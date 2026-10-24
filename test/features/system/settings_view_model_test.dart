import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<SettingsState> sub;
  late int storeOpened;

  setUp(() {
    storeOpened = 0;
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        appVersionProvider.overrideWith((ref) async => '1.2.3'),
        openStoreListingProvider.overrideWithValue(() async => storeOpened++),
      ],
    );
    sub = container.listen(settingsViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  SettingsViewModel viewModel() => container.read(settingsViewModelProvider.notifier);

  test('state ban đầu: theo hệ thống, nhắc hẹn giờ bật, nhắc bữa tắt, có phiên bản', () async {
    await container.read(appVersionProvider.future);

    final state = sub.read();
    expect(state.themeMode, ThemeMode.system);
    expect(state.timerDone, isTrue);
    expect(state.mealReminder, isFalse);
    expect(state.version, '1.2.3');
  });

  test('đổi giao diện thì themeModeProvider đổi ngay', () async {
    await viewModel().setThemeMode(ThemeMode.dark);

    expect(sub.read().themeMode, ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('bật/tắt thông báo cập nhật state', () async {
    await viewModel().setTimerDone(false);
    await viewModel().setMealReminder(true);

    expect(sub.read().timerDone, isFalse);
    expect(sub.read().mealReminder, isTrue);
  });

  test('đánh giá app mở trang Google Play', () async {
    await viewModel().rateApp();
    expect(storeOpened, 1);
  });
}
