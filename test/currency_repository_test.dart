import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/currency/data/exchange_rate_repository.dart';

Future<int> _profile(AppDatabase db, String name, {String currency = 'BDT'}) {
  final now = DateTime.now();
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          currencyCode: Value(currency),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late ExchangeRateRepository repo;
  late int a;
  late int b;

  setUp(() async {
    db = AppDatabase.memory();
    repo = ExchangeRateRepository(db);
    a = await _profile(db, 'A');
    b = await _profile(db, 'B');
  });
  tearDown(() => db.close());

  test('create stores an active rate', () async {
    final r = await repo.upsert(
      profileId: a,
      currencyCode: 'USD',
      rateMicro: 122500000,
    );
    expect(r.currencyCode, 'USD');
    expect(r.rateMicro, 122500000);
    expect(r.isActive, isTrue);
    expect(r.profileId, a);
  });

  test('update changes the rate and re-activates', () async {
    final r = await repo.upsert(
      profileId: a,
      currencyCode: 'USD',
      rateMicro: 120000000,
    );
    await repo.setActive(a, r.id, false);
    final u = await repo.upsert(
      profileId: a,
      currencyCode: 'USD',
      rateMicro: 123000000,
    );
    expect(u.id, r.id);
    expect(u.rateMicro, 123000000);
    expect(u.isActive, isTrue);
  });

  test('duplicate currency upsert updates, never duplicates', () async {
    await repo.upsert(profileId: a, currencyCode: 'EUR', rateMicro: 130000000);
    await repo.upsert(profileId: a, currencyCode: 'EUR', rateMicro: 131000000);
    final all = await repo.watchRates(a, includeInactive: true).first;
    expect(all, hasLength(1));
    expect(all.single.rateMicro, 131000000);
  });

  test('currency code is case-insensitive', () async {
    final r = await repo.upsert(
      profileId: a,
      currencyCode: ' usd ',
      rateMicro: 120000000,
    );
    expect(r.currencyCode, 'USD');
    await repo.upsert(profileId: a, currencyCode: 'USD', rateMicro: 121000000);
    expect(await repo.watchRates(a, includeInactive: true).first, hasLength(1));
    expect((await repo.getActiveRate(a, 'usd'))!.rateMicro, 121000000);
  });

  test('base currency is rejected', () async {
    await expectLater(
      repo.upsert(profileId: a, currencyCode: 'bdt', rateMicro: 1000000),
      throwsA(isA<ValidationException>()),
    );
    final eurBase = await _profile(db, 'EUR profile', currency: 'EUR');
    await expectLater(
      repo.upsert(profileId: eurBase, currencyCode: 'EUR', rateMicro: 1000000),
      throwsA(isA<ValidationException>()),
    );
    // BDT is a normal foreign currency for a EUR-based profile.
    final ok = await repo.upsert(
      profileId: eurBase,
      currencyCode: 'BDT',
      rateMicro: 8000,
    );
    expect(ok.currencyCode, 'BDT');
  });

  test('invalid code or rate is rejected', () async {
    for (final code in ['US', 'USDD', 'U1D', '', '12 ']) {
      await expectLater(
        repo.upsert(profileId: a, currencyCode: code, rateMicro: 1000000),
        throwsA(isA<ValidationException>()),
        reason: code,
      );
    }
    for (final rate in [0, -5, 1000001 * 1000000]) {
      await expectLater(
        repo.upsert(profileId: a, currencyCode: 'USD', rateMicro: rate),
        throwsA(isA<ValidationException>()),
        reason: '$rate',
      );
    }
    expect(await repo.watchRates(a, includeInactive: true).first, isEmpty);
  });

  test('setActive hides from active list and getActiveRate', () async {
    final r = await repo.upsert(
      profileId: a,
      currencyCode: 'GBP',
      rateMicro: 150000000,
    );
    expect(await repo.getActiveRate(a, 'GBP'), isNotNull);
    await repo.setActive(a, r.id, false);
    expect(await repo.getActiveRate(a, 'GBP'), isNull);
    expect(await repo.watchRates(a).first, isEmpty);
    expect(await repo.watchRates(a, includeInactive: true).first, hasLength(1));
    await repo.setActive(a, r.id, true);
    expect(await repo.getActiveRate(a, 'GBP'), isNotNull);
    expect(await repo.getActiveRate(a, 'bad'), isNull);
  });

  test('cross-profile setActive is rejected and changes nothing', () async {
    final r = await repo.upsert(
      profileId: a,
      currencyCode: 'USD',
      rateMicro: 120000000,
    );
    await expectLater(
      repo.setActive(b, r.id, false),
      throwsA(isA<ProfileMismatchException>()),
    );
    await expectLater(
      repo.setActive(a, 9999, false),
      throwsA(isA<NotFoundException>()),
    );
    expect(await repo.getActiveRate(a, 'USD'), isNotNull);
  });

  test('rates are isolated per profile', () async {
    await repo.upsert(profileId: a, currencyCode: 'USD', rateMicro: 120000000);
    await repo.upsert(profileId: b, currencyCode: 'USD', rateMicro: 125000000);
    await repo.upsert(profileId: b, currencyCode: 'EUR', rateMicro: 135000000);
    expect((await repo.getActiveRate(a, 'USD'))!.rateMicro, 120000000);
    expect((await repo.getActiveRate(b, 'USD'))!.rateMicro, 125000000);
    expect(await repo.getActiveRate(a, 'EUR'), isNull);
    expect(await repo.watchRates(a).first, hasLength(1));
    expect(await repo.watchRates(b).first, hasLength(2));
  });
}
