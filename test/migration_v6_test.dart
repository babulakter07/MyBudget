import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';

const _ts = 1700000000;

/// A v5 database reduced to what the v6 step needs (a profile row).
AppDatabase _openV5() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
CREATE TABLE financial_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'BDT',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        raw.execute(
          "INSERT INTO financial_profiles VALUES (1,'Home','BDT',1,$_ts,$_ts)",
        );
        raw.execute('PRAGMA user_version = 5');
      },
    ),
  );
}

Future<void> _sql(AppDatabase db, String sql) => db.customStatement(sql);

Future<List<Map<String, Object?>>> _rows(AppDatabase db, String q) async =>
    (await db.customSelect(q).get()).map((r) => r.data).toList();

const _loan =
    "INSERT INTO loans (id,profile_id,lender_name,loan_type,principal_minor,interest_rate_bp,interest_method,frequency,tenure_count,installment_minor,processing_fee_minor,start_date,first_due_date,is_active,created_at,updated_at) "
    "VALUES (1,1,'City Bank','personal',10000000,1200,'reducing','monthly',12,888488,0,'2026-01-01','2026-02-01',1,$_ts,$_ts)";

const _card =
    "INSERT INTO credit_cards (id,profile_id,name,bank_name,credit_limit_minor,statement_day,due_days,apr_bp,min_payment_bp,created_at,updated_at) "
    "VALUES (1,1,'Visa','EBL',10000000,5,20,2400,500,$_ts,$_ts)";

const _bill =
    "INSERT INTO credit_card_bills (id,profile_id,card_id,bill_month,statement_date,due_date,amount_minor,min_payment_minor,is_active,created_at,updated_at) "
    "VALUES (1,1,1,'2026-03','2026-03-05','2026-03-25',100000,5000,1,$_ts,$_ts)";

void main() {
  test('schema version is 7', () {
    expect(AppDatabase.currentSchemaVersion, 7);
  });

  test('v5 -> v6 creates loan and credit card tables, keeps data', () async {
    final db = _openV5();
    addTearDown(db.close);

    expect(await _rows(db, 'SELECT name FROM financial_profiles'), [
      {'name': 'Home'},
    ]);
    final tables = (await _rows(
      db,
      "SELECT name FROM sqlite_master WHERE type='table'",
    )).map((r) => r['name']).toSet();
    expect(
      tables,
      containsAll([
        'loans',
        'loan_payments',
        'credit_cards',
        'credit_card_bills',
        'credit_card_payments',
      ]),
    );
    final indexes = (await _rows(
      db,
      "SELECT name FROM sqlite_master WHERE type='index'",
    )).map((r) => r['name']).toSet();
    expect(
      indexes,
      containsAll([
        'idx_loan_payments_loan',
        'uq_cards_profile_name',
        'uq_card_bills_month',
        'idx_card_bills_card',
        'idx_card_payments_bill',
      ]),
    );

    await _sql(db, _loan);
    await _sql(
      db,
      "INSERT INTO loan_payments (profile_id,loan_id,amount_minor,payment_date,created_at) VALUES (1,1,888488,'2026-02-01',$_ts)",
    );
    await _sql(db, _card);
    await _sql(db, _bill);
    await _sql(
      db,
      "INSERT INTO credit_card_payments (profile_id,bill_id,amount_minor,payment_date,created_at) VALUES (1,1,5000,'2026-03-20',$_ts)",
    );
    expect(await _rows(db, 'SELECT * FROM loan_payments'), hasLength(1));
    expect(await _rows(db, 'SELECT * FROM credit_card_payments'), hasLength(1));
  });

  test('fresh database enforces constraints and composite FKs', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await _sql(
      db,
      "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (1,'Home','BDT',1,$_ts,$_ts)",
    );
    await _sql(
      db,
      "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (2,'Work','BDT',1,$_ts,$_ts)",
    );
    await _sql(db, _loan);
    await _sql(db, _card);
    await _sql(db, _bill);

    // Cross-profile loan payment is rejected by the composite FK.
    await expectLater(
      _sql(
        db,
        "INSERT INTO loan_payments (profile_id,loan_id,amount_minor,payment_date,created_at) VALUES (2,1,100,'2026-02-01',$_ts)",
      ),
      throwsA(anything),
    );
    // Non-positive amounts are rejected.
    await expectLater(
      _sql(
        db,
        "INSERT INTO loan_payments (profile_id,loan_id,amount_minor,payment_date,created_at) VALUES (1,1,0,'2026-02-01',$_ts)",
      ),
      throwsA(anything),
    );
    // Card names are unique per profile, ignoring case.
    await expectLater(
      _sql(
        db,
        "INSERT INTO credit_cards (profile_id,name,bank_name,credit_limit_minor,statement_day,due_days,apr_bp,min_payment_bp,created_at,updated_at) VALUES (1,'VISA','X',100,5,20,0,0,$_ts,$_ts)",
      ),
      throwsA(anything),
    );
    // Same name in another profile is fine.
    await _sql(
      db,
      "INSERT INTO credit_cards (profile_id,name,bank_name,credit_limit_minor,statement_day,due_days,apr_bp,min_payment_bp,created_at,updated_at) VALUES (2,'VISA','X',100,5,20,0,0,$_ts,$_ts)",
    );
    // One active bill per card per month; a voided one does not block.
    await expectLater(
      _sql(db, _bill.replaceFirst('VALUES (1,', 'VALUES (2,')),
      throwsA(anything),
    );
    await _sql(db, 'UPDATE credit_card_bills SET is_active = 0 WHERE id = 1');
    await _sql(db, _bill.replaceFirst('VALUES (1,', 'VALUES (2,'));
    // Minimum payment may not exceed the bill.
    await expectLater(
      _sql(
        db,
        "INSERT INTO credit_card_bills (profile_id,card_id,bill_month,statement_date,due_date,amount_minor,min_payment_minor,created_at,updated_at) VALUES (1,1,'2026-04','2026-04-05','2026-04-25',100,200,$_ts,$_ts)",
      ),
      throwsA(anything),
    );
    // Statement day outside 1..28 is rejected.
    await expectLater(
      _sql(
        db,
        "INSERT INTO credit_cards (profile_id,name,bank_name,credit_limit_minor,statement_day,due_days,apr_bp,min_payment_bp,created_at,updated_at) VALUES (1,'Z','X',100,31,20,0,0,$_ts,$_ts)",
      ),
      throwsA(anything),
    );
  });
}
