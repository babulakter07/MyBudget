---
name: mybudget-release
description: Build, verify, sign and prepare MyBudget for release (APK for local install, AAB for Google Play). Use for "build the apk", "release", "publish to Play Store", "install on my phone", or when a Windows Gradle build fails.
---

# MyBudget release workflow

Toolchain: `export PATH=/c/flutter/bin:$PATH` (Flutter 3.50, Android SDK `C:\Android\Sdk`, JDK 17). Read `CLAUDE.md` first.

## 1. Verify before building
`flutter pub get`, `dart format .`, `flutter analyze` (must be clean), `flutter test` (all pass, including `test/app_smoke_test.dart` and `test/migration_v2_test.dart`). If `sqlite3.dll` is locked by a stale `flutter_tester.exe`, ask the user before killing it.

## 2. Build
- Local install/test APK: `flutter build apk --release` gives `build/app/outputs/flutter-apk/app-release.apk` (debug-signed unless `android/key.properties` exists).
- Play Store bundle: `flutter build appbundle --release` gives `build/app/outputs/bundle/release/app-release.aab`.
- The first build is slow (8-15 min); cached rebuilds take about 40 s.

## 3. Known build failures (Windows)
- `Could not close incremental caches ... compileReleaseKotlin`: project on D:, pub cache on C:. The fix is already in `android/gradle.properties` (`kotlin.incremental=false`); keep it.
- `copyFlutterApksRelease ... file is being used by another process`: run `android/gradlew --stop`, then rebuild. The finished APK is already in `build/app/outputs/apk/release/`.
- A fat APK is about 63 MB; the AAB is what Play uses (per-ABI splits).

## 4. Post-build checks
- 16 KB page alignment (Play requirement): `C:\Android\Sdk\build-tools\36.0.0\zipalign.exe -c -P 16 4 app-release.apk` must report success.
- Signer: `apksigner.bat verify --print-certs app-release.apk`. `CN=Android Debug` means the APK cannot be uploaded to Play.
- Permissions: `aapt2.exe dump badging app-release.apk` and look at `uses-permission`. WorkManager adds POST_NOTIFICATIONS, FOREGROUND_SERVICE, WAKE_LOCK and RECEIVE_BOOT_COMPLETED; remove the ones the app doesn't need with `tools:node="remove"` in `AndroidManifest.xml` to avoid extra Play declarations.

## 5. Signing for Play (user-owned secrets: never generate, commit or guess passwords)
`android/app/build.gradle.kts` signs with `android/key.properties` when present (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`) and otherwise falls back to the debug key. `key.properties`, `*.jks` and `*.keystore` are git-ignored. The user creates the keystore (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), backs it up, and enrolls in Play App Signing.

## 6. Play Store checklist
- Custom launcher icon (replace `android/app/src/main/res/mipmap-*`), 512x512 store icon, feature graphic, screenshots, short and full description.
- Privacy policy URL, data-safety form (the app is fully offline and collects nothing), content rating, target audience.
- Bump `versionCode` in `pubspec.yaml` (`version: x.y.z+N`) for every upload. Application ID `com.mybudget.my_budget` is permanent once published.
- Test on a real device first: add transactions, ledger, report PDF/CSV export, backup and restore, automatic backup (Android may delay WorkManager; never promise exact times).
