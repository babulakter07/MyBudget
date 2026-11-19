import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/credit_card_repository.dart';
import '../domain/credit_card.dart';

final creditCardRepositoryProvider = Provider<CreditCardRepository>(
  (ref) => CreditCardRepository(ref.watch(appDatabaseProvider)),
);

/// Toggle on the list screen: also show inactive cards.
class ShowInactiveCardsNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final showInactiveCardsProvider =
    NotifierProvider<ShowInactiveCardsNotifier, bool>(
      ShowInactiveCardsNotifier.new,
    );

final creditCardSummariesProvider = StreamProvider<List<CardSummary>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final inactive = ref.watch(showInactiveCardsProvider);
  if (profileId == null) return Stream.value(const <CardSummary>[]);
  return ref
      .watch(creditCardRepositoryProvider)
      .watchCards(profileId, includeInactive: inactive);
});

final creditCardProvider = StreamProvider.family<CardSummary?, int>((
  ref,
  cardId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref.watch(creditCardRepositoryProvider).watchCard(profileId, cardId);
});

final cardBillsProvider = StreamProvider.family<List<BillStatement>, int>((
  ref,
  cardId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <BillStatement>[]);
  return ref.watch(creditCardRepositoryProvider).watchBills(profileId, cardId);
});

final cardBillProvider = StreamProvider.family<BillStatement?, int>((
  ref,
  billId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref.watch(creditCardRepositoryProvider).watchBill(profileId, billId);
});

final billProjectionProvider = StreamProvider.family<BillProjection?, int>((
  ref,
  billId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref
      .watch(creditCardRepositoryProvider)
      .watchProjection(profileId, billId);
});

final cardPaymentsProvider = StreamProvider.family<List<CardPayment>, int>((
  ref,
  billId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <CardPayment>[]);
  return ref
      .watch(creditCardRepositoryProvider)
      .watchPayments(profileId, billId);
});

final overallCardSummaryProvider = StreamProvider<OverallCardSummary>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(OverallCardSummary.empty);
  return ref.watch(creditCardRepositoryProvider).watchOverallSummary(profileId);
});
