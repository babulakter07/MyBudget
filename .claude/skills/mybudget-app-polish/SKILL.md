---
name: mybudget-app-polish
description: Add user-facing polish to MyBudget (app lock/PIN recovery, theme, in-app manual, setup guide, reminders, split bill, Bangla/English strings) and ship an APK. Use for requests like "add a user manual", "translate to Bangla", "add a reminder card", "PIN recovery", "split transaction", or "build the apk after changes".
---

# MyBudget app-polish workflow (learned 2026-11-18)

Read `CLAUDE.md` first. Everything below was proven in practice on this repo.

## Where things live
- **App lock:** `lib/features/security/` (`AppLockGate` in `MaterialApp.builder` in `lib/app/app.dart`; `appLockControllerProvider`; PBKDF2 PIN hash; lockout 5 tries -> 30s doubling; recovery code `XXXX-XXXX-XXXX-XXXX`, stored hashed only). The gate sits ABOVE the Navigator, so never use `showDialog` or other Navigator UI inside the lock screen; use inline panels (the recovery panel wraps its TextField in its own `Overlay`).
- **Theme:** `lib/features/preferences/` (`themeModeProvider`, `localeProvider`).
- **User manual:** `lib/features/help/` — text lives in `domain/manual_content.dart` (English) and `domain/manual_content_bn.dart` (Bangla, keyed by topic id; a test checks every topic has a translation with the same step/tip counts). Open a topic from any screen with `HelpButton(topicId: 'budget')` (route `/help?topic=<id>`).
- **Setup guide + reminders:** `lib/features/onboarding/` — `setupProgressProvider` (live SQL, always filtered by `profile_id`), `SetupGuideScreen` (`/setup`, also linked in Settings so it stays reachable), `SetupGuideCard` and `BackupReminderCard` on the Home tab (rule in `evaluateBackupReminder`, 30 days, 7-day snooze).
- **Split bill:** `TransactionRepository.createSplitExpense` (one DB transaction, idempotency key per line, all-or-nothing) + `SplitExpenseScreen` at `/transactions/split`.
- **Budget carry-over:** already exists (`rollover_enabled` toggle in the Budget tab). Do not rebuild it.

## Strings (English + Bangla)
1. NEVER edit `lib/l10n/app_*.arb` by hand (they are regenerated and your keys would be lost). Add keys to BOTH `l10n_parts/<module>_en.arb` and `l10n_parts/<module>_bn.arb`, prefixed with the camelCase module name (placeholders need an `@key` block in the English part).
2. Run `PYTHONUTF8=1 tool/l10n.sh` (merges the parts, checks parity, runs `flutter gen-l10n`; not build_runner). Generated files in `lib/l10n/generated/` are committed.
3. Use `context.l10n.key`. Bangla terms: Ledger = **লেজার** (not খতিয়ান), Budget = বাজেট, Category = ক্যাটাগরি, Cost item = কস্ট আইটেম.
4. Widget tests that need Bangla must use the app's real delegates (`AppLocalizations.delegate`, `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`) with `locale: Locale('bn')`; `Localizations.override` alone loses Material localizations.
5. Bangla text written by an AI must be reviewed by a Bangla speaker before release.

## Wiring checklist for a new screen
- Route in `lib/app/router/app_router.dart`. Put static paths (e.g. `/transactions/split`) BEFORE parameter paths (`/transactions/:id`) or they get captured.
- Settings tile in `lib/app/shell/settings_screen.dart` (always give a feature a permanent entry point; a card that hides itself is not discoverable).
- A manual topic (en + bn) and, where useful, a `HelpButton`.
- Tests: repository tests with `AppDatabase.memory()` (helpers in `test/ledger_test_helpers.dart`); widget tests use `material_ui`, `scrollUntilVisible` for items below the fold in a lazy ListView.

## Verify and ship
1. `tool/locked.sh dart format <paths>`, then `tool/locked.sh flutter analyze` (must be clean), then `tool/locked.sh flutter test` (all pass; includes `test/app_smoke_test.dart`).
2. `tool/locked.sh flutter build apk --release` -> `build/app/outputs/flutter-apk/app-release.apk` (about 72 MB, debug-signed without `android/key.properties`; fine for phone install, not for Play).
3. Do not run the build while edits to files it compiles are still landing; build last.

## Shell gotchas on this machine
- Long Bash heredocs containing apostrophes or `\n` escapes break the Bash tool ("unexpected EOF"). Write a script or file with the Write tool instead and run it. In a Python script, use real `\n` escapes inside normal strings and check non-ASCII (Bangla) text survives with `encoding='utf-8'`.
- Edit/Write require the file to have been Read in the session; after another agent or a formatter changes a file, Read it again.
- Other agents may edit the same files (the security screens were localized by someone else mid-task). Re-read before editing and keep their changes.

## Still open (not built)
Home-screen widget, daily "log your spending" reminder, net worth view, real signing keystore, real-device tests (biometrics, notifications, background backups, receipt photos).
