import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Kênh thông báo Android; người dùng tắt được từng kênh trong cài đặt của điện thoại.
enum NotificationChannel {
  timer('timer', 'Hẹn giờ nấu', 'Báo khi đồng hồ nấu hết giờ'),
  meal('meal', 'Nhắc bữa', 'Nhắc trước bữa đã lên trong thực đơn');

  const NotificationChannel(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

/// Lớp mỏng trên plugin thông báo của hệ điều hành, để test thay bằng bản giả.
abstract interface class NotificationPlugin {
  /// Hiện thông báo ngay.
  Future<void> show({
    required int id,
    required NotificationChannel channel,
    required String title,
    required String body,
  });

  /// Hẹn thông báo lúc [at]. Trùng [id] thì thay lịch cũ.
  ///
  /// Chỉ đúng giờ khi máy cho báo thức chính xác (Android 12–13 mặc định có; Android 14+ phải bật
  /// "Báo thức và lời nhắc" cho app). Không thì Android có thể dời tới 1 tiếng sau [at].
  Future<void> schedule({
    required int id,
    required NotificationChannel channel,
    required DateTime at,
    required String title,
    required String body,
  });

  /// Id các thông báo đang hẹn, chưa hiện.
  Future<List<int>> pendingIds();

  Future<void> cancel(int id);

  /// Người dùng có cho phép app gửi thông báo không (Android 13+ phải xin; máy cũ luôn có).
  Future<bool> isPermitted();

  /// Hiện hộp thoại xin quyền của hệ thống; trả về đã được cho phép hay chưa.
  Future<bool> requestPermission();
}

/// Không gửi gì, coi như đã có quyền; dùng mặc định cho test. `main.dart` override bằng
/// [LocalNotificationPlugin].
class NoopNotificationPlugin implements NotificationPlugin {
  const NoopNotificationPlugin();

  @override
  Future<void> show({
    required int id,
    required NotificationChannel channel,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> schedule({
    required int id,
    required NotificationChannel channel,
    required DateTime at,
    required String title,
    required String body,
  }) async {}

  @override
  Future<List<int>> pendingIds() async => const [];

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool> isPermitted() async => true;

  @override
  Future<bool> requestPermission() async => true;
}

/// Bản thật dùng `flutter_local_notifications`, chỉ Android. Khởi tạo ở lần gọi đầu.
class LocalNotificationPlugin implements NotificationPlugin {
  LocalNotificationPlugin();

  final _plugin = FlutterLocalNotificationsPlugin();

  late final Future<void> _ready = _plugin.initialize(
    // `drawable/ic_notification.xml`: logo monochrome.
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    ),
  );

  Future<AndroidFlutterLocalNotificationsPlugin?> get _android async {
    await _ready;
    return _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  }

  static NotificationDetails _details(NotificationChannel channel) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.title,
      channelDescription: channel.description,
      importance: channel == NotificationChannel.timer
          ? Importance.high
          : Importance.defaultImportance,
      priority: channel == NotificationChannel.timer ? Priority.high : Priority.defaultPriority,
      category: channel == NotificationChannel.timer
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
    ),
  );

  @override
  Future<void> show({
    required int id,
    required NotificationChannel channel,
    required String title,
    required String body,
  }) async {
    await _ready;
    await _plugin.show(id: id, title: title, body: body, notificationDetails: _details(channel));
  }

  @override
  Future<void> schedule({
    required int id,
    required NotificationChannel channel,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    final android = await _android;
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // Hẹn một lần theo mốc thời gian tuyệt đối nên dùng UTC, khỏi cần dữ liệu múi giờ.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details(channel),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<List<int>> pendingIds() async {
    await _ready;
    return [for (final request in await _plugin.pendingNotificationRequests()) request.id];
  }

  @override
  Future<void> cancel(int id) async {
    await _ready;
    await _plugin.cancel(id: id);
  }

  @override
  Future<bool> isPermitted() async => await (await _android)?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await (await _android)?.requestNotificationsPermission() ?? false;
}

final notificationPluginProvider = Provider<NotificationPlugin>(
  (ref) => const NoopNotificationPlugin(),
);
