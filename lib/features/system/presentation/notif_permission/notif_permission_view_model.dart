import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/features/system/data/notification_permission.dart';

/// State của màn xin quyền: đang chờ hộp thoại hệ thống hay không (khoá nút).
class NotifPermissionState {
  const NotifPermissionState({this.busy = false});

  final bool busy;
}

class NotifPermissionViewModel extends Notifier<NotifPermissionState> {
  @override
  NotifPermissionState build() => const NotifPermissionState();

  /// "Cho phép": hiện hộp thoại xin quyền của hệ thống. Trả về đã được cho phép hay chưa.
  Future<bool> allow() async {
    state = const NotifPermissionState(busy: true);
    try {
      return await ref.read(notificationPermissionProvider).request();
    } finally {
      if (ref.mounted) state = const NotifPermissionState();
    }
  }

  /// "Để sau": không hỏi lại trong [NotificationPermission.askAgainAfter].
  Future<void> later() => ref.read(notificationPermissionProvider).postpone();
}

final notifPermissionViewModelProvider =
    NotifierProvider.autoDispose<NotifPermissionViewModel, NotifPermissionState>(
      NotifPermissionViewModel.new,
    );
