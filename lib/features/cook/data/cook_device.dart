import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Giữ màn hình luôn sáng khi đang nấu; test thay bằng bản giả.
abstract interface class ScreenWakelock {
  Future<void> enable();
  Future<void> disable();
}

/// Bản thật dùng `wakelock_plus`. Lỗi của plugin thì bỏ qua: màn tắt sớm còn hơn không nấu được.
class PluginScreenWakelock implements ScreenWakelock {
  const PluginScreenWakelock();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } on Object {
      // Bỏ qua, xem doc của class.
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } on Object {
      // Bỏ qua, xem doc của class.
    }
  }
}

final wakelockProvider = Provider<ScreenWakelock>((ref) => const PluginScreenWakelock());

/// Bật màn hình luôn sáng chừng nào còn người `watch`, hết người watch thì tắt.
///
/// ViewModel của màn nấu `ref.watch(keepScreenOnProvider)` trong `build`: dựng lại ViewModel
/// không làm màn tắt rồi bật lại.
final keepScreenOnProvider = Provider.autoDispose<void>((ref) {
  final wakelock = ref.watch(wakelockProvider);
  wakelock.enable();
  ref.onDispose(wakelock.disable);
});

/// App đang mở trên màn hình (không ở app khác, không tắt màn).
final appInForegroundProvider = Provider<bool Function()>(
  (ref) =>
      () => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
);
