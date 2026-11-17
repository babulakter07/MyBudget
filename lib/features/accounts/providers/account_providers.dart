import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/account_repository.dart';
import '../domain/account.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(appDatabaseProvider)),
);

class AccountFilter {
  const AccountFilter({this.search = '', this.includeInactive = false});
  final String search;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is AccountFilter &&
      other.search == search &&
      other.includeInactive == includeInactive;
  @override
  int get hashCode => Object.hash(search, includeInactive);
}

class AccountFilterNotifier extends Notifier<AccountFilter> {
  @override
  AccountFilter build() => const AccountFilter();
  void setSearch(String s) =>
      state = AccountFilter(search: s, includeInactive: state.includeInactive);
  void setIncludeInactive(bool v) =>
      state = AccountFilter(search: state.search, includeInactive: v);
}

final accountFilterProvider =
    NotifierProvider<AccountFilterNotifier, AccountFilter>(
      AccountFilterNotifier.new,
    );

/// Accounts of the active profile (no balances).
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final filter = ref.watch(accountFilterProvider);
  if (profileId == null) return Stream.value(const <Account>[]);
  return ref
      .watch(accountRepositoryProvider)
      .watchAll(
        profileId,
        search: filter.search,
        includeInactive: filter.includeInactive,
      );
});

/// Accounts with live computed balances (reacts to transaction changes).
final accountBalancesProvider = StreamProvider<List<AccountBalance>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final filter = ref.watch(accountFilterProvider);
  if (profileId == null) return Stream.value(const <AccountBalance>[]);
  return ref
      .watch(accountRepositoryProvider)
      .watchBalances(
        profileId,
        search: filter.search,
        includeInactive: filter.includeInactive,
      );
});
