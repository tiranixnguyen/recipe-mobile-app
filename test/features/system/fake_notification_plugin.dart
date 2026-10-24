import 'package:recipe_mobile_app/features/system/data/notification_plugin.dart';

/// Ghi lại thông báo đã gửi / đã hẹn; quyền đặt được bằng [permitted] và [grantOnRequest].
class FakeNotificationPlugin implements NotificationPlugin {
  FakeNotificationPlugin({this.permitted = true, this.grantOnRequest = true});

  bool permitted;
  bool grantOnRequest;
  int permissionRequests = 0;

  final shown = <({int id, NotificationChannel channel, String title, String body})>[];

  /// Đang hẹn, theo id.
  final scheduled =
      <int, ({NotificationChannel channel, DateTime at, String title, String body})>{};

  @override
  Future<void> show({
    required int id,
    required NotificationChannel channel,
    required String title,
    required String body,
  }) async => shown.add((id: id, channel: channel, title: title, body: body));

  @override
  Future<void> schedule({
    required int id,
    required NotificationChannel channel,
    required DateTime at,
    required String title,
    required String body,
  }) async => scheduled[id] = (channel: channel, at: at, title: title, body: body);

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permitted = grantOnRequest;
  }
}
