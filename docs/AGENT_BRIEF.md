# Shared brief for module agents (Sprints 3-8)

Project: `D:\MyProject\MyBudget` (Flutter, Android-first). Read `CLAUDE.md` and `docs/SPEC.md` first; they are binding.
Existing modules (profiles, categories, sub_categories, cost_items) are the style reference: copy their repository/provider/screen/test structure.

## Environment
- Bash tool: `export PATH=/c/flutter/bin:$PATH`.
- **UI imports:** use `package:material_ui/material_ui.dart` ONLY. NEVER import `package:flutter/material.dart` (it is a separate Material copy; dialogs/bottom sheets crash under the app's `material_ui` MaterialApp). Tests must also use `material_ui` `MaterialApp`.
- **Heavy commands must go through the lock** (parallel agents share one project dir): `tool/locked.sh flutter test test/<your files>` and `tool/locked.sh dart analyze lib/features/<yours> test/<yours>`. Never run `flutter test` bare, never `build_runner`, never `flutter pub get/add`, never `dart format .` (format only your own files: `dart format lib/features/<yours> test/<yours>`). Never kill processes. Never edit `*.g.dart`, `lib/core/database/*`, `lib/app/**`, `pubspec.yaml`, other modules.
- If you truly need a schema/pubspec/router/shell change, don't make it: describe it in your final report and work around it.

## Database contract (schema v2, already generated; see `lib/core/database/database_tables.dart`)
Drift tables/data classes: `FinancialProfiles/ProfileRow`, `Categories/CategoryRow`, `SubCategories/SubCategoryRow`, `CostItems/CostItemRow`, `MonthlyBudgets/MonthlyBudgetRow` (profileId, year, month, totalBudgetMinor), `CategoryBudgets/CategoryBudgetRow` (profileId, monthlyBudgetId, categoryId, amountMinor), `Accounts/AccountRow` (profileId, name, type cash|bank|mobile|other, openingBalanceMinor, openingDate 'yyyy-MM-dd', isActive), `FinancialTransactions/TransactionRow`, `TransactionAuditLogs/AuditLogRow`, `ApplicationSettings/SettingRow` (key/value text).
`financial_transactions`: `type` expense|income|transfer; `accountId` (source for transfer), `toAccountId` (transfer destination only); `categoryId/subCategoryId/costItemId` (expense; category required, others optional); name snapshots (`accountNameSnapshot`, `toAccountNameSnapshot`, `categoryNameSnapshot`, `subCategoryNameSnapshot`, `costItemNameSnapshot`); `incomeSource`; `amountMinor` > 0; `txnDate` text 'yyyy-MM-dd'; `title`, `remarks`; `idempotencyKey` (unique per profile when non-null); `isDeleted`, `deletedAt`. A transfer is ONE row. Soft-deleted rows (`is_deleted=1`) must be excluded from every ledger/report/balance/budget calculation.
Audit: `transaction_audit_logs` (action create|update|delete|restore, previousJson/newJson).
Account balance = openingBalance + income - expense + transfersIn - transfersOut over non-deleted rows with txnDate >= account.openingDate (decide & document: rows dated before opening date are still counted only if on/after openingDate; transactions before the opening date must be rejected on create).
Budget remaining = monthlyBudget.totalBudgetMinor - SUM(expense in month). Category budgets are allocations inside the total, never added to it. Budget remaining != cash balance.

## Shared helpers (do not modify)
- `lib/core/utils/money.dart`: `parseMajorToMinor`, `formatMinor` (ints only, never double).
- `lib/core/utils/date_keys.dart`: `dateKey(DateTime)`, `parseDateKey`, `monthStartKey/monthEndKey/monthKey`, `daysInMonth`, `isValidDateKey`.
- `lib/core/errors/app_exception.dart`: `AppException`, `ValidationException`, `DuplicateNameException`, `NotFoundException`, `ProfileMismatchException`.
- `lib/core/widgets/widgets.dart`: `LoadingView`, `EmptyState`, `ErrorState`, `showConfirmDialog`.
- `lib/shared/providers/core_providers.dart`: `appDatabaseProvider`, `sharedPreferencesProvider`, `activeProfileIdProvider` (every profile-scoped provider must `ref.watch` it).
- `lib/features/profiles/data/profile_providers.dart`: `activeProfileProvider` (Profile with `currencyCode`).
- `lib/app/theme/app_colors.dart`: `AppColors.income/expense`.

## Non-negotiables (from CLAUDE.md)
Money = int minor units. Every query filters `profile_id`; cross-profile ids rejected before touching DB (`ProfileMismatchException`/`NotFoundException`). No hard deletes of master/financial data. Financial writes in `db.transaction(...)`. Running balances computed at query time (SQL window functions via `customSelect`), never stored. Riverpod 3 (`Notifier`/`AsyncNotifier`/`StreamProvider`; no `StateNotifier`/`StateProvider`). Business logic in repositories/services, not widgets. Loading/empty/error states on every screen. User-readable `AppException` messages. No mock/seed data in production code. Light + dark friendly (use theme colors).

## Tests
Real `AppDatabase.memory()` (no mocks); insert parents directly through `db.into(...)`. Widget tests with Drift streams: after unmounting and before `db.close()` do `await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(seconds: 1)); await tester.runAsync(() => db.close());` and avoid `pumpAndSettle` with live streams (use pump with durations). Cover: happy paths, validation, duplicate, cross-profile rejection, FK enforcement, edge cases listed for your module in docs/SPEC.md §17.

## Routes the lead will wire (use exactly these class names/constructors)
Tab bodies (no Scaffold/AppBar of their own; they are placed inside HomeShell's Scaffold): `DashboardView()`, `BudgetView()`, `AddTransactionView()`, `LedgerView()`, `ReportsView()`.
Pushed screens (own Scaffold): `AccountListScreen()` /config/accounts; `TransactionDetailScreen({required int transactionId})` /transactions/:id; `EditTransactionScreen({required int transactionId})` /transactions/:id/edit; `MonthlyReportScreen({int? year, int? month})` /reports/monthly; `YearlyReportScreen({int? year})` /reports/yearly; `BackupScreen()` /settings/backup. Navigate with `context.push('/transactions/$id')` etc. (go_router).

## Final report (concise)
Files created/modified, behaviours, tests run + exact results, known limitations, anything the lead must wire (providers, init calls, manifest changes).
