import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/fixed_deposits/data/fixed_deposit_repository.dart';
import 'package:my_budget/features/fixed_deposits/domain/fixed_deposit.dart';
import 'package:my_budget/features/fixed_deposits/domain/fixed_deposit_calculator.dart';

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime.now();
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
  late AppDatabase db;
  late FixedDepositRepository repo;
  late int p1;
  late int p2;
  var today = '2026-06-01';

  setUp(() async {
    today = '2026-06-01';
    db = AppDatabase.memory();
    repo = FixedDepositRepository(db, today: () => today);
    p1 = await _profile(db, 'One');
    p2 = await _profile(db, 'Two');
  });
  tearDown(() => db.close());

  // 10,00,000.00 at 10 % for 365 days from 2026-01-15.
  Future<FixedDepositPosition> make({
    int? profile,
    String bank = 'City Bank',
    String number = 'FDR-001',
    int principal = 100000000,
    int days = 365,
    int rate = 1000,
  }) => repo.create(
    profileId: profile ?? p1,
    bankName: bank,
    instrumentNumber: number,
    startDate: '2026-01-15',
    tenureDays: days,
    rateBp: rate,
    principalMinor: principal,
  );

  Future<FixedDepositPosition> reissue(
    FixedDepositPosition p, {
    String settled = '2027-01-15',
    int interest = 10000000,
    int tax = 1000000,
    int charge = 0,
    int? net,
    String number = 'FDR-002',
    String start = '2027-01-15',
    int days = 180,
    int rate = 900,
  }) => repo.reissue(
    profileId: p1,
    termId: p.current.id,
    settledDate: settled,
    interestMinor: interest,
    taxMinor: tax,
    bankChargeMinor: charge,
    netReceivedMinor: net,
    newInstrumentNumber: number,
    newStartDate: start,
    newTenureDays: days,
    newRateBp: rate,
  );

  group('create', () {
    test('creates the deposit with its first instrument', () async {
      final p = await make();
      expect(p.terms.length, 1);
      expect(p.current.termNo, 1);
      expect(p.current.instrumentNumber, 'FDR-001');
      expect(p.deposit.schemeType, 'FDR');
      expect(p.status, FdStatus.active);
      expect(p.maturityDate, '2027-01-15');
      expect(p.placedMinor, 100000000);
    });

    test('validates input', () async {
      await expectLater(make(bank: '  '), throwsA(isA<ValidationException>()));
      await expectLater(make(number: ' '), throwsA(isA<ValidationException>()));
      await expectLater(
        make(principal: 0),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(make(days: 0), throwsA(isA<ValidationException>()));
      await expectLater(make(rate: 10001), throwsA(isA<ValidationException>()));
    });

    test('instrument number is unique per profile, case-insensitive', () async {
      await make();
      await expectLater(
        make(number: 'fdr-001'),
        throwsA(isA<DuplicateNameException>()),
      );
      // Another profile may reuse it.
      await make(profile: p2, number: 'FDR-001');
    });

    test('unknown profile is rejected', () async {
      await expectLater(make(profile: 999), throwsA(isA<NotFoundException>()));
    });

    test('profile isolation', () async {
      final a = await make();
      await make(profile: p2, number: 'X-1');
      expect((await repo.watchAll(p1).first).length, 1);
      expect(await repo.getById(p2, a.deposit.id), isNull);
      await expectLater(
        repo.encash(
          profileId: p2,
          termId: a.current.id,
          settledDate: '2027-01-15',
          interestMinor: 0,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('maturity status', () {
    test('matured once the date is reached', () async {
      final p = await make();
      today = '2027-01-15';
      expect((await repo.getById(p1, p.deposit.id))!.status, FdStatus.matured);
    });
  });

  group('reissue', () {
    test(
      'net received becomes the new principal, linked to the old one',
      () async {
        final p = await make();
        final r = await reissue(p);
        expect(r.terms.length, 2);
        final old = r.terms.first;
        expect(old.outcome, fdOutcomeReissued);
        expect(old.settledDate, '2027-01-15');
        expect(old.interestMinor, 10000000);
        expect(old.taxMinor, 1000000);
        // 10,00,000 + 1,00,000 - 10,000 = 10,90,000.00
        expect(old.netReceivedMinor, 109000000);
        expect(r.current.principalMinor, 109000000);
        expect(r.current.termNo, 2);
        expect(r.current.instrumentNumber, 'FDR-002');
        expect(r.current.renewedFromTermId, old.id);
        expect(r.current.tenureDays, 180);
        expect(r.current.rateBp, 900);
        expect(r.reissueCount, 1);
        expect(r.status, FdStatus.active);
      },
    );

    test('bank charge is deducted from the net', () async {
      final r = await reissue(await make(), charge: 50000);
      expect(r.current.principalMinor, 108950000);
    });

    test('a final net figure overrides the calculation', () async {
      final r = await reissue(await make(), net: 108000000);
      expect(r.terms.first.netReceivedMinor, 108000000);
      expect(r.current.principalMinor, 108000000);
    });

    test('chains several reissues', () async {
      var p = await make();
      for (var i = 0; i < 3; i++) {
        p = await repo.reissue(
          profileId: p1,
          termId: p.current.id,
          settledDate: p.maturityDate,
          interestMinor: 1000,
          newInstrumentNumber: 'R-$i',
          newStartDate: p.maturityDate,
          newTenureDays: 365,
          newRateBp: 1000,
        );
      }
      expect(p.terms.map((t) => t.termNo).toList(), [1, 2, 3, 4]);
      expect(p.reissueCount, 3);
      expect(p.terms.where((t) => t.isActive).length, 1);
      expect(p.earnedInterestMinor, 3000);
    });

    test('can reissue before maturity (early)', () async {
      final r = await reissue(
        await make(),
        settled: '2026-07-20',
        start: '2026-07-20',
        interest: 2000000,
        tax: 0,
      );
      expect(r.current.principalMinor, 102000000);
    });

    test('new instrument number must be new', () async {
      final p = await make();
      await expectLater(
        reissue(p, number: 'fdr-001'),
        throwsA(isA<DuplicateNameException>()),
      );
    });

    test('rejects bad new terms and leaves the old one untouched', () async {
      final p = await make();
      await expectLater(
        reissue(p, days: 0),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        reissue(p, number: ' '),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        reissue(p, net: 0),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        reissue(p, start: '2026-01-15'),
        throwsA(isA<ValidationException>()),
      );
      final again = (await repo.getById(p1, p.deposit.id))!;
      expect(again.terms.length, 1);
      expect(again.current.isActive, isTrue);
    });

    test('a closed instrument cannot be closed twice', () async {
      final p = await make();
      await reissue(p);
      await expectLater(reissue(p), throwsA(isA<ValidationException>()));
      await expectLater(
        repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: '2027-01-15',
          interestMinor: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('encash', () {
    test('records the figures and closes the deposit', () async {
      final p = await make();
      final r = await repo.encash(
        profileId: p1,
        termId: p.current.id,
        settledDate: '2027-01-16',
        interestMinor: 10000000,
        taxMinor: 1000000,
        bankChargeMinor: 50000,
      );
      expect(r.status, FdStatus.closed);
      expect(r.current.outcome, fdOutcomeEncashed);
      expect(r.current.netReceivedMinor, 108950000);
      expect(r.placedMinor, 0);
    });

    test('rejects invalid figures', () async {
      final p = await make();
      for (final bad in [
        () => repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: '2027-01-15',
          interestMinor: -1,
        ),
        () => repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: '2025-12-31',
          interestMinor: 0,
        ),
        () => repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: 'nope',
          interestMinor: 0,
        ),
        () => repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: '2027-01-15',
          interestMinor: 0,
          netReceivedMinor: -5,
        ),
      ]) {
        await expectLater(bad(), throwsA(isA<ValidationException>()));
      }
    });
  });

  group('edit and archive', () {
    test('updateDeposit changes bank details only', () async {
      final p = await make();
      await repo.updateDeposit(
        profileId: p1,
        depositId: p.deposit.id,
        schemeType: 'DPS',
        bankName: 'Sonali Bank',
        beneficiaryName: 'Spouse',
      );
      final r = (await repo.getById(p1, p.deposit.id))!;
      expect(r.deposit.bankName, 'Sonali Bank');
      expect(r.deposit.schemeType, 'DPS');
      expect(r.deposit.beneficiaryName, 'Spouse');
      expect(r.current.principalMinor, 100000000);
    });

    test('updateActiveTerm edits only a running instrument', () async {
      final p = await make();
      await repo.updateActiveTerm(
        profileId: p1,
        termId: p.current.id,
        instrumentNumber: 'FDR-001A',
        startDate: '2026-01-15',
        tenureDays: 180,
        rateBp: 1100,
        principalMinor: 100000000,
      );
      final r = (await repo.getById(p1, p.deposit.id))!;
      expect(r.current.tenureDays, 180);
      expect(r.current.instrumentNumber, 'FDR-001A');
      await repo.encash(
        profileId: p1,
        termId: r.current.id,
        settledDate: '2026-07-15',
        interestMinor: 0,
      );
      await expectLater(
        repo.updateActiveTerm(
          profileId: p1,
          termId: r.current.id,
          instrumentNumber: 'FDR-001A',
          startDate: '2026-01-15',
          tenureDays: 180,
          rateBp: 1100,
          principalMinor: 100000000,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('editing cannot steal another instrument number', () async {
      await make();
      final b = await make(number: 'FDR-002');
      await expectLater(
        repo.updateActiveTerm(
          profileId: p1,
          termId: b.current.id,
          instrumentNumber: 'FDR-001',
          startDate: '2026-01-15',
          tenureDays: 365,
          rateBp: 1000,
          principalMinor: 100000000,
        ),
        throwsA(isA<DuplicateNameException>()),
      );
    });

    test('archived deposits are hidden and cannot be closed', () async {
      final p = await make();
      await repo.setArchived(
        profileId: p1,
        depositId: p.deposit.id,
        archived: true,
      );
      expect(await repo.watchAll(p1).first, isEmpty);
      expect((await repo.watchAll(p1, includeArchived: true).first).length, 1);
      expect((await repo.watchSummary(p1).first).openCount, 0);
      await expectLater(
        repo.encash(
          profileId: p1,
          termId: p.current.id,
          settledDate: '2027-01-15',
          interestMinor: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      await repo.setArchived(
        profileId: p1,
        depositId: p.deposit.id,
        archived: false,
      );
      expect((await repo.watchSummary(p1).first).openCount, 1);
    });
  });
}
