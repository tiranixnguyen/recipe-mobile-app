import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fake_analytics.dart';
import 'fake_notification_plugin.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<SettingsState> sub;
  late int storeOpened;
  late FakeNotificationPlugin plugin;
  late FakeAnalytics analytics;

  setUp(() {
    storeOpened = 0;
    plugin = FakeNotificationPlugin();
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        appVersionProvider.overrideWith((ref) async => '1.2.3'),
        openStoreListingProvider.overrideWithValue(() async => storeOpened++),
        notificationPluginProvider.overrideWithValue(plugin),
        analyticsProvider.overrideWithValue(analytics),
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

  test('đổi giao diện ghi theme_change; chọn lại ô đang chọn thì không', () async {
    await viewModel().setThemeMode(ThemeMode.system);
    await viewModel().setThemeMode(ThemeMode.light);

    expect(analytics.events, ['theme_change']);
    expect(analytics.params.single, {'mode': 'light'});
  });

  test('bật/tắt thông báo cập nhật state', () async {
    await viewModel().setTimerDone(false);
    await viewModel().setMealReminder(true);

    expect(sub.read().timerDone, isFalse);
    expect(sub.read().mealReminder, isTrue);
  });

  test('bật thông báo khi chưa có quyền: xin quyền, được thì bật', () async {
    plugin.permitted = false;

    expect(await viewModel().setMealReminder(true), isTrue);
    expect(plugin.permissionRequests, 1);
    expect(sub.read().mealReminder, isTrue);
  });

  test('bật thông báo mà bị từ chối quyền: để tắt, báo false', () async {
    await viewModel().setTimerDone(false);
    plugin
      ..permitted = false
      ..grantOnRequest = false;

    expect(await viewModel().setTimerDone(true), isFalse);
    expect(await viewModel().setMealReminder(true), isFalse);
    expect(sub.read().timerDone, isFalse);
    expect(sub.read().mealReminder, isFalse);
  });

  test('tắt thông báo không cần xin quyền', () async {
    plugin.permitted = false;

    expect(await viewModel().setTimerDone(false), isTrue);
    expect(plugin.permissionRequests, 0);
  });

  test('đổi giờ nhắc bữa', () async {
    expect(sub.read().mealReminderLead, const Duration(minutes: 30));
    await viewModel().setMealReminderLead(const Duration(minutes: 60));
    expect(sub.read().mealReminderLead, const Duration(minutes: 60));
  });

  test('đánh giá app mở trang Google Play', () async {
    await viewModel().rateApp();
    expect(storeOpened, 1);
  });
}
