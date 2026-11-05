# Khalid Networks Staff

Mobile-first Flutter app for Khalid Networks collectors/staff.

## App features
- Staff ID/password login using existing staff accounts
- Secure saved app session
- Dashboard KPIs and assigned villages
- Start/Stop Duty and GPS location updates
- Unpaid bill collection submission for admin approval
- New connection submission
- Assigned complaints and fix reporting
- Pending/rejected request list with admin notes
- Staff profile picture upload/remove
- Same existing Khalid Networks MySQL database

## Backend patch
Upload `backend-patch/mobile-api.php` into the same public_html folder as `staff-api.php`.
Do not replace your database or config.php.

The app currently points to:
`https://mistyrose-reindeer-364324.hostingersite.com/mobile-api.php`

If your domain changes, edit `lib/core/config.dart`.

## Build on Windows
From your existing Flutter project folder:
1. Copy/overwrite `lib`, `assets`, `pubspec.yaml`, `analysis_options.yaml` and the AndroidManifest/MainActivity files from this package.
2. Run:
   `flutter pub get`
3. Accept Android licenses if needed:
   `flutter doctor --android-licenses`
4. Build:
   `flutter build apk --release`
5. APK output:
   `build\app\outputs\flutter-apk\app-release.apk`


## Easiest install into your existing project
Your project already exists at `C:\KhalidNetworks\khalid_networks_staff`.
Extract this package anywhere, open PowerShell inside the extracted folder and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install-into-existing-project.ps1
```

Then upload `backend-patch\mobile-api.php` into your Hostinger `public_html` folder beside `staff-api.php`.

Finally:
```powershell
cd C:\KhalidNetworks\khalid_networks_staff
.\build-windows.ps1
```

The final APK will be copied to:
`C:\KhalidNetworks\khalid_networks_staff\Khalid-Networks-Staff.apk`


## STAFF APP v1.1.1 update
Requires Khalid Networks server v15/schema v11. Adds asset/expense workflow; Staff app also adds provisional 58mm Bluetooth receipt printing and month-wise receipt history.
