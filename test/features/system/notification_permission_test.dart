import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/data/notification_permission.dart';
import 'package:recipe_mobile_app/features/system/presentation/notif_permission/notif_permission_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fake_notification_plugin.dart';

void main() {
  late FakeNotificationPlugin plugin;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    plugin = FakeNotificationPlugin(permitted: false);
    now = DateTime(2026, 10, 26, 10);
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        notificationPluginProvider.overrideWithValue(plugin),
        systemClockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<bool> shouldAsk() => container.read(shouldAskNotificationPermissionProvider)();
  NotifPermissionViewModel viewModel() => container.read(notifPermissionViewModelProvider.notifier);

  test('đã có quyền (Android < 13 hoặc đã cho phép) thì không hỏi', () async {
    plugin.permitted = true;
    expect(await shouldAsk(), isFalse);
  });

  test('chưa có quyền, chưa hỏi lần nào thì hỏi', () async {
    expect(await shouldAsk(), isTrue);
  });

  test('"Để sau" thì 7 ngày sau mới hỏi lại', () async {
    container.listen(notifPermissionViewModelProvider, (_, _) {});
    await viewModel().later();

    now = now.add(const Duration(days: 6, hours: 23));
    expect(await shouldAsk(), isFalse);

    now = now.add(const Duration(hours: 1));
    expect(await shouldAsk(), isTrue);
  });

  test('"Cho phép": xin quyền hệ thống, trả về kết quả', () async {
    final sub = container.listen(notifPermissionViewModelProvider, (_, _) {});

    final granted = viewModel().allow();
    expect(sub.read().busy, isTrue);
    expect(await granted, isTrue);
    expect(sub.read().busy, isFalse);
    expect(plugin.permissionRequests, 1);
    expect(await shouldAsk(), isFalse);
  });

  test('"Cho phép" mà người dùng từ chối: không hỏi lại ngay', () async {
    plugin.grantOnRequest = false;
    container.listen(notifPermissionViewModelProvider, (_, _) {});

    expect(await viewModel().allow(), isFalse);
    expect(await shouldAsk(), isFalse);
  });
}
