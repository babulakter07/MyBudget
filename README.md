# MyBudget

Offline-first personal and family finance app for Android, built with Flutter.
**All data stays on the device** — no account, no backend, no analytics, no cloud.

## Features

**Money tracking**
- Multiple profiles (personal, family) with fully isolated data
- Accounts (cash, bank, mobile wallet, savings, credit card), expenses, income and transfers
- Categories → sub-categories → cost items, optional quick-add favourites
- Tags that cut across categories, receipt photo attachments
- Edit, soft-delete with undo, full audit log, duplicate-safe saves

**Planning**
- Monthly and per-category budgets, with optional carry-over of unspent budget
- Recurring transactions (rent, salary, bills, EMI) that catch up after the app was closed
- Savings goals with progress, deadline and required-per-month
- Debt and loan tracker (lent / borrowed, repayments, overdue status)
- Local reminders for bills and debts, and budget alerts at 80% / 100%

**Understanding**
- Dashboard, account and budget ledgers with running balances
- Search and filters across everything (text, amount, date, tags, accounts)
- Spending insights: month-over-month change, unusual spend, month-end forecast
- Monthly / yearly / custom-range reports exported as PDF or CSV

**Safety**
- PIN and biometric app lock with auto-lock and attempt lockout
- Manual and automatic JSON backups, optional password-encrypted export (AES-256-GCM)
- Validated, atomic restore with an automatic safety backup
- CSV import from bank statements (duplicate-safe re-import)
- Local error log you can attach to a support email

## Tech stack

Flutter · Dart · Drift (SQLite) · Riverpod 3 · GoRouter · Material 3 · fl_chart · WorkManager

Architecture is feature-first clean architecture: `lib/features/<feature>/{domain,data,providers,presentation}`.
Money is always stored as integer minor units (paisa). See [`CLAUDE.md`](CLAUDE.md) for the engineering rules
and [`docs/SPEC.md`](docs/SPEC.md) for the product requirements.

## Getting started

```bash
flutter pub get
flutter run
```

Verification (run before every commit; CI runs the same steps):

```bash
dart format .
flutter analyze
flutter test
```

After changing Drift tables or anything with a `part '*.g.dart'`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Schema changes must bump `AppDatabase.currentSchemaVersion`, add a stepwise migration and a migration test.

## Release

1. Create an upload keystore and `android/key.properties` (both git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/path/to/upload-keystore.jks
   ```
2. `flutter build appbundle --release`
3. Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play.

Without `key.properties`, release APKs fall back to the debug key (local testing only) and
`flutter build appbundle` fails on purpose.

Icons: edit `tool/make_icon.py`, then run `python tool/make_icon.py` (needs Pillow).
Privacy policy: [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md).
