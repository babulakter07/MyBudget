import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger_models.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(appDatabaseProvider)),
);

/// Injectable clock so default filters (current month) are testable.
final ledgerClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Accounts (active and inactive) of the active profile.
final ledgerAccountsProvider = StreamProvider<List<LedgerAccount>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <LedgerAccount>[]);
  return ref.watch(ledgerRepositoryProvider).watchAccounts(profileId);
});

class AccountLedgerFilter {
  const AccountLedgerFilter({
    this.accountId,
    required this.from,
    required this.to,
    this.search = '',
  });

  /// Null = first available account.
  final int? accountId;
  final String from;
  final String to;
  final String search;

  AccountLedgerFilter copyWith({
    int? accountId,
    String? from,
    String? to,
    String? search,
  }) => AccountLedgerFilter(
    accountId: accountId ?? this.accountId,
    from: from ?? this.from,
    to: to ?? this.to,
    search: search ?? this.search,
  );
}

class AccountLedgerFilterNotifier extends Notifier<AccountLedgerFilter> {
  @override
  AccountLedgerFilter build() {
    ref.watch(activeProfileIdProvider); // reset when the profile switches
    final now = ref.read(ledgerClockProvider)();
    return AccountLedgerFilter(
      from: monthStartKey(now.year, now.month),
      to: monthEndKey(now.year, now.month),
    );
  }

  void selectAccount(int id) => state = state.copyWith(accountId: id);
  void setRange(String from, String to) =>
      state = state.copyWith(from: from, to: to);
  void setSearch(String s) => state = state.copyWith(search: s);
}

final accountLedgerFilterProvider =
    NotifierProvider<AccountLedgerFilterNotifier, AccountLedgerFilter>(
      AccountLedgerFilterNotifier.new,
    );

/// The account actually shown: the selected one if it still exists, else the
/// first account; null when the profile has no accounts.
final effectiveLedgerAccountIdProvider = Provider<int?>((ref) {
  final accounts = ref.watch(ledgerAccountsProvider).asData?.value;
  if (accounts == null || accounts.isEmpty) return null;
  final selected = ref.watch(accountLedgerFilterProvider).accountId;
  if (selected != null && accounts.any((a) => a.id == selected)) {
    return selected;
  }
  return accounts.first.id;
});

final accountLedgerProvider = StreamProvider<AccountLedger?>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final accountId = ref.watch(effectiveLedgerAccountIdProvider);
  final filter = ref.watch(accountLedgerFilterProvider);
  if (profileId == null || accountId == null) return Stream.value(null);
  return ref
      .watch(ledgerRepositoryProvider)
      .watchAccountLedger(
        profileId: profileId,
        accountId: accountId,
        from: filter.from,
        to: filter.to,
        search: filter.search,
      );
});

/// Month shown in the budget ledger (day is always 1).
class BudgetLedgerMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(activeProfileIdProvider);
    final now = ref.read(ledgerClockProvider)();
    return DateTime(now.year, now.month);
  }

  void set(DateTime month) => state = DateTime(month.year, month.month);
}

final budgetLedgerMonthProvider =
    NotifierProvider<BudgetLedgerMonthNotifier, DateTime>(
      BudgetLedgerMonthNotifier.new,
    );

final budgetLedgerProvider = StreamProvider<BudgetLedger?>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final month = ref.watch(budgetLedgerMonthProvider);
  if (profileId == null) return Stream.value(null);
  return ref
      .watch(ledgerRepositoryProvider)
      .watchBudgetLedger(
        profileId: profileId,
        year: month.year,
        month: month.month,
      );
});
