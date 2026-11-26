import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/upcoming_repository.dart';
import '../domain/upcoming_payment.dart';

/// Injectable clock (tests override).
final upcomingClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final upcomingRepositoryProvider = Provider<UpcomingRepository>(
  (ref) => UpcomingRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(upcomingClockProvider),
  ),
);

/// Overdue and next-30-days payments of the active profile. Invalidate when
/// the date may have changed.
final upcomingPaymentsProvider = StreamProvider<List<UpcomingPayment>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <UpcomingPayment>[]);
  return ref.watch(upcomingRepositoryProvider).watch(profileId);
});

const upcomingWindowChoices = [7, upcomingMaxDays];
const _kDays = 'upcoming_window_days';

/// How many days ahead the card shows; remembered between launches.
class UpcomingWindowNotifier extends Notifier<int> {
  @override
  int build() {
    final saved = ref.watch(sharedPreferencesProvider).getInt(_kDays);
    return upcomingWindowChoices.contains(saved) ? saved! : 7;
  }

  Future<void> select(int days) async {
    if (!upcomingWindowChoices.contains(days)) return;
    state = days;
    await ref.read(sharedPreferencesProvider).setInt(_kDays, days);
  }
}

final upcomingWindowProvider = NotifierProvider<UpcomingWindowNotifier, int>(
  UpcomingWindowNotifier.new,
);
