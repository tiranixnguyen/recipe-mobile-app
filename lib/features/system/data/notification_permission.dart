import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/data/notification_plugin.dart';

const _askedAtKey = 'system.notif.askedAt';

/// Giờ hiện tại; test override để cố định.
final systemClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Quyền gửi thông báo (Android 13+). Màn xin quyền và Cài đặt dùng.
class NotificationPermission {
  NotificationPermission(this._plugin, this._store, this._now);

  final NotificationPlugin _plugin;
  final LocalStore _store;
  final DateTime Function() _now;

  /// Bấm "Để sau" (hoặc đã hỏi) thì chừng này ngày sau mới hỏi lại.
  static const askAgainAfter = Duration(days: 7);

  Future<bool> isGranted() => _plugin.isPermitted();

  /// Hiện hộp thoại xin quyền của hệ thống; trả về đã được cho phép hay chưa.
  Future<bool> request() async {
    await postpone();
    return _plugin.requestPermission();
  }

  /// Ghi nhận đã hỏi, để [shouldAsk] không hỏi lại ngay.
  Future<void> postpone() => _store.writeString(_askedAtKey, _now().toIso8601String());

  /// Nên mở màn giải thích trước khi xin quyền: chưa có quyền và chưa hỏi trong [askAgainAfter].
  Future<bool> shouldAsk() async {
    if (await isGranted()) return false;
    final askedAt = DateTime.tryParse(_store.readString(_askedAtKey) ?? '');
    return askedAt == null || _now().difference(askedAt) >= askAgainAfter;
  }
}

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => NotificationPermission(
    ref.watch(notificationPluginProvider),
    ref.watch(localStoreProvider),
    ref.watch(systemClockProvider),
  ),
);

/// F2/F4 gọi trước lần hẹn giờ / nhắc bữa đầu:
///
/// ```dart
/// if (await ref.read(shouldAskNotificationPermissionProvider)()) {
///   await context.push(notifPermissionLocation);
/// }
/// ```
final shouldAskNotificationPermissionProvider = Provider<Future<bool> Function()>(
  (ref) => ref.watch(notificationPermissionProvider).shouldAsk,
);
