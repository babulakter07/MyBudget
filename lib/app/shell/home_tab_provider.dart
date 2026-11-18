import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab indexes of the home shell.
abstract final class HomeTab {
  static const home = 0;
  static const budget = 1;
  static const add = 2;
  static const ledger = 3;
  static const reports = 4;
}

/// Selected bottom-nav tab. Lives in a provider so launcher shortcuts and
/// other screens can switch tabs.
class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => HomeTab.home;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(
  HomeTabNotifier.new,
);
