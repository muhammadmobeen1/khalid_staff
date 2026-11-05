$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Khalid Networks Staff - Android Release Build" -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter is not available in PATH."
}

$settingsKts = Join-Path $Root "android\settings.gradle.kts"
$settingsGroovy = Join-Path $Root "android\settings.gradle"
$wrapper = Join-Path $Root "android\gradlew.bat"
if ((-not (Test-Path $settingsKts)) -and (-not (Test-Path $settingsGroovy)) -or (-not (Test-Path $wrapper))) {
  Write-Host "Incomplete/legacy Android project detected. Running automatic v2 repair..." -ForegroundColor Yellow
  & (Join-Path $Root "repair-android.ps1")
  if ($LASTEXITCODE -ne 0) { throw "Android repair failed" }
}

Push-Location $Root
try {
  flutter clean
  if ($LASTEXITCODE -ne 0) { throw "flutter clean failed" }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
  flutter analyze
  if ($LASTEXITCODE -ne 0) { Write-Warning "flutter analyze reported issues. Build will still be attempted." }
  flutter build apk --release
  if ($LASTEXITCODE -ne 0) { throw "APK build failed" }
  $apk = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
  if (Test-Path $apk) {
    $dest = Join-Path $Root "Khalid-Networks-Staff.apk"
    Copy-Item $apk $dest -Force
    Write-Host "DONE: $dest" -ForegroundColor Green
  } else {
    throw "APK was not found after build."
  }
} finally {
  Pop-Location
}
