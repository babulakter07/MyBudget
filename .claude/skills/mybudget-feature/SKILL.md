---
name: mybudget-feature
description: Add or modify a MyBudget feature/sprint (new module, schema change, screen, report) using the project's established architecture and parallel-agent process. Use for any MyBudget change request such as "implement Sprint 3", "add X to accounts", or "change the cost item screen".
---

# MyBudget feature workflow

Read `CLAUDE.md` (architecture + rules) and the relevant sprint in `docs/SPEC.md` first. Then:

1. **Scope.** Restate which sprint/module is changing and its acceptance criteria. Don't start later sprints.
2. **Contract first (lead, sequential).** If the change needs schema: edit `lib/core/database/database_tables.dart` (profile_id on every owned table, composite FKs via `customConstraints`, `uniqueKeys {profileId,id}` on parents), bump `schemaVersion`, add an `onUpgrade` step + NOCASE unique indexes in `app_database.dart`, run `dart run build_runner build --delete-conflicting-outputs` once, add shared providers/exceptions if needed. Check `dart analyze lib`.
3. **Fan out (parallel).** For 2+ independent modules, launch one background agent per module in a single message. Each prompt must state: project path, toolchain PATH, Riverpod 3 rules, money-in-minor-units, profile isolation, owned file list (feature folder + its tests only), forbidden actions (no `.g.dart` edits, no build_runner, no other modules, no killing processes), the exact screen class names/constructors the router will reference, required tests, and "report files/tests/limitations concisely". For a single small change, do it directly instead.
4. **Integrate (lead).** Wire routes in `app/router/app_router.dart` and Settings/home shell entries. Run `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test`. Fix failures; never mark done on unrun tests. If `sqlite3.dll` is locked by a stale `flutter_tester`, ask the user before killing it.
5. **Report** per CLAUDE.md (files, DB changes, features, tests + results, limitations, remaining). Commit/push only if the user asks.

Checklist before finishing: every query filters `profile_id`; no doubles for money; soft-delete only; duplicate/cross-profile/FK tests exist; migration test if schema changed; loading/empty/error states in UI.
