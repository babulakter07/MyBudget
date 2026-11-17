import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_models.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(appDatabaseProvider)),
);

final recentTransactionsProvider =
    StreamProvider.family<List<TransactionView>, int>((ref, limit) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return Stream.value(const <TransactionView>[]);
      return ref
          .watch(transactionRepositoryProvider)
          .watchRecent(pid, limit: limit);
    });

final transactionsProvider =
    StreamProvider.family<List<TransactionView>, TransactionFilter>((
      ref,
      filter,
    ) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return Stream.value(const <TransactionView>[]);
      return ref
          .watch(transactionRepositoryProvider)
          .watchByFilter(pid, filter);
    });

final transactionProvider = StreamProvider.family<TransactionView?, int>((
  ref,
  id,
) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(null);
  return ref.watch(transactionRepositoryProvider).watchById(pid, id);
});

final transactionAuditProvider =
    StreamProvider.family<List<TransactionAuditEntry>, int>((ref, id) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return Stream.value(const <TransactionAuditEntry>[]);
      return ref.watch(transactionRepositoryProvider).watchAuditLog(pid, id);
    });

/// Active accounts of the active profile (for the transaction forms).
final txnActiveAccountsProvider = StreamProvider<List<AccountRow>>((ref) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const <AccountRow>[]);
  return ref.watch(transactionRepositoryProvider).watchActiveAccounts(pid);
});

final txnActiveCategoriesProvider = StreamProvider<List<CategoryRow>>((ref) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const <CategoryRow>[]);
  return ref.watch(transactionRepositoryProvider).watchActiveCategories(pid);
});

final txnActiveSubCategoriesProvider =
    FutureProvider.family<List<SubCategoryRow>, int>((ref, categoryId) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return const <SubCategoryRow>[];
      return ref
          .watch(transactionRepositoryProvider)
          .activeSubCategories(pid, categoryId);
    });

final txnActiveCostItemsProvider =
    FutureProvider.family<List<CostItemRow>, int>((ref, subCategoryId) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return const <CostItemRow>[];
      return ref
          .watch(transactionRepositoryProvider)
          .activeCostItems(pid, subCategoryId);
    });
