# MyBudget — project guide for Claude

Offline-first personal/family finance app. Flutter (Android-first), Dart, Drift/SQLite, Riverpod 3, GoRouter, Material 3.
No backend, no Firebase, no REST, no cloud. All data local. Full requirements: `docs/SPEC.md`.

## Toolchain (this machine)
- Flutter 3.50 at `C:\flutter\bin`, Android SDK `C:\Android\Sdk`, JDK 17 (Temurin). If `flutter` is not on PATH in a shell: `export PATH=/c/flutter/bin:$PATH` (bash) / `$env:Path="C:\flutter\bin;$env:Path"` (PowerShell).
- After editing Drift tables or anything with `part '*.g.dart'`: `dart run build_runner build --delete-conflicting-outputs` (slow, ~2 min; run it in ONE place only, never from parallel agents).
- Verification after every change: `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test`. Never claim done unless these pass.
- If `flutter test` fails with "failed to delete build\native_assets\windows\sqlite3.dll", a stale `flutter_tester` process holds the lock. Ask the user before killing it; don't kill a tester another agent may be using.
- Parallel agents must run heavy commands through `tool/locked.sh <cmd>` (mkdir-based lock) so test/analyze runs don't collide.
- **UI imports: `package:material_ui/material_ui.dart` ONLY.** `package:flutter/material.dart` is a separate Material copy; dialogs/bottom sheets from it crash under the app's `material_ui` MaterialApp (this was the dead "Add category" button). Widget tests must use `material_ui` too.
- Windows release builds need `kotlin.incremental=false` in `android/gradle.properties` (project on D:, pub cache on C:). If the final APK copy fails with "file in use", run `android/gradlew --stop` and rebuild. See `/mybudget-release`.

## Architecture (feature-first clean architecture)
```
lib/
  main.dart                      # bootstraps prefs + DB, ProviderScope overrides
  app/        (app.dart, router/app_router.dart, theme/, shell/, app_constants.dart)
  core/       (database/, errors/, utils/money.dart, widgets/)
  shared/providers/core_providers.dart   # appDatabaseProvider, sharedPreferencesProvider, activeProfileIdProvider
  features/<feature>/
      domain/        entities / view models / filters (no Flutter, no Drift imports in business rules)
      data/          repository over Drift (all SQL lives here)
      providers/ or data/*_providers.dart   Riverpod providers
      presentation/  screens + widgets (no SQL, no business logic)
test/<feature>_*_test.dart
```
Implemented (all sprints, schema v2): profiles, categories, sub_categories, cost_items, accounts, budgets (monthly + category, RESET rollover), transactions (expense/income/transfer, edit, soft delete + undo, audit log, idempotency keys), ledger (account + budget, SQL window functions), dashboard, reports (monthly/yearly/custom range, PDF + CSV), backup (manual JSON export, validated atomic restore with safety backup, WorkManager auto backup), About screen. Shell: `app/shell/home_shell.dart` tabs = `DashboardView`, `BudgetView`, `AddTransactionView`, `LedgerView`, `ReportsView`; routes in `app/router/app_router.dart`.
Not yet done: real-device testing, release keystore, custom launcher icon, Play Store listing, app bundle.

### Data conventions (schema v2)
- Transaction/opening dates are text `'yyyy-MM-dd'` (`core/utils/date_keys.dart`), not DateTime, so they sort and group without timezone drift.
- `financial_transactions`: one row per transfer (`account_id` source, `to_account_id` destination); name snapshots; `idempotency_key` unique per profile; `is_deleted` rows are excluded from every ledger/report/balance/budget calculation.
- Account balance = opening + income - expense + transfers in - transfers out (non-deleted, dated on/after opening date). Budget remaining = budget - expense; never confuse it with cash balance.
- Dashboard/report decisions: avg daily expense divides by days elapsed for the current month; avg monthly = yearly/12; lowest month = min among months WITH expense ('-' if none); ties go to the earliest month.
- PDFs print money as `BDT 12,000.50` (default PDF fonts lack the taka sign and Bengali glyphs).
- Backup retention: only `auto` backups are pruned (newest N, 3..30, default 7); `manual` is never auto-pruned; `safety` keeps the newest 5.

## Non-negotiable rules
1. **Money = integer minor units** (paisa). Never double. Use `core/utils/money.dart` (`parseMajorToMinor`, `formatMinor`). Default currency BDT (৳).
2. **Profile isolation:** every profile-owned table has `profile_id`; child tables use composite FKs `(profile_id, parent_id)`; EVERY repository query filters by `profile_id`; cross-profile ids are rejected (`ProfileMismatchException`/`NotFoundException`) before touching the DB. Profile-scoped providers must `ref.watch(activeProfileIdProvider)`.
3. **No hard deletes** for master or financial data — use `is_active` / soft delete + audit log. Keep name snapshots on transactions.
4. Names unique case-insensitively within their parent (unique indexes with `COLLATE NOCASE`, created in `AppDatabase._createIndexes`); repositories also pre-check and map DB violations to `DuplicateNameException`.
5. Financial writes use Drift `transaction(...)`. Running balances are computed (window functions/queries), never stored.
6. Schema changes: bump `AppDatabase.currentSchemaVersion`, add a stepwise `onUpgrade` migration (never rewrite earlier steps), add a migration test, regenerate code.
7. No mock/seed data in production code. Errors are `AppException` subclasses (`core/errors/app_exception.dart`) with user-readable messages.
8. Riverpod 3: use `Notifier`/`AsyncNotifier`/`StreamProvider`; no `StateNotifier`/`StateProvider`.
9. Do not redesign finished modules without a real architectural reason; extend, don't restructure.

## Testing conventions
- Repository tests use real `AppDatabase.memory()` (no mocks); insert parents directly via `db.into(...)`.
- Widget tests with Drift streams: teardown must be `await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(seconds: 1)); await tester.runAsync(() => db.close());` or the test hangs (10-minute timeout). Avoid `pumpAndSettle` with live streams; use bounded `pump(Duration)` (and `runAsync(Future.delayed)` so Drift streams can emit).
- Route transitions need `pump(100ms)` then `pump(600ms)`; call `tester.ensureVisible` before tapping list items near the bottom of the 800x600 test viewport.
- Migration tests build a hand-written old-schema DB via `NativeDatabase.memory(setup: ...)` with `PRAGMA user_version`, then open `AppDatabase` (see `test/migration_v2_test.dart`).
- `test/app_smoke_test.dart` boots the real `MyBudgetApp` (router + shell); keep it passing after any wiring change.
- Each feature: create, duplicate, cross-profile rejection, FK enforcement, edit, deactivate-preserved, search/filter.

## Working process (how Sprints 1–8 were built — repeat for new work)
1. Inspect workspace/toolchain; read `docs/SPEC.md` for the sprint.
2. Lead writes the shared contract FIRST: Drift tables + migration, `build_runner`, shared providers, error types.
3. Fan out parallel agents, **one per feature module**, each owning only its own folders (`lib/features/<x>/**`, its tests). Tell them: don't edit `.g.dart` or run build_runner, don't touch other modules, depend on other features only via DB tables/shared providers. The lead (or one agent) owns router/app shell.
4. Lead integrates: format, analyze, full test, fix cross-module issues, then report.
5. Sprint report: files created/modified, DB changes, features done, tests run + results, known limitations, remaining tasks. Do not start the next sprint until acceptance criteria pass.
6. Use the `/mybudget-feature` skill for this workflow and `/mybudget-release` to build, sign and publish. Agent brief template: `docs/AGENT_BRIEF.md`.

## Git
Remote: https://github.com/babulakter07/MyBudget.git (branch `main`). Commit/push only when the user asks.
