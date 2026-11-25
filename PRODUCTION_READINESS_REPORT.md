# MyBudget — Production Readiness Report

Audit date: 2026-11-26 · Mode: read-only (no source/config/dependency changes; `flutter pub get` refreshed `.dart_tool` only; build outputs only under `build/`).
Legend: **[V]** verified by running a command or reading the file · **[U]** unverified / assumption.

---

## 1. Executive Summary

**Overall: NOT ready to upload to Google Play today; READY AFTER FIXES.** The code quality is high and the app is functionally broad. The blockers are release-engineering and privacy-configuration items, not code defects.

Evidence of health **[V]**: `flutter analyze` → *No issues found*; `flutter test` → *888 tests, All tests passed*; target SDK 36 meets Google's requirement; 16 KB page alignment check passed on the (stale) existing APK; no network permission in release, no HTTP code, no secrets found, no Firebase.

**Critical blockers**
1. **No upload keystore / release signing** — `android/key.properties` absent; Gradle silently falls back to the **debug key** (`android/app/build.gradle.kts:59-63`). The existing APK is signed `CN=Android Debug` **[V]**. Play rejects this.
2. **AAB build could not be verified.** `flutter build appbundle --release` failed twice **[V]** — environmental, not a project defect: a global Gradle init script `C:\Users\user\.gradle\init.d\zz-curl-mirror.gradle` (marked "TEMPORARY") rewrites all Maven URLs to `http://127.0.0.1:8765`, where nothing is listening. No AAB exists.
3. **Android Auto Backup is not disabled** (no `android:allowBackup`/`dataExtractionRules` in manifest → defaults to enabled **[V]**). Financial DB, PIN hash and plain-JSON auto-backups may be uploaded to the user's Google Drive, contradicting the privacy policy and the app's "data never leaves device" promise.
4. **Privacy policy is only a Markdown file in `docs/`** with no public URL and no concrete contact address; Play requires a hosted URL.
5. **No real-device testing yet** (self-reported in `CLAUDE.md`): biometrics, notifications, camera/picker, WorkManager backup, launcher shortcuts.

**Recommended next action:** (a) approve fixes for items 3, permission cleanup and icon; (b) create the upload keystore yourself (I will not generate one); (c) remove/start the stale Gradle mirror so the AAB can be built; (d) host the privacy policy; (e) device-test, then start closed testing.

---

## 2. Project Technology Stack **[V]**

| Item | Value |
|---|---|
| Flutter / Dart | 3.50.0 stable / 3.14.0 (`flutter doctor -v`; a newer Flutter is available) |
| App version | `1.0.0+1` (versionName 1.0.0, versionCode 1) |
| Application ID / namespace | `com.mybudget.my_budget` |
| minSdk / targetSdk / compileSdk | 24 / 36 / `max(flutter 36, 37)` = 37 |
| AGP / Gradle / Kotlin | 9.3.1 / 9.5.0 / 2.4.20 |
| JDK | Temurin 17.0.21 (source/target/jvmTarget 17) |
| Android SDK / build-tools | platform-36, build-tools 36.0.0; licenses accepted |
| Architecture | Feature-first clean architecture; Riverpod 3, GoRouter 18, Drift 2.35 over SQLite (schema v7), Material 3 (`material_ui`), en+bn localization |
| Key packages | workmanager, flutter_local_notifications, local_auth, file_picker, image_picker, share_plus, pdf/printing, csv, cryptography (AES-256-GCM backups), fl_chart |
| Backend | None (no Firebase, no REST, no analytics) — `CLAUDE.md`, grep of `lib/` found only 3 static developer links in `about_screen.dart` and no HTTP client |
| Doctor | Only warning: Visual Studio C++ workload (irrelevant to Android) |

Notes: `sqlite3_flutter_libs: ^0.6.0+eol` is an end-of-life marker package; 19 packages have newer incompatible versions; `pubspec.yaml` description is still "A new Flutter project." There is no `assets/` folder and no ProGuard rules file (R8 runs with Flutter defaults; `mapping.txt` exists).

---

## 3. Feature Audit

Discovered from `lib/features/*` (35+ modules) and `CLAUDE.md`; behaviour correctness is evidenced only by the 888 passing automated tests.

**Implemented and covered by automated tests [V]:** multi-profile isolation; categories/sub-categories/cost items; accounts & wallets; monthly + category budgets with rollover; income/expense/transfer transactions (edit, soft-delete + undo, audit log, idempotency keys, split bill, foreign-currency entry with manual rate); ledger (account + budget); dashboard/analytics/insights/forecast; reports (monthly/yearly/custom, PDF + CSV); search/filters; tags and receipt attachments; recurring transactions; savings goals; debts; bank loans (amortization, early close/adjust); credit cards (bills, payments, late fee/interest); fixed deposits (FDR/DPS); CSV import; local notifications/budget alerts; app lock (PIN + biometric + recovery code); backup/restore (validated, atomic, safety backup, optional AES-256-GCM, WorkManager auto-backup); theme/language; onboarding/setup guide; bilingual manual; offline error log.

**Incomplete / known gaps:** custom launcher icon and splash (default Flutter icon, white splash — `res/mipmap-*` are the template PNGs **[V]**); release keystore; home-screen widget (not built); foreign-currency *accounts*; repository error messages not localized; Bangla copy never reviewed by a native speaker; PDFs cannot render Bengali/taka sign.
**Placeholders/mock data:** none found — no TODO/FIXME or mock data in `lib/` **[V]** (grep).
**Unverified on hardware [U]:** biometrics, notification delivery/exactness (scheduled *inexact* by design, `notification_gateway.dart:123`), camera/photo picker, WorkManager auto-backup timing, launcher shortcuts, performance on low-end phones, TalkBack/accessibility, Bangla rendering on real devices.

---

## 4. Security Audit

No secrets, API keys, tokens, keystores or `.env` files exist in the repo; `*.jks`, `*.keystore`, `key.properties` are git-ignored and none are tracked **[V]**. No Internet permission in the release manifest **[V]**, so cleartext/network-security-config and HTTPS items are N/A. SQL uses bound parameters; dynamic fragments in `search_repository.dart` are only `?` placeholder lists and a whitelisted ORDER BY **[V]**. `FLAG_SECURE` is set in `MainActivity.kt` (blocks screenshots/recents thumbnail). Backup restore has path-traversal protection (`backup_paths.dart`) and bounded KDF iterations. No WebView.

**Critical:** none confirmed.

**High**
- **H1 Auto Backup enabled** (see P1-3). Plain, unencrypted auto-backup JSON (`defaultBackupsDirectory` → app documents dir, `backup_service.dart:17`), the SQLite DB and SharedPreferences (incl. PIN hash) are all eligible for Google backup / device transfer.

**Medium**
- **M1 Database is unencrypted SQLite** (`app_database.dart:252-256`). Acceptable for local apps, but the app lock does not protect the data at rest; disclose accurately.
- **M2 PIN verifier in SharedPreferences, weak parameters** (`app_lock_providers.dart`, `pin_hasher.dart`): 4–6 digit PIN, PBKDF2-SHA256 at 20 000 iterations → offline brute force of the stored hash is trivial on a rooted/backed-up device. Lockout counters and `lockoutUntil` are in plain prefs and use wall-clock `DateTime.now`, so they can be reset by editing prefs or changing the clock. Recovery code (80-bit) is sound. Consider Android Keystore-backed storage (e.g. `flutter_secure_storage`) and an app-lock label of "convenience lock".
- **M3 Auto/safety backups are plaintext** by design (`CLAUDE.md`: "Auto/safety backups are plain"). Combined with H1 this is the main financial-privacy exposure.
- **M4 Error log may contain financial data** — `app_logger.dart` writes raw `error` strings/stacks; Drift/SQLite exceptions can echo values. Log is user-shareable from Settings.

**Low**
- L1 `main.dart:78-82` shows the raw exception `$error` on the startup-error screen (English only, not localized).
- L2 Library-exported components (`SystemJobService`, `DiagnosticsReceiver`, `ProfileInstallReceiver`) are standard and permission-guarded; only `MainActivity` is exported by the app itself **[V]** (note: this check is against the *source* manifest + the stale merged manifest, see §6).
- L3 Developer's personal university e-mail is hard-coded in `about_screen.dart:14` (visible to all users).
- L4 Clipboard copy of the recovery code (`security_settings_screen.dart:199`) leaves it on the clipboard.

---

## 5. Code Quality

- `flutter doctor -v`: healthy except the unrelated Visual Studio component **[V]**.
- `flutter pub get`: OK; 19 packages have newer incompatible versions **[V]**.
- `flutter analyze`: **No issues found** (135 s) **[V]**.
- `flutter test`: **888 passed, 0 failed** **[V]** — repositories on a real in-memory DB, migrations v2/v4/v6, backup v4–v6, widget tests, en/bn parity.
- Tests are slow (~35 min on this machine, because live Drift-stream widget tests use bounded pumps); several `transactions_quickadd_test` cases take ~1 min each — worth investigating **[V]**.
- CI (`.github/workflows/ci.yml`): format, analyze, test, **debug** APK only — never builds a release/AAB, so release-only failures (R8, signing, manifest merge) go undetected.
- `android/build.gradle.kts:25-30` disables `lintVital*` tasks (JDK 17 lint crash workaround) → Android release lint never runs.
- **Missing tests (important):** release-config/signing smoke test; app-lock lockout persistence across restarts and clock changes; restore of a corrupted/oversized file; WorkManager backup isolate concurrent-DB access; notification permission denied flow; large-dataset (10k+ transactions) performance; accessibility/large-font layouts; widget tests for the startup error screen.
- Memory leaks/unnecessary rebuilds: not profiled **[U]**; no obvious issues from structure (providers watch `activeProfileIdProvider`).

---

## 6. Android Configuration

- Package ID: `com.mybudget.my_budget` — unique-looking, not the template `com.example`, but the file still contains the template `TODO` comment (`build.gradle.kts:32`). **Permanent after first upload.**
- SDK: min 24, **target 36 ✅** (Play requires API 36 for new apps/updates since 2026-08-31; extension window to 2026-11-01 has passed), compile 37.
- Version 1.0.0+1 — fine for first upload; bump `+N` for each subsequent upload.
- **Signing ❌:** fallback to debug key; no keystore, no `key.properties` **[V]**. Keystore backup plan required (Play App Signing is recommended; losing the upload key requires a Play reset request).
- **Manifest (source) [V]:** label `MyBudget`; permissions declared: `USE_BIOMETRIC`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`; no `allowBackup`, no `dataExtractionRules`, no `enableOnBackInvokedCallback`, no `screenOrientation` (fine for Android 16 large-screen rules). WorkManager merges in `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SHORT_SERVICE`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`; the repo's own release skill recommends removing unneeded ones with `tools:node="remove"`. No INTERNET in release; no exact-alarm permission (inexact scheduling — good, avoids a Play declaration).
- **The merged manifest/APK in `build/` is stale** (built 2026-11-18, compileSdk 36, lacks `USE_BIOMETRIC` and notification receivers) **[V]** — so final permissions of the real release artifact are **unverified** until a fresh build.
- Launcher icon: default Flutter template PNGs; splash: plain white `launch_background.xml`; no dark-mode splash and no Android 12 splash config.
- R8/ProGuard: no custom rules file; Flutter default minification active (mapping.txt present). Upload `mapping.txt` and native debug symbols (33 MB zip generated) to Play for readable crash reports.
- 16 KB page-size alignment: passed on the existing APK (`zipalign -c -P 16 4`) **[V]**; re-check on the new build.

---

## 7. Performance Audit

No profiling, startup timing or device tests were run — everything below is **[U]** except where noted.
- Data access: window-function ledger queries, indexes on (profile, date/account/category), paginated search (`LIMIT/OFFSET`) — good design. `exportBackup` loads whole tables and base64-embeds photos in a single JSON string → **memory spike / OOM risk with many receipt photos** on low-RAM devices (`backup_service.dart:68-120`).
- Background backup runs in a separate isolate with its **own SQLite connection** (`backup_scheduler.dart:20`) while the UI may write; no `busy_timeout`/WAL pragma found (only `foreign_keys=ON`, `app_database.dart:144`) → possible `database is locked` failures (swallowed, `return true`). **[V]** for the absence of pragmas; the failure itself is untested.
- Data-loss scenarios: (1) all data, **including local backups**, live in app-private storage — uninstall/clear-data wipes everything unless the user shared a backup out; (2) forgotten backup password is unrecoverable (documented); (3) Auto Backup restore may bring back stale DB state on a new device (H1).
- Fat APK 66 MB (AAB will be smaller per ABI). No image assets. Battery: periodic WorkManager (daily/weekly) and inexact notifications — low impact.
- Offline: app is offline by design; no network failure paths.

---

## 8. Google Play Compliance (checked against Play Console Help, 2026-11-26)

**Satisfied / likely satisfied**
- Target API 36 ✅ ([target API policy](https://support.google.com/googleplay/android-developer/answer/11926878); next step API 37 from Aug 2027).
- AAB is the required format (build pending); 16 KB alignment ✅.
- No ads, no accounts/login (App access: "no restrictions"), no INTERNET.

**Missing / developer action required**
1. Upload keystore + Play App Signing enrolment (P1).
2. **Privacy policy** hosted at a public URL, with real contact e-mail; correct its "stored only on device" claim after the backup fix (`docs/PRIVACY_POLICY.md` is a good draft).
3. **Data safety form:** the app collects/shares nothing to developer servers; declare accordingly. Confirm in Play's Data-safety guidance how Android Auto Backup should be treated **[U — not verified in docs]**; disabling it removes the question.
4. **Financial features declaration** is mandatory for every app, even if none apply ([guide](https://support.google.com/googleplay/android-developer/answer/13849271)). MyBudget records loans, credit cards, FDRs and debts but offers no lending, payments, transfers or advice, so "no financial features" is the likely answer — this is my **inference**, not a Google statement; read the declaration options carefully and do not assume exemption.
5. Content rating questionnaire, target audience (adults/general; not designed for children), category **Finance** (or Productivity), ads = none, news = no, government = no.
6. Store listing: 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots (en + bn if localized listing), short/full description. The custom launcher icon should exist before screenshots.
7. **If your developer account is a personal account created after 2023-11-13:** a closed test with **≥12 testers opted in for 14 consecutive days** is required before production access ([requirement](https://support.google.com/googleplay/android-developer/answer/14151465)). Account type is **[U]**.
8. Notification permission (`POST_NOTIFICATIONS`) and biometric are runtime/normal — no special Play declaration; ensure the foreground-service permissions pulled in by WorkManager don't trigger a declaration prompt (`FOREGROUND_SERVICE_SHORT_SERVICE` does not).

---

## 9. Release Build Results

- Command: `flutter build appbundle --release` (run twice, second with `GRADLE_OPTS=-Dorg.gradle.offline=true`).
- **Status: FAILED [V]** — `Could not resolve com.android.tools.build:gradle-settings-api:9.3.1 … Connect to 127.0.0.1:8765 failed: Connection refused`. Cause: global init script `C:\Users\user\.gradle\init.d\zz-curl-mirror.gradle` (outside the project; its own comment says "TEMPORARY… Delete this file to go back to normal") redirects every Maven repo to a local mirror that is not running. I did **not** delete or edit it (outside the project, user-owned).
- AAB output path: **none** (`build/app/outputs/bundle` does not exist).
- Signing verification: not possible for an AAB. The existing `build/app/outputs/flutter-apk/app-release.apk` (2026-11-18, stale) is signed by **CN=Android Debug**, package `com.mybudget.my_budget`, versionCode 1, targetSdk 36, minSdk 24.
- Because no keystore is configured, even a successful build would produce a **debug-signed, non-uploadable** bundle.

---

## 10. Issue Prioritization

| # | Pri | File / location | Problem | Impact | Recommended fix |
|---|---|---|---|---|---|
| 1 | P1 | `android/app/build.gradle.kts:57-65` (`buildTypes.release.signingConfig`) | Falls back to debug signing silently when `key.properties` is missing | Debug-signed release possible; Play rejects; accidental non-Play distribution | You create upload keystore + `android/key.properties`; change fallback to a **hard build failure** for release |
| 2 | P1 | `~/.gradle/init.d/zz-curl-mirror.gradle` (env) | Dead local mirror breaks all Gradle downloads | Cannot produce AAB; CI-parity lost | Start the mirror or delete the file (your call); then rebuild AAB and verify signature with `jarsigner`/`bundletool` |
| 3 | P1 | `android/app/src/main/AndroidManifest.xml` `<application>` | `allowBackup` default true, no `dataExtractionRules`/`fullBackupContent` | DB, PIN hash, plain backups uploaded to Google Drive; privacy-policy contradiction | Set `android:allowBackup="false"` (or exclude db/prefs/backups via data-extraction rules) |
| 4 | P1 | `docs/PRIVACY_POLICY.md` | Not hosted; no real contact; claim inaccurate until #3 | Play Console submission blocked | Host (GitHub Pages is fine), add support e-mail, update after #3 |
| 5 | P1 | whole app | No real-device testing | Unknown crashes on biometrics/notifications/picker/WorkManager | Test on ≥2 physical devices (incl. Android 13+, Android 16) before closed test |
| 6 | P1 | Play Console | Financial-features declaration, Data safety, content rating, listing assets not done | Cannot publish | See §8 |
| 7 | P2 | `AndroidManifest.xml` (merged) | Extra permissions from WorkManager (`FOREGROUND_SERVICE`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`); final merged manifest unverified | Extra store scrutiny | Remove with `tools:node="remove"` if unused; re-verify with `aapt2 dump badging` on new build |
| 8 | P2 | `res/mipmap-*`, `res/drawable/launch_background.xml` | Default Flutter icon, white splash, no night splash | Poor store presentation; possible quality/metadata review flags | Add custom adaptive icon + splash (light/dark) |
| 9 | P2 | `app_lock_providers.dart`, `pin_hasher.dart` | PIN hash + lockout counters in SharedPreferences, 20k PBKDF2 iterations, wall-clock lockout | Lock bypass/brute force off-device or on rooted device | Raise iterations (≥210k like backups) or use Keystore-backed storage; monotonic clock; label as convenience lock |
| 10 | P2 | `backup_service.dart:17` + `exportBackup` | Auto/safety backups plaintext; backups stored only in app-private dir; whole-DB+photos built in memory | Privacy exposure; loss on uninstall; OOM risk with many photos | Offer encrypted auto-backups or export prompt; stream photos / cap size; warn users to export a copy |
| 11 | P2 | `backup_scheduler.dart:20`, `app_database.dart:143` | Second SQLite connection in WorkManager isolate, no `busy_timeout`/WAL | Intermittent "database is locked", silent missed backups | Add `PRAGMA busy_timeout`, consider WAL; test concurrent write+backup |
| 12 | P2 | `core/logging/app_logger.dart:42-49` | Raw exceptions logged and shareable | Financial values may leak via support e-mail | Redact values; mention in policy |
| 13 | P2 | `.github/workflows/ci.yml` | CI builds debug only | Release-only breakages unseen | Add `flutter build appbundle --release` (with a CI debug-signing flag) |
| 14 | P2 | `pubspec.yaml` `sqlite3_flutter_libs ^0.6.0+eol` | EOL marker package | Future maintenance/security risk | Migrate per Drift docs to the supported sqlite3 build-hook setup |
| 15 | P3 | `android/build.gradle.kts:25-30` | `lintVital*` disabled | Android lint never gates releases | Run on JDK 21 and re-enable |
| 16 | P3 | `main.dart:78-82` | Raw exception on startup-error screen, English only | Confusing UX, minor info leak | Localize; show generic text + log reference |
| 17 | P3 | `about_screen.dart:14` | Personal university e-mail hard-coded | Developer privacy/stale address | Use a dedicated support address |
| 18 | P3 | `pubspec.yaml:2`, `build.gradle.kts:32` | Template description / TODO comment | Cosmetic | Update text |
| 19 | P3 | manifest | No `enableOnBackInvokedCallback` (predictive back) | Missed Android 16 UX polish | Evaluate and enable if navigation supports it |
| 20 | P3 | `pubspec.yaml` | 19 outdated packages; `flutter_local_notifications` 23.0.4 available | Drift over time | Scheduled dependency update after launch |
| 21 | P3 | tests | Suite takes ~35 min; gaps listed in §5 | Slower iteration | Parallelise/trim pumps; add missing tests |

No P0 (confirmed critical security/data-loss) issue was found; H1/#3 is the closest and is rated P1 because it requires Auto Backup to be active on the user's device.

---

## 11. Final Decision

**READY AFTER FIXES**

Reasoning: the codebase is clean (analyzer clean, 888/888 tests, sensible architecture, offline-only, no secrets, target SDK compliant). It cannot be published today because (1) there is no upload keystore and release signing silently falls back to debug, (2) a signed AAB was never produced or verified (environment blocker), (3) Android Auto Backup is left enabled for a financial app and conflicts with the privacy policy, (4) the privacy policy and Play Console declarations are not in place, and (5) nothing has been exercised on real hardware. All are fixable in a short cycle; none requires a redesign. After fixes: build a signed AAB, verify signer/permissions/16 KB alignment, run a closed test, then promote to production.
