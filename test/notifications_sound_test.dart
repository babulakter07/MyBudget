import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_providers.dart';
import 'package:my_budget/features/notifications/data/ringtone_picker.dart';
import 'package:my_budget/features/notifications/domain/notification_sound.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('channel suffix: default none, silent fixed, custom per uri', () {
    expect(NotificationSound.systemDefault.channelSuffix, '');
    expect(NotificationSound.silent.channelSuffix, '_silent');
    const a = NotificationSound(uri: 'content://media/internal/audio/1');
    const b = NotificationSound(uri: 'content://media/internal/audio/2');
    expect(a.channelSuffix, isNot(b.channelSuffix));
    expect(a.channelSuffix, a.channelSuffix);
  });

  test(
    'choosing a sound persists it per channel; cancel changes nothing',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.memory();
      final picker = FakeRingtonePicker(
        const NotificationSound(uri: 'content://x/9', title: 'Chime'),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          ringtonePickerProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final n = container.read(notificationSoundsProvider.notifier);
      await n.choose(budget: false);
      expect(
        container.read(notificationSoundsProvider).reminders.title,
        'Chime',
      );
      expect(
        container.read(notificationSoundsProvider).budget.isDefault,
        isTrue,
      );
      expect(NotificationSounds.load(prefs).reminders.uri, 'content://x/9');

      picker.result = null; // user cancelled
      await n.choose(budget: false);
      expect(
        container.read(notificationSoundsProvider).reminders.title,
        'Chime',
      );

      picker.result = NotificationSound.silent;
      await n.choose(budget: true);
      expect(NotificationSounds.load(prefs).budget.isSilent, isTrue);
    },
  );
}
