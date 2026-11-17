# MyBudget – Requirements Specification (condensed from the original brief)

Production-quality, offline-first personal/family finance app. Android-first Flutter/Dart. No backend/cloud/Firebase/REST. Real DB operations, no mock data.

## Stack
Flutter, Dart, SQLite via Drift, Riverpod, GoRouter, Material 3, fl_chart, shared_preferences, path_provider, JSON backup, pdf+printing, csv, Workmanager (scheduled backup; Android may delay, never promise exact times), intl, flutter_test + integration_test. Stable compatible versions; avoid unnecessary packages. Business logic independent of UI; Drift transactions for financial ops.

## Architecture
Feature-first clean architecture: `lib/{app,core,features,shared}`; features: profiles, categories, sub_categories, cost_items, budgets, accounts, transactions, ledger, dashboard, reports, backup, each with data/domain/presentation. No SQL in widgets.

## 4. Profiles
Multiple independent profiles (Personal, Family, ...). Each owns categories, sub-categories, cost items, budgets, accounts, income, expenses, transfers, ledgers, reports. Every profile-owned table has `profile_id`; all queries filter by it; composite FKs; no cross-profile category/sub-category selection or account transfer; switching profile refreshes all dashboards/reports; deactivation never deletes history; deletion needs explicit confirmation + safe retention policy. Persist selected profile.

## 5. Master configuration
Category → Sub-category → Cost Item, all user-defined (nothing hardcoded).
- Category: id, profile_id, name, description, icon, color, is_active, created/updated. Case-insensitive unique name per profile. Create/edit/view/activate-deactivate.
- Sub-category: id, profile_id, category_id (same profile), name, is_active, timestamps.
- Cost item: id, profile_id, sub_category_id, name, description, default amount (optional), is_active, timestamps. Search; filter by category/sub-category. Default amount can be overridden in a transaction.
- Never physically delete referenced masters; use active/inactive. History stays reportable after rename/deactivate; transactions keep name snapshots.

## 6. Monthly budgets
monthly_budgets(id, profile_id, year, month, total_budget, timestamps), unique per profile/year/month. Optional category budgets (allocations within the total — never added to the total). Rollover = RESET: each month independent, no carry-forward of unused or negative amounts, new month configured manually, history preserved. Remaining = Budget − Expense; Utilization = Expense/Budget×100; overspend allowed and shown negative. Budget remaining ≠ account cash balance.

## 7. Accounts
Cash / Bank / Mobile banking / custom. Fields: id, profile_id, name, type, opening balance, opening date, is_active, timestamps. Every transaction belongs to an account.

## 8. Transactions
- Expense: id, profile_id, account_id, category/sub-category/cost item ids, amount, date, title, remarks, timestamps, is_deleted.
- Income: id, profile_id, account_id, income source, amount, date, remarks. Raises balance, not budget.
- Transfer: between own accounts of the same profile; atomic; preserves total; never income/expense.

## 9. Edit / delete
Edit: validate, save, keep old+new in audit history, recompute balances/budgets, refresh UI; month change updates both months. Delete = soft delete with audit (original data, timestamp, action, previous values, visible history); excluded from ledgers/reports; undo if practical; deleting a transfer reverses both sides atomically.

## 10. Ledgers
- Account ledger: Date, Description, Income, Expense, Transfer In, Transfer Out, Running Balance = Opening + Income − Expense + In − Out.
- Budget ledger: Date, Cost Item, Category, Expense, Remaining Budget = Budget − cumulative expense.
Both: date filters, search, details, history; running balances computed via SQL window functions (never stored); order by date + stable transaction id.

## 11. Dashboard
Overview: monthly budget, month expense, remaining, utilization %, actual cash balance, month income. Analytics: top-5 items, top-5 categories, highest spending day, average daily expense, category distribution. Yearly: income, expense, avg monthly expense, highest/lowest month, monthly trend. Filters: current/previous/selected month, year, profile. Reactive Drift queries.

## 12. Reports
Monthly: income, expense, budget, remaining, utilization, category/sub-category/item-wise, daily expenditure, account movements. Yearly: income, expense, budget, monthly expense/income comparison, highest/lowest month, average, category comparison; always all 12 months. PDF + CSV export, custom date ranges, profile-specific.

## 13. Data integrity (critical)
Integer minor units (paisa), never floats; decimal-safe parse/format; validate amounts; reject negative and zero amounts; validate account/hierarchy ownership by profile and dates; atomic transactions; preserve history; soft delete; reports recomputed from source transactions; idempotent retries (no duplicates); concurrent writes can't corrupt balances. Default BDT (৳); currency per profile (future-compatible).

## 14. Backup
Local, app-private DB. Manual JSON export (versioned): profiles, categories, sub-categories, cost items, budgets, accounts, transactions, transfers, audit logs, settings. Restore: validate format, version, records, relationships, duplicate ids/refs → user confirm → safety backup → atomic restore → rollback on failure; never overwrite silently. Automatic backup via WorkManager: configurable frequency, local destination, status, timestamp, retention, restore from previous backups; manual backup always available; no cloud required.

## 15. UI/UX
Material 3, clean, consistent spacing, light+dark, accessible contrast, loading/empty/error states, confirmations, validation, search/filter. Bottom nav: Home, Budget, Add, Ledger, Reports; master config via Settings. Screens: profile selection/creation, dashboard, category/sub-category/cost item management, monthly budget, accounts, add expense/income/transfer, expense details, edit transaction, account ledger, budget ledger, monthly/yearly report, backup/restore, settings. Add Expense uses cascading Category → Sub-category → Cost Item, active only.

## 16. Database
Tables: financial_profiles, categories, sub_categories, cost_items, monthly_budgets, category_budgets, accounts, financial_transactions, transaction_audit_logs, application_settings (+ justified extras). PKs, FKs, composite profile-scoped FKs, unique constraints, report indexes, timestamps, soft-delete fields, explicit migration strategy, consistent naming, no redundant tables, name snapshots, export/commit Drift schema snapshots.

## 17. Tests
Database (profile creation/isolation, hierarchy, duplicates, FKs); transactions (add expense/income/transfer, edit, delete expense/transfer, historical updates); calculations (budget, negative remaining, running balances, avg daily/monthly, highest month, top five); edge cases (empty month, zero budget, backdated, month/year boundary, leap year, same-day multiples, cross-profile access, invalid/duplicate backup restore, migration). Realistic data; production never depends on seed data.

## 18. Sprints
1. Foundation: project, structure, theme, navigation, Riverpod, Drift + migrations, profiles, persisted active profile. **(done)**
2. Master configuration: categories, sub-categories, cost items, validation, search/filter. **(done, pending final verification)**
3. Budget + accounts: monthly/category budgets, accounts, opening balances, monthly reset.
4. Transactions: expense, income, transfer, edit, delete, audit.
5. Ledger: account + budget ledger, running balances, filtering.
6. Dashboard: overview, top-five, averages, yearly stats.
7. Reports: monthly/yearly, charts, PDF, CSV.
8. Backup + release: manual/auto backup, restore, security, performance, regression, release APK.

## 19. Agent working rules
Before coding: inspect workspace, Flutter/Dart/Android SDK, package compatibility, plan, schema before dependent screens. During: one sprint at a time, no skipped requirements, no mock data, no logic in widgets, reusable widgets, proper error handling, migration-safe, profile isolation. After each phase run `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test` (+ integration tests); fix errors. Report per sprint: files created/modified, DB changes, features, tests run/results, known limitations, remaining tasks. Never claim completion without implementation + passing tests. Don't start the next sprint before acceptance criteria pass; don't redesign finished modules without reason.

### Sprint acceptance criteria
- S1: runs on Android; multiple profiles; persist after restart; switching works; no internet needed.
- S2: user-defined hierarchy; sub-category can't reference another profile's category; cost item can't reference another profile's sub-category; editing works; deactivated records preserved; persists after restart.
