# Brief for v4 module agents (Sprints 9+)

Project: `D:\MyProject\MyBudget` (Flutter, Android-first). **Read `CLAUDE.md` and `docs/AGENT_BRIEF.md` first; both are binding** (UI imports `package:material_ui/material_ui.dart` ONLY, money = int minor units, every query filters `profile_id`, cross-profile ids rejected, soft delete only, Riverpod 3 `Notifier`/`AsyncNotifier`/`StreamProvider`, real `AppDatabase.memory()` in tests, lock commands via `tool/locked.sh`). This file only adds what is new in schema v4.

## What the lead already did (do NOT redo or edit)
- Schema is **v4** and `*.g.dart` is regenerated. New Drift tables/row classes in `lib/core/database/database_tables.dart`:
  `RecurringRules/RecurringRuleRow`, `SavingsGoals/SavingsGoalRow`, `Debts/DebtRow`, `DebtPayments/DebtPaymentRow`, `Tags/TagRow`, `TransactionTags/TransactionTagRow`, `TransactionAttachments/AttachmentRow`.
  New columns: `cost_items.is_favorite`, `category_budgets.rollover_enabled`. Read the table definitions for exact columns and CHECK constraints.
- Deps already in pubspec (do not run pub get/add): `local_auth`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `image_picker`, `crypto`, `cryptography`, `quick_actions` (+ existing `shared_preferences`, `file_picker`, `csv`, `share_plus`, `pdf`, `intl`, `fl_chart`).
- Android manifest/gradle already have USE_BIOMETRIC, POST_NOTIFICATIONS, boot receivers, core-library desugaring, `FlutterFragmentActivity`.
- `lib/core/storage/app_paths.dart`: `attachmentsDirectory()` + `attachmentsDirectoryOverride` (set in tests to a temp dir).

## Rules specific to this wave
- You own ONLY your module folder `lib/features/<module>/**` and `test/<module>_*_test.dart` (names given in your task). Do not edit other modules, `lib/core/**`, `lib/app/**`, `lib/shared/**`, `pubspec.yaml`, `*.g.dart`, `docs/**`. Never run build_runner, `pub get/add`, bare `flutter test`, `dart format .`, and never kill processes.
- Run heavy commands only via the lock: `tool/locked.sh flutter test test/<your files>` and `tool/locked.sh dart analyze lib/features/<yours> test/<yours>`. Format only your own paths: `dart format lib/features/<yours> test/<yours>`.
- Depend on other features only through DB tables and existing public providers (`appDatabaseProvider`, `activeProfileIdProvider`, `sharedPreferencesProvider`, `activeProfileProvider`, and public repository providers such as the transactions repository when posting transactions so snapshots + audit log are reused). If something you need is missing, work around it and report it.
- Sibling agents run in parallel and may leave their own folders mid-edit; analyze/test only your paths.
- Name uniqueness (case-insensitive) is enforced by indexes; also pre-check in the repository and map violations to `DuplicateNameException`.
- Screens need loading/empty/error states, dark+light friendly (theme colors), and tests: happy path, validation, duplicate, cross-profile rejection, soft-delete behaviour, plus ≥1 widget test per screen.
- Writes go through `db.transaction(...)`. Dates are `'yyyy-MM-dd'` via `core/utils/date_keys.dart`. Money via `core/utils/money.dart`.
- Pushed screens have their own `Scaffold`. Widgets meant for embedding elsewhere have none. Use exactly the class names/constructors listed in your task — the lead wires routes, shell and settings tiles to them.

## Final report (concise)
Files created, public API (class names, constructors, providers), behaviours/decisions, tests run with exact pass counts, known limitations, anything the lead must wire (routes, settings tiles, init calls, manifest).
