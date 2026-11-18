import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/core/utils/currency.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late int p1, p2, cash, cash2, food;
  final now = DateTime(2026, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    repo = TransactionRepository(db);
    p1 = await db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: 'One',
            createdAt: now,
            updatedAt: now,
          ),
        );
    p2 = await db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: 'Two',
            currencyCode: const Value('USD'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    Future<int> acc(int p, String n) => db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: p,
            name: n,
            openingDate: '2020-01-01',
            createdAt: now,
            updatedAt: now,
          ),
        );
    cash = await acc(p1, 'Cash');
    cash2 = await acc(p1, 'Bank');
    food = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            profileId: p1,
            name: 'Food',
            createdAt: now,
            updatedAt: now,
          ),
        );
  });
  tearDown(() => db.close());

  Future<dynamic> exp({
    int amount = 245000,
    int? orig = 2000,
    String? cur = 'USD',
    int? rate = 122500000,
    int? profile,
    int? account,
  }) => repo.createExpense(
    profileId: profile ?? p1,
    accountId: account ?? cash,
    categoryId: food,
    amountMinor: amount,
    originalAmountMinor: orig,
    originalCurrency: cur,
    rateMicro: rate,
    date: '2026-02-10',
  );

  test(
    'valid foreign expense stores base amount and original fields',
    () async {
      final t = await exp(cur: 'usd');
      expect(t.amountMinor, 245000);
      expect(t.originalAmountMinor, 2000);
      expect(t.originalCurrency, 'USD');
      expect(t.rateMicro, 122500000);
      expect(t.isForeign, isTrue);
      final got = await repo.getById(p1, t.id);
      expect(got!.isForeign, isTrue);
    },
  );

  test('valid foreign income', () async {
    final t = await repo.createIncome(
      profileId: p1,
      accountId: cash,
      incomeSource: 'Freelance',
      amountMinor: 1225000,
      originalAmountMinor: 10000,
      originalCurrency: 'USD',
      rateMicro: 122500000,
      date: '2026-02-10',
    );
    expect(t.isForeign, isTrue);
    expect(t.amountMinor, 1225000);
  });

  test('plain base transaction has no original fields', () async {
    final t = await exp(orig: null, cur: null, rate: null);
    expect(t.isForeign, isFalse);
    expect(t.originalCurrency, isNull);
  });

  test('all-or-none is enforced', () async {
    for (final args in [
      [2000, null, null],
      [null, 'USD', null],
      [null, null, 122500000],
      [2000, 'USD', null],
      [2000, null, 122500000],
      [null, 'USD', 122500000],
    ]) {
      await expectLater(
        exp(
          orig: args[0] as int?,
          cur: args[1] as String?,
          rate: args[2] as int?,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
    expect(await db.select(db.financialTransactions).get(), isEmpty);
  });

  test('amount must equal the exact conversion', () async {
    await expectLater(exp(amount: 245001), throwsA(isA<ValidationException>()));
    await expectLater(exp(amount: 1), throwsA(isA<ValidationException>()));
    // 1 cent * 122.5 = 122.5 -> rounds half up to 123.
    final t = await exp(amount: 123, orig: 1);
    expect(t.amountMinor, 123);
    expect(
      convertToBaseMinor(originalMinor: 1, rateMicro: 122500000),
      t.amountMinor,
    );
  });

  test(
    'base currency, bad code, bad amount and rate bounds rejected',
    () async {
      await expectLater(
        exp(cur: 'BDT', rate: 1000000, orig: 245000),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(exp(cur: 'US'), throwsA(isA<ValidationException>()));
      await expectLater(
        exp(orig: 0, amount: 0),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        exp(orig: -5, amount: 5),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        exp(rate: 0, amount: 1),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        exp(rate: maxRateMicro + 1, amount: 1),
        throwsA(isA<ValidationException>()),
      );
      final t = await exp(rate: maxRateMicro, orig: 1, amount: 1000000);
      expect(t.rateMicro, maxRateMicro);
    },
  );

  test('base currency is the profile currency (USD profile)', () async {
    final a = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: p2,
            name: 'Wallet',
            openingDate: '2020-01-01',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await expectLater(
      repo.createIncome(
        profileId: p2,
        accountId: a,
        incomeSource: 'Pay',
        amountMinor: 100,
        originalAmountMinor: 100,
        originalCurrency: 'USD',
        rateMicro: 1000000,
        date: '2026-02-10',
      ),
      throwsA(isA<ValidationException>()),
    );
    // BDT is foreign for that profile: 100.00 BDT at 0.01 = 1.00 USD.
    final t = await repo.createIncome(
      profileId: p2,
      accountId: a,
      incomeSource: 'Pay',
      amountMinor: 100,
      originalAmountMinor: 10000,
      originalCurrency: 'BDT',
      rateMicro: 10000,
      date: '2026-02-10',
    );
    expect(t.originalCurrency, 'BDT');
  });

  test('transfers reject original fields and carry none', () async {
    await expectLater(
      repo.createTransfer(
        profileId: p1,
        fromAccountId: cash,
        toAccountId: cash2,
        amountMinor: 245000,
        originalAmountMinor: 2000,
        originalCurrency: 'USD',
        rateMicro: 122500000,
        date: '2026-02-10',
      ),
      throwsA(isA<ValidationException>()),
    );
    final t = await repo.createTransfer(
      profileId: p1,
      fromAccountId: cash,
      toAccountId: cash2,
      amountMinor: 100,
      date: '2026-02-10',
    );
    expect(t.isForeign, isFalse);
    await expectLater(
      repo.updateTransfer(
        profileId: p1,
        id: t.id,
        fromAccountId: cash,
        toAccountId: cash2,
        amountMinor: 100,
        originalCurrency: 'USD',
        date: '2026-02-10',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('edit to foreign, between currencies, and back to base', () async {
    final base = await exp(orig: null, cur: null, rate: null, amount: 5000);
    Future<dynamic> upd({int? o, String? c, int? r, required int amount}) =>
        repo.updateExpense(
          profileId: p1,
          id: base.id,
          accountId: cash,
          categoryId: food,
          amountMinor: amount,
          originalAmountMinor: o,
          originalCurrency: c,
          rateMicro: r,
          date: '2026-02-10',
        );
    var t = await upd(o: 2000, c: 'USD', r: 122500000, amount: 245000);
    expect(t.isForeign, isTrue);
    t = await upd(o: 1000, c: 'eur', r: 130000000, amount: 130000);
    expect(t.originalCurrency, 'EUR');
    expect(t.amountMinor, 130000);
    await expectLater(
      upd(o: 1000, c: 'EUR', r: 130000000, amount: 999),
      throwsA(isA<ValidationException>()),
    );
    t = await upd(amount: 7000);
    expect(t.isForeign, isFalse);
    final row = await (db.select(
      db.financialTransactions,
    )..where((r) => r.id.equals(base.id))).getSingle();
    expect(row.originalAmountMinor, isNull);
    expect(row.originalCurrency, isNull);
    expect(row.rateMicro, isNull);
    expect(row.amountMinor, 7000);
  });

  test('audit snapshots include the original fields', () async {
    final t = await exp();
    await repo.updateExpense(
      profileId: p1,
      id: t.id,
      accountId: cash,
      categoryId: food,
      amountMinor: 7000,
      date: '2026-02-10',
    );
    final logs =
        await (db.select(db.transactionAuditLogs)
              ..where((a) => a.transactionId.equals(t.id))
              ..orderBy([(a) => OrderingTerm.asc(a.id)]))
            .get();
    final created = jsonDecode(logs.first.newJson!) as Map<String, dynamic>;
    expect(created['originalAmountMinor'], 2000);
    expect(created['originalCurrency'], 'USD');
    expect(created['rateMicro'], 122500000);
    final upd = logs.last;
    expect((jsonDecode(upd.previousJson!) as Map)['originalCurrency'], 'USD');
    expect((jsonDecode(upd.newJson!) as Map)['originalCurrency'], isNull);
  });

  test('idempotent retry returns the same foreign row', () async {
    Future<dynamic> go() => repo.createExpense(
      profileId: p1,
      accountId: cash,
      categoryId: food,
      amountMinor: 245000,
      originalAmountMinor: 2000,
      originalCurrency: 'USD',
      rateMicro: 122500000,
      date: '2026-02-10',
      idempotencyKey: 'k1',
    );
    final a = await go();
    final b = await go();
    expect(b.id, a.id);
    expect(await db.select(db.financialTransactions).get(), hasLength(1));
  });

  test('cross-profile account is still rejected', () async {
    final other = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: p2,
            name: 'X',
            openingDate: '2020-01-01',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await expectLater(
      exp(account: other),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(await db.select(db.financialTransactions).get(), isEmpty);
  });
}
