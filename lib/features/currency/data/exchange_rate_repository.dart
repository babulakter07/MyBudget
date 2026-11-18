import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/currency.dart';
import '../domain/exchange_rate.dart';

/// Manual exchange rates for entering transactions in a foreign currency.
/// The profile's own currency is the base and cannot have a rate.
class ExchangeRateRepository {
  ExchangeRateRepository(this._db);
  final AppDatabase _db;

  ExchangeRate _map(ExchangeRateRow r) => ExchangeRate(
    id: r.id,
    profileId: r.profileId,
    currencyCode: r.currencyCode,
    rateMicro: r.rateMicro,
    isActive: r.isActive,
    updatedAt: r.updatedAt,
  );

  Future<String> _baseCurrency(int profileId) async {
    final p = await (_db.select(
      _db.financialProfiles,
    )..where((t) => t.id.equals(profileId))).getSingleOrNull();
    if (p == null) throw NotFoundException('Profile not found.');
    return p.currencyCode.toUpperCase();
  }

  Stream<List<ExchangeRate>> watchRates(
    int profileId, {
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.exchangeRates)
      ..where(
        (r) =>
            r.profileId.equals(profileId) &
            (includeInactive ? const Constant(true) : r.isActive.equals(true)),
      )
      ..orderBy([(r) => OrderingTerm(expression: r.currencyCode)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  /// Active rate for [code], or null (also null for the base currency).
  Future<ExchangeRate?> getActiveRate(int profileId, String code) async {
    final c = normalizeCurrencyCode(code);
    if (c == null) return null;
    final row =
        await (_db.select(_db.exchangeRates)..where(
              (r) =>
                  r.profileId.equals(profileId) &
                  r.currencyCode.equals(c) &
                  r.isActive.equals(true),
            ))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// Creates the rate for [currencyCode] or updates (and re-activates) it.
  Future<ExchangeRate> upsert({
    required int profileId,
    required String currencyCode,
    required int rateMicro,
  }) async {
    final code = normalizeCurrencyCode(currencyCode);
    if (code == null) {
      throw ValidationException('Currency code must be 3 letters, e.g. USD.');
    }
    if (rateMicro <= 0 || rateMicro > maxRateMicro) {
      throw ValidationException('Enter a valid exchange rate.');
    }
    return _db.transaction(() async {
      final base = await _baseCurrency(profileId);
      if (code == base) {
        throw ValidationException(
          '$code is the base currency of this profile and needs no rate.',
        );
      }
      final now = DateTime.now();
      final existing =
          await (_db.select(_db.exchangeRates)..where(
                (r) =>
                    r.profileId.equals(profileId) & r.currencyCode.equals(code),
              ))
              .getSingleOrNull();
      if (existing == null) {
        final id = await _db
            .into(_db.exchangeRates)
            .insert(
              ExchangeRatesCompanion.insert(
                profileId: profileId,
                currencyCode: code,
                rateMicro: rateMicro,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _map(
          await (_db.select(
            _db.exchangeRates,
          )..where((r) => r.id.equals(id))).getSingle(),
        );
      }
      await (_db.update(
        _db.exchangeRates,
      )..where((r) => r.id.equals(existing.id))).write(
        ExchangeRatesCompanion(
          rateMicro: Value(rateMicro),
          isActive: const Value(true),
          updatedAt: Value(now),
        ),
      );
      return _map(
        await (_db.select(
          _db.exchangeRates,
        )..where((r) => r.id.equals(existing.id))).getSingle(),
      );
    });
  }

  /// Deactivates/reactivates a rate. Transactions already saved keep their
  /// stored original amount, currency and rate.
  Future<void> setActive(int profileId, int id, bool active) async {
    final row = await (_db.select(
      _db.exchangeRates,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('Exchange rate not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Exchange rate belongs to another profile.',
      );
    }
    await (_db.update(_db.exchangeRates)..where((r) => r.id.equals(id))).write(
      ExchangeRatesCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
