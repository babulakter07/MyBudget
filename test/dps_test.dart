import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/dps/data/dps_repository.dart';
import 'package:my_budget/features/dps/domain/dps.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_scheduler.dart';
import 'package:my_budget/features/notifications/domain/notification_models.dart';
import 'package:my_budget/features/upcoming/data/upcoming_repository.dart';
import 'package:my_budget/l10n/generated/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

DpsTerms _terms({
  String bank = 'City Bank',
  String? number = 'DPS-1',
  int installment = 100000,
  int months = 36,
  String open = '2026-08-10',
  String firstDue = '2026-08-10',
  int rateBp = 1000,
  int? bankMaturity,
  int lateFee = 10000,
  int grace = 5,
  int missed = 3,
}) => DpsTerms(
  bankName: bank,
  accountNumber: number,
  installmentMinor: installment,
  tenureMonths: months,
  openDate: open,
  firstDueDate: firstDue,
  rateBp: rateBp,
  bankMaturityMinor: bankMaturity,
  lateFeeMinor: lateFee,
  graceDays: grace,
  missedLimit: missed,
);

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime(2026);
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  group('calculator', () {
    test('estimate adds profit monthly on installments paid in advance', () {
      int estimate(int rate, [int months = 60]) =>
          DpsCalculator.estimatedMaturity(
            installmentMinor: 100000,
            tenureMonths: months,
            rateBp: rate,
          );
      expect(estimate(0), 6000000);
      // 1,000 a month at 10 % for 5 years is about 78,082.
      expect(estimate(1000), closeTo(7808238, 100));
      // One month earns exactly one month of profit.
      expect(estimate(1200, 1), 101000);
    });

    test('month ends keep the original day', () {
      expect(DpsCalculator.addMonths('2026-01-31', 1), '2026-02-28');
      expect(DpsCalculator.addMonths('2026-01-31', 2), '2026-03-31');
      expect(DpsCalculator.addMonths('2027-12-31', 2), '2028-02-29');
      expect(DpsCalculator.maturityDate('2026-08-10', 36), '2029-08-10');
    });

    test('tax rounds half up', () {
      expect(DpsCalculator.taxOn(105, 1000), 11);
      expect(DpsCalculator.taxOn(104, 1000), 10);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late DpsRepository repo;
    late int p1, p2;
    var today = '2026-11-26';

    setUp(() async {
      today = '2026-11-26';
      db = AppDatabase.memory();
      repo = DpsRepository(db, today: () => today);
      p1 = await _profile(db, 'One');
      p2 = await _profile(db, 'Two');
    });
    tearDown(() => db.close());

    Future<DpsPosition> add({DpsTerms? terms, int paid = 0}) => repo.create(
      profileId: p1,
      terms: terms ?? _terms(),
      paidInstallments: paid,
    );

    Future<void> pay(int id, int count, {String? date, int fee = 0}) =>
        repo.addPayment(
          profileId: p1,
          dpsId: id,
          installments: count,
          lateFeeMinor: fee,
          paymentDate: date ?? today,
        );

    Future<DpsPosition> reload(int id) async => (await repo.getById(p1, id))!;

    test('status follows the grace period and the missed limit', () async {
      // Due 10 Aug, Sep, Oct, Nov.
      final id = (await add(paid: 2)).account.id;
      today = '2026-10-15'; // last grace day of October
      var p = await reload(id);
      expect((p.status, p.overdueCount), (DpsStatus.active, 0));
      expect(p.nextDue!.status, DpsInstallmentStatus.due);

      today = '2026-10-16';
      expect((await reload(id)).status, DpsStatus.overdue);

      today = '2026-11-26';
      p = await reload(id);
      expect((p.status, p.overdueCount), (DpsStatus.overdue, 2));
      expect(p.isOneMissFromLimit, isTrue);

      today = '2026-12-16';
      p = await reload(id);
      expect((p.status, p.overdueCount), (DpsStatus.atRisk, 3));
      // The app only warns.
      expect(p.account.closingType, isNull);
    });

    test('a bank without a missed limit is never at risk', () async {
      final id = (await add(terms: _terms(missed: 0))).account.id;
      expect((await reload(id)).status, DpsStatus.overdue);
    });

    test('earlier installments are recorded on their due dates', () async {
      final p = await add(paid: 3);
      expect(p.paidCount, 3);
      expect(p.depositedMinor, 300000);
      expect(p.lateFeesPaidMinor, 0);
      expect(p.schedule.take(3).map((i) => i.paidDate), [
        '2026-08-10',
        '2026-09-10',
        '2026-10-10',
      ]);
    });

    test('deposits settle the oldest first and suggest late fees', () async {
      final p = await add();
      final id = p.account.id;
      // Aug, Sep, Oct, Nov are all past grace on 26 Nov.
      expect(p.suggestedLateFee(2, today), 20000);
      expect(p.suggestedLateFee(6, today), 40000);
      expect(p.suggestedLateFee(1, '2026-08-15'), 0);

      await pay(id, 2, fee: 20000);
      final after = await reload(id);
      expect(after.paidCount, 2);
      expect(after.depositedMinor, 200000);
      expect(after.lateFeesPaidMinor, 20000);
      expect(after.nextDue!.no, 3);
    });

    test('voiding keeps history and stops counting', () async {
      final id = (await add()).account.id;
      await pay(id, 2);
      final payment = (await repo.watchPayments(p1, id).first).single;
      await repo.voidPayment(p1, payment.id);
      expect((await reload(id)).paidCount, 0);
      expect((await repo.watchPayments(p1, id).first).single.isDeleted, isTrue);
    });

    test('rejects impossible deposits', () async {
      final id = (await add(terms: _terms(months: 3))).account.id;
      for (final (count, date) in [
        (0, today),
        (4, today),
        (1, '2026-08-09'), // before opening
        (1, '2026-11-27'), // future
      ]) {
        await expectLater(
          pay(id, count, date: date),
          throwsA(isA<ValidationException>()),
        );
      }
      await pay(id, 3);
      await expectLater(pay(id, 1), throwsA(isA<ValidationException>()));
    });

    test('validates terms and unique account numbers', () async {
      await add();
      await expectLater(
        add(terms: _terms(number: 'dps-1')),
        throwsA(isA<DuplicateNameException>()),
      );
      // Numbers are optional and unique only within a profile.
      await add(terms: _terms(number: ''));
      await add(terms: _terms(number: null));
      await repo.create(profileId: p2, terms: _terms());
      for (final bad in [
        _terms(number: 'x', installment: 0),
        _terms(number: 'x', months: 361),
        _terms(number: 'x', firstDue: '2026-08-09'),
        _terms(number: 'x', grace: 61),
        _terms(number: 'x', bankMaturity: 100),
        _terms(number: 'x', bank: ' '),
      ]) {
        await expectLater(add(terms: bad), throwsA(isA<ValidationException>()));
      }
      await expectLater(
        add(terms: _terms(number: 'y'), paid: 37),
        throwsA(isA<ValidationException>()),
      );
    });

    test('another profile cannot read or change an account', () async {
      final id = (await add(paid: 1)).account.id;
      final payment = (await repo.watchPayments(p1, id).first).single;
      expect(await repo.getById(p2, id), isNull);
      expect(await repo.loadAll(p2), isEmpty);
      await expectLater(
        repo.addPayment(
          profileId: p2,
          dpsId: id,
          installments: 1,
          paymentDate: today,
        ),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repo.voidPayment(p2, payment.id),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repo.setArchived(p2, id, true),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'the schedule locks after a deposit but rules stay editable',
      () async {
        final id = (await add()).account.id;
        await repo.update(
          profileId: p1,
          id: id,
          terms: _terms(installment: 200000),
        );
        await pay(id, 1);
        await expectLater(
          repo.update(profileId: p1, id: id, terms: _terms()),
          throwsA(isA<ValidationException>()),
        );
        final edited = await repo.update(
          profileId: p1,
          id: id,
          terms: _terms(installment: 200000, rateBp: 900, lateFee: 5),
        );
        expect((edited.terms.rateBp, edited.terms.lateFeeMinor), (900, 5));
      },
    );

    test('matured closing needs every installment and the date', () async {
      final id = (await add(
        terms: _terms(
          months: 3,
          open: '2026-08-10',
          firstDue: '2026-08-10',
          bankMaturity: 310000,
        ),
        paid: 2,
      )).account.id;
      Future<DpsPosition> close(DpsClosingType type, String date) => repo.close(
        profileId: p1,
        id: id,
        type: type,
        closedDate: date,
        profitMinor: 10000,
        taxMinor: 1000,
        chargeMinor: 500,
      );

      await expectLater(
        close(DpsClosingType.matured, today),
        throwsA(isA<ValidationException>()),
      );
      await pay(id, 1, date: '2026-10-10');
      var p = await reload(id);
      expect(p.status, DpsStatus.matured); // matures 10 Nov
      expect(p.expectedProfitMinor, 10000);
      expect(p.expectedNetMinor, 309000);
      await expectLater(
        close(DpsClosingType.matured, '2026-11-09'),
        throwsA(isA<ValidationException>()),
      );

      p = await close(DpsClosingType.matured, today);
      expect(p.status, DpsStatus.closed);
      expect(p.account.netReceivedMinor, 300000 + 10000 - 1000 - 500);

      await expectLater(pay(id, 1), throwsA(isA<ValidationException>()));
      await expectLater(
        close(DpsClosingType.premature, today),
        throwsA(isA<ValidationException>()),
      );
      final payment = (await repo.watchPayments(p1, id).first).first;
      await expectLater(
        repo.voidPayment(p1, payment.id),
        throwsA(isA<ValidationException>()),
      );
    });

    test('early closing accepts the bank figure and stops dues', () async {
      final id = (await add(paid: 2)).account.id;
      await expectLater(
        repo.close(
          profileId: p1,
          id: id,
          type: DpsClosingType.premature,
          closedDate: '2026-09-01', // a deposit is dated 10 Sep
          profitMinor: 0,
          taxMinor: 0,
          chargeMinor: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      final p = await repo.close(
        profileId: p1,
        id: id,
        type: DpsClosingType.premature,
        closedDate: today,
        profitMinor: 0,
        taxMinor: 0,
        chargeMinor: 0,
        netReceivedMinor: 198000,
      );
      expect(p.account.netReceivedMinor, 198000);
      expect(p.overdueCount, 0);
    });

    test('upcoming payments respect grace and drop closed accounts', () async {
      final id = (await add(paid: 3)).account.id;
      Future<List<(bool, int)>> upcoming(DateTime now) async => [
        for (final u in await UpcomingRepository(db, clock: () => now).load(p1))
          (u.overdue, u.count),
      ];
      // Fourth installment: due 10 Nov, grace to 15 Nov.
      expect((await upcoming(DateTime(2026, 11, 15))).first, (false, 2));
      expect((await upcoming(DateTime(2026, 11, 16))).first, (true, 1));

      await repo.setArchived(p1, id, true);
      expect(await upcoming(DateTime(2026, 11, 16)), isEmpty);
      await repo.setArchived(p1, id, false);
      await repo.close(
        profileId: p1,
        id: id,
        type: DpsClosingType.bankClosed,
        closedDate: today,
        profitMinor: 0,
        taxMinor: 0,
        chargeMinor: 0,
      );
      expect(await upcoming(DateTime(2026, 11, 16)), isEmpty);
    });

    test('reminders are planned for unpaid installments only', () async {
      await add(paid: 4);
      SharedPreferences.setMockInitialValues({});
      final plan = await NotificationScheduler(
        db: db,
        prefs: await SharedPreferences.getInstance(),
        gateway: FakeNotificationGateway(),
        activeProfileId: () => p1,
        clock: () => DateTime(2026, 11, 26, 8),
        l10n: AppLocalizationsEn.new,
      ).buildPlan();
      final dps = plan.where((n) => n.kind == NotificationKind.dps).toList();
      expect(dps, isNotEmpty);
      expect(dps.first.title, contains('City Bank DPS installment #5'));
      expect(dps.map((n) => n.dueDate), isNot(contains('2026-11-10')));
    });

    group('backup', () {
      late Directory dir;
      late BackupService backups;
      setUp(() {
        dir = Directory.systemTemp.createTempSync('mybudget_dps_');
        backups = BackupService(db, backupsDirectory: dir);
      });
      tearDown(() => dir.deleteSync(recursive: true));

      Map<String, dynamic> tables(Map<String, dynamic> j) =>
          j['tables'] as Map<String, dynamic>;

      test('accounts and deposits survive a restore', () async {
        final id = (await add(paid: 2)).account.id;
        final json = await backups.exportJson();
        expect(backups.validate(json).errors, isEmpty);

        await repo.addPayment(
          profileId: p1,
          dpsId: id,
          installments: 1,
          paymentDate: today,
        );
        await backups.restore(json);
        final p = await reload(id);
        expect((p.paidCount, p.terms.bankName), (2, 'City Bank'));
      });

      test('a backup from before DPS still restores', () async {
        final j =
            jsonDecode(await backups.exportJson()) as Map<String, dynamic>;
        j['version'] = 5;
        j['schemaVersion'] = 7;
        tables(j)
          ..remove('dps_accounts')
          ..remove('dps_payments');
        await add();
        await backups.restore(jsonEncode(j));
        expect(await repo.loadAll(p1), isEmpty);
      });

      test('damaged DPS records are rejected', () async {
        await add(paid: 2);
        final good = await backups.exportJson();
        void rejects(
          String table,
          void Function(Map<String, dynamic> row) damage,
        ) {
          final j = jsonDecode(good) as Map<String, dynamic>;
          damage((tables(j)[table] as List).first as Map<String, dynamic>);
          expect(backups.validate(jsonEncode(j)).isValid, isFalse);
        }

        rejects('dps_accounts', (r) => r['installment_minor'] = 0);
        rejects('dps_accounts', (r) => r['closing_type'] = 'lost');
        rejects('dps_accounts', (r) => r['closing_type'] = 'premature');
        rejects('dps_accounts', (r) => r['tenure_months'] = 1);
        rejects('dps_accounts', (r) => r['profile_id'] = p2);
        rejects('dps_payments', (r) => r['dps_id'] = 999);
        rejects('dps_payments', (r) => r['installments'] = 0);
      });
    });
  });

  test('a schema 7 database gains the DPS tables and keeps data', () async {
    final dir = Directory.systemTemp.createTempSync('mybudget_v8_');
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    final profile = await _profile(db, 'Kept');
    // Turn the file back into a version 7 database.
    await db.customStatement('DROP TABLE dps_payments');
    await db.customStatement('DROP TABLE dps_accounts');
    await db.customStatement('PRAGMA user_version = 7');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });
    final repo = DpsRepository(db, today: () => '2026-11-26');
    await repo.create(profileId: profile, terms: _terms());
    await expectLater(
      repo.create(profileId: profile, terms: _terms()),
      throwsA(isA<DuplicateNameException>()),
    );
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    expect(
      indexes.map((r) => r.read<String>('name')),
      containsAll(['uq_dps_account_number', 'idx_dps_payments_account']),
    );
    expect((await db.select(db.financialProfiles).getSingle()).name, 'Kept');
  });
}
