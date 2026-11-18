import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/exchange_rate_repository.dart';
import '../domain/exchange_rate.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>(
  (ref) => ExchangeRateRepository(ref.watch(appDatabaseProvider)),
);

/// Active manual rates of the active profile (for pickers).
final exchangeRatesProvider = StreamProvider<List<ExchangeRate>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return const Stream.empty();
  return ref.watch(exchangeRateRepositoryProvider).watchRates(profileId);
});

/// All rates including deactivated ones (for the management screen).
final allExchangeRatesProvider = StreamProvider<List<ExchangeRate>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return const Stream.empty();
  return ref
      .watch(exchangeRateRepositoryProvider)
      .watchRates(profileId, includeInactive: true);
});
