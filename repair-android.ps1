$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $Root
try {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter is not available in PATH."
    }

    Write-Host "Repairing Android project with current Flutter v2 embedding..." -ForegroundColor Cyan

    $temp = Join-Path $env:TEMP ("khalid-staff-android-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $temp | Out-Null

    $oldRes = Join-Path $Root "android\app\src\main\res"
    if (Test-Path $oldRes) {
        Copy-Item $oldRes (Join-Path $temp "res") -Recurse -Force
    }

    if (Test-Path (Join-Path $Root "android")) {
        Remove-Item (Join-Path $Root "android") -Recurse -Force
    }

    flutter create --platforms=android --org com.khalidnetworks --project-name khalid_networks_staff .
    if ($LASTEXITCODE -ne 0) { throw "flutter create failed while regenerating Android project." }

    $appGradleKts = Join-Path $Root "android\app\build.gradle.kts"
    $appGradle = Join-Path $Root "android\app\build.gradle"
    if (Test-Path $appGradleKts) {
        $g = Get-Content $appGradleKts -Raw
        $g = [regex]::Replace($g, 'namespace\s*=\s*"[^"]+"', 'namespace = "com.khalidnetworks.staff"')
        $g = [regex]::Replace($g, 'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.khalidnetworks.staff"')
        $g = [regex]::Replace($g, 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23')
        Set-Content $appGradleKts $g -Encoding UTF8
    } elseif (Test-Path $appGradle) {
        $g = Get-Content $appGradle -Raw
        $g = [regex]::Replace($g, 'namespace\s+["''][^"'']+["'']', 'namespace "com.khalidnetworks.staff"')
        $g = [regex]::Replace($g, 'applicationId\s+["''][^"'']+["'']', 'applicationId "com.khalidnetworks.staff"')
        $g = [regex]::Replace($g, 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23')
        Set-Content $appGradle $g -Encoding UTF8
    } else {
        throw "Android app Gradle file was not generated."
    }

    $manifest = @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <application
        android:label="Khalid Networks Staff"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
'@
    Set-Content (Join-Path $Root "android\app\src\main\AndroidManifest.xml") $manifest -Encoding UTF8

    $kotlinRoot = Join-Path $Root "android\app\src\main\kotlin"
    $javaRoot = Join-Path $Root "android\app\src\main\java"
    if (Test-Path $kotlinRoot) { Remove-Item $kotlinRoot -Recurse -Force }
    if (Test-Path $javaRoot) { Remove-Item $javaRoot -Recurse -Force }
    $mainDir = Join-Path $kotlinRoot "com\khalidnetworks\staff"
    New-Item -ItemType Directory -Force -Path $mainDir | Out-Null
    @'
package com.khalidnetworks.staff

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
'@ | Set-Content (Join-Path $mainDir "MainActivity.kt") -Encoding UTF8

    $savedRes = Join-Path $temp "res"
    if (Test-Path $savedRes) {
        Copy-Item (Join-Path $savedRes "*") (Join-Path $Root "android\app\src\main\res") -Recurse -Force
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed after Android repair." }

    Write-Host "Android v2 project repaired successfully." -ForegroundColor Green
} finally {
    Pop-Location
}
