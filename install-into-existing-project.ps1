param(
  [string]$Target = "C:\KhalidNetworks\khalid_networks_staff"
)
$ErrorActionPreference = "Stop"
$Source = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $Target "pubspec.yaml"))) {
  throw "Flutter project not found at $Target"
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $Target "backup-before-khalid-app-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($name in @("lib","assets","pubspec.yaml","analysis_options.yaml")) {
  $p = Join-Path $Target $name
  if (Test-Path $p) { Copy-Item $p $backup -Recurse -Force }
}
Write-Host "Backup created: $backup" -ForegroundColor DarkGray

Copy-Item (Join-Path $Source "lib") $Target -Recurse -Force
Copy-Item (Join-Path $Source "assets") $Target -Recurse -Force
Copy-Item (Join-Path $Source "pubspec.yaml") $Target -Force
Copy-Item (Join-Path $Source "analysis_options.yaml") $Target -Force
Copy-Item (Join-Path $Source "build-windows.ps1") $Target -Force

$androidApp = Join-Path $Target "android\app"
Copy-Item (Join-Path $Source "android\app\build.gradle.kts") $androidApp -Force
Copy-Item (Join-Path $Source "android\app\src\main\AndroidManifest.xml") (Join-Path $androidApp "src\main\AndroidManifest.xml") -Force

$oldKotlin = Join-Path $androidApp "src\main\kotlin"
if (Test-Path $oldKotlin) { Remove-Item $oldKotlin -Recurse -Force }
Copy-Item (Join-Path $Source "android\app\src\main\kotlin") (Join-Path $androidApp "src\main") -Recurse -Force
Copy-Item (Join-Path $Source "android\app\src\main\res") (Join-Path $androidApp "src\main") -Recurse -Force

Push-Location $Target
try {
  flutter clean
  flutter pub get
  Write-Host "App source installed successfully." -ForegroundColor Green
  Write-Host "Next: upload backend-patch\mobile-api.php to public_html, then run build-windows.ps1 or flutter build apk --release." -ForegroundColor Cyan
} finally {
  Pop-Location
}
