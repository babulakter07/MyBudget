import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/attachments/domain/attachment.dart';
import 'package:my_budget/features/attachments/presentation/attachments_section.dart';

import 'l10n_test_helpers.dart';

/// The framework reports a locale-support warning for the Material delegates under
/// `bn` in tests (shared helper issue); anything else is a real error.
void expectNoRealException(WidgetTester tester) {
  final e = tester.takeException();
  expect(
    e == null || '$e'.contains('not supported by all of its localization'),
    isTrue,
    reason: '$e',
  );
}

void main() {
  testWidgets('attachments section and add sheet render in Bangla', (
    tester,
  ) async {
    final pending = PendingAttachments();
    addTearDown(pending.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          home: Scaffold(body: AttachmentsSection(pending: pending)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('সংযুক্তি (0/5)'), findsOneWidget);
    expect(find.text('ছবি যোগ করুন'), findsOneWidget);
    expect(find.text('কোনো সংযুক্তি নেই'), findsOneWidget);
    await tester.tap(find.text('ছবি যোগ করুন'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ক্যামেরা'), findsOneWidget);
    expect(find.text('গ্যালারি'), findsOneWidget);
    expectNoRealException(tester);
  });

  testWidgets('attachments section still shows English by default', (
    tester,
  ) async {
    final pending = PendingAttachments();
    addTearDown(pending.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AttachmentsSection(pending: pending)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Attachments (0/5)'), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
  });
}
