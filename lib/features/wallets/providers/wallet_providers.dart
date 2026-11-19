import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(appDatabaseProvider)),
);

/// Injectable clock ("this month" and default dates).
final walletClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final walletOverviewProvider = StreamProvider<WalletOverview>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(WalletOverview.empty);
  final now = ref.watch(walletClockProvider)();
  return ref.watch(walletRepositoryProvider).watchOverview(profileId, now: now);
});

final walletProvider = StreamProvider.family<WalletItem?, int>((
  ref,
  accountId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  final now = ref.watch(walletClockProvider)();
  return ref
      .watch(walletRepositoryProvider)
      .watchWallet(profileId, accountId, now: now);
});

class WalletPeriodNotifier extends Notifier<WalletPeriod> {
  @override
  WalletPeriod build() => WalletPeriod.thisMonth;
  void set(WalletPeriod p) => state = p;
}

final walletPeriodProvider =
    NotifierProvider<WalletPeriodNotifier, WalletPeriod>(
      WalletPeriodNotifier.new,
    );

/// Ledger of one account for the selected period (running balance in SQL).
final walletLedgerProvider = StreamProvider.family<AccountLedger, int>((
  ref,
  accountId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const AccountLedger([]));
  final period = ref.watch(walletPeriodProvider);
  final range = walletPeriodRange(period, ref.watch(walletClockProvider)());
  return ref
      .watch(ledgerRepositoryProvider)
      .watchAccountLedger(
        profileId: profileId,
        accountId: accountId,
        from: range.from,
        to: range.to,
      );
});
