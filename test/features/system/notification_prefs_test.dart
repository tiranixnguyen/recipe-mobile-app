import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    );
  });

  tearDown(() => container.dispose());

  test('mặc định bật nhắc hẹn giờ, tắt nhắc bữa', () {
    expect(container.read(notificationPrefsProvider), const NotificationPrefs());
    expect(container.read(notificationPrefsProvider).timerDone, isTrue);
    expect(container.read(notificationPrefsProvider).mealReminder, isFalse);
  });

  test('đổi thì lưu lại, dựng lại vẫn giữ', () async {
    final controller = container.read(notificationPrefsProvider.notifier);
    await controller.setTimerDone(false);
    await controller.setMealReminder(true);

    container.invalidate(notificationPrefsProvider);
    expect(
      container.read(notificationPrefsProvider),
      const NotificationPrefs(timerDone: false, mealReminder: true),
    );
  });

  test('xoá dữ liệu đưa về mặc định', () async {
    await container.read(notificationPrefsProvider.notifier).setTimerDone(false);

    await container.read(clearLocalDataProvider)();

    expect(container.read(notificationPrefsProvider), const NotificationPrefs());
  });
}
