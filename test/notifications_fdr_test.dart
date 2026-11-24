import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/fixed_deposits/data/fixed_deposit_repository.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_scheduler.dart';
import 'package:my_budget/features/notifications/domain/notification_models.dart';
import 'package:my_budget/features/notifications/domain/notification_settings.dart';
import 'package:my_budget/features/notifications/domain/reminder_planner.dart';
import 'package:my_budget/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_test_helpers.dart';

MaturityReminderInput fdr({
  int id = 1,
  String maturity = '2026-12-20',
  int principal = 100000000,
}) => MaturityReminderInput(
  id: id,
  schemeType: 'FDR',
  instrumentNumber: 'FDR-001',
  bankName: 'City Bank',
  principalMinor: principal,
  maturityDate: maturity,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bn = lookupAppLocalizations(const Locale('bn'));
  const planner = ReminderPlanner();
  final now = DateTime(2026, 11, 18, 8);

  group('planner: deposit maturity', () {
    test('fires 7 days before, 1 day before and on the day', () {
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
      );
      expect(plan.map((p) => p.when), [
        DateTime(2026, 12, 13, 9),
        DateTime(2026, 12, 19, 9),
        DateTime(2026, 12, 20, 9),
      ]);
      expect(plan.every((p) => p.kind == NotificationKind.fdr), isTrue);
      expect(plan.map((p) => p.phase), [
        NotificationPhase.upcoming,
        NotificationPhase.upcoming,
        NotificationPhase.today,
      ]);
      expect(plan.first.title, 'FDR maturing');
      expect(
        plan.first.body,
        'FDR FDR-001 of City Bank matures in 7 days (2026-12-20). '
        'Principal ৳1,000,000.00.',
      );
      expect(plan[1].body, contains('matures tomorrow'));
      expect(plan[2].body, contains('matures today'));
      expect(plan.every((p) => p.dueDate == '2026-12-20'), isTrue);
    });

    test('each reminder has its own key and id', () {
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
      );
      expect(plan.map((p) => p.key).toSet().length, 3);
      expect(plan.map((p) => p.id).toSet().length, 3);
    });

    test('is localized', () {
      final plan = planner.plan(
        l10n: bn,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
      );
      expect(plan.first.title, 'FDR মেয়াদপূর্তি');
      expect(plan.first.body, contains('City Bank-এর FDR FDR-001'));
      expect(plan.first.body, contains('7 দিন'));
    });

    test('outside the planning window nothing is scheduled', () {
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr(maturity: '2027-06-01')],
      );
      expect(plan, isEmpty);
    });

    test('a reminder that falls inside the window is kept alone', () {
      // Maturity 8 days before the horizon end: only the 7-day one is past
      // the horizon edge, the closer ones are not.
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr(maturity: '2027-01-20')],
      );
      // horizon = 2027-01-17 08:00: the 7-day-before (01-13) reminder is in,
      // 01-19 and 01-20 are out.
      expect(plan.map((p) => p.when), [DateTime(2027, 1, 13, 9)]);
    });

    test('today reminder follows the "today" switch', () {
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
        todayEnabled: false,
      );
      expect(plan, hasLength(2));
      expect(plan.any((p) => p.phase == NotificationPhase.today), isFalse);
    });

    test('closed / zero-principal deposits are ignored', () {
      final plan = planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: const [],
        maturities: [fdr(principal: 0)],
      );
      expect(plan, isEmpty);
    });

    test('a reminder time that already passed today is a catch-up', () {
      final plan = planner.plan(
        l10n: en,
        now: DateTime(2026, 12, 20, 10),
        rules: const [],
        debts: const [],
        maturities: [fdr()],
      );
      expect(plan, hasLength(1));
      expect(plan.single.catchUp, isTrue);
      expect(plan.single.phase, NotificationPhase.today);
    });

    test('catch-up already shown is not repeated', () {
      final late = DateTime(2026, 12, 20, 10);
      final first = planner.plan(
        l10n: en,
        now: late,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
      );
      final again = planner.plan(
        l10n: en,
        now: late,
        rules: const [],
        debts: const [],
        maturities: [fdr()],
        catchUpDone: {first.single.key},
      );
      expect(again, isEmpty);
    });
  });

  group('scheduler: deposit maturity', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late FakeNotificationGateway gateway;
    late NotificationScheduler scheduler;
    late FixedDepositRepository repo;
    late int pid;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.memory();
      gateway = FakeNotificationGateway();
      pid = await addProfile(db);
      repo = FixedDepositRepository(db);
      await NotificationSettings(
        remindersEnabled: true,
        budgetAlertsEnabled: true,
        reminderHour: 9,
        expireAfterDays: 0,
      ).save(prefs);
      scheduler = NotificationScheduler(
        db: db,
        prefs: prefs,
        gateway: gateway,
        activeProfileId: () => pid,
        clock: () => now,
      );
    });
    tearDown(() => db.close());

    // Starts 2026-11-20 + 30 days => matures 2026-12-20.
    Future<FixedDepositPositionRef> make({String number = 'FDR-001'}) async {
      final p = await repo.create(
        profileId: pid,
        bankName: 'City Bank',
        instrumentNumber: number,
        startDate: '2026-11-20',
        tenureDays: 30,
        rateBp: 1000,
        principalMinor: 100000000,
      );
      return FixedDepositPositionRef(p.deposit.id, p.current.id);
    }

    test('running deposit schedules three reminders', () async {
      await make();
      await scheduler.resync();
      final fdrs = gateway.scheduled.values
          .where((n) => n.kind == NotificationKind.fdr)
          .toList();
      expect(fdrs, hasLength(3));
      expect(fdrs.every((n) => n.body.contains('FDR-001')), isTrue);
      final plan = await scheduler.buildPlan();
      expect(plan.where((n) => n.kind == NotificationKind.fdr), hasLength(3));
    });

    test('encashed, reissued-away and archived deposits stay silent', () async {
      final a = await make();
      await repo.encash(
        profileId: pid,
        termId: a.termId,
        settledDate: '2026-12-20',
        interestMinor: 1000,
      );
      final b = await make(number: 'FDR-002');
      await repo.setArchived(
        profileId: pid,
        depositId: b.depositId,
        archived: true,
      );
      await scheduler.resync();
      expect(
        gateway.scheduled.values.where((n) => n.kind == NotificationKind.fdr),
        isEmpty,
      );
    });

    test('a reissue moves the reminders to the new maturity date', () async {
      final a = await make();
      await repo.reissue(
        profileId: pid,
        termId: a.termId,
        settledDate: '2026-12-20',
        interestMinor: 500000,
        newInstrumentNumber: 'FDR-009',
        newStartDate: '2026-12-20',
        newTenureDays: 20,
        newRateBp: 900,
      );
      final plan = await scheduler.buildPlan();
      final fdrs = plan.where((n) => n.kind == NotificationKind.fdr).toList();
      expect(fdrs, hasLength(3));
      expect(fdrs.every((n) => n.dueDate == '2027-01-09'), isTrue);
      expect(fdrs.every((n) => n.body.contains('FDR-009')), isTrue);
    });

    test('a switched-off reminder is not scheduled', () async {
      await make();
      final plan = await scheduler.buildPlan();
      final tomorrow = plan.firstWhere(
        (n) => n.kind == NotificationKind.fdr && n.when.day == 19,
      );
      await NotificationSettings.saveDisabledKeys(prefs, {tomorrow.key});
      await scheduler.resync();
      final fdrs = gateway.scheduled.values
          .where((n) => n.kind == NotificationKind.fdr)
          .toList();
      expect(fdrs, hasLength(2));
    });
  });
}

/// Ids of a freshly created deposit and its first instrument.
class FixedDepositPositionRef {
  FixedDepositPositionRef(this.depositId, this.termId);
  final int depositId;
  final int termId;
}
