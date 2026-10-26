import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/data/notification_plugin.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/data/notification_service.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fake_notification_plugin.dart';

void main() {
  late FakeNotificationPlugin plugin;
  late ProviderContainer container;

  setUp(() {
    plugin = FakeNotificationPlugin();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        notificationPluginProvider.overrideWithValue(plugin),
      ],
    );
  });

  tearDown(() => container.dispose());

  NotificationService service() => container.read(notificationServiceProvider);
  NotificationPrefsController prefs() => container.read(notificationPrefsProvider.notifier);
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  test('mặc định dùng plugin không làm gì, gọi được, không ném', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(notificationServiceProvider);

    await expectLater(service.timerDone(recipeTitle: 'Trứng rán'), completes);
    await expectLater(
      service.mealReminder(meal: Meal.dinner, at: tomorrow, recipeTitle: 'Canh rau'),
      completes,
    );
    await expectLater(service.cancelMealReminders(), completes);
    await expectLater(service.scheduleTimer(key: 0, recipeTitle: 't', at: tomorrow), completes);
    await expectLater(service.cancelTimer(0), completes);
  });

  test('hẹn giờ xong: hiện ngay trên kênh timer', () async {
    await service().timerDone(recipeTitle: 'Trứng rán');

    expect(plugin.shown.single.channel, NotificationChannel.timer);
    expect(plugin.shown.single.title, 'Hết giờ rồi');
    expect(plugin.shown.single.body, contains('Trứng rán'));
  });

  test('tắt nhắc hẹn giờ trong Cài đặt thì không gửi', () async {
    await prefs().setTimerDone(false);
    await service().timerDone(recipeTitle: 'Trứng rán');

    expect(plugin.shown, isEmpty);
  });

  test('hẹn báo hết giờ: mỗi key một id, hẹn lại thay lịch cũ, huỷ theo key', () async {
    final soon = DateTime.now().add(const Duration(minutes: 3));
    await service().scheduleTimer(key: 0, recipeTitle: 'Trứng rán', at: soon);
    await service().scheduleTimer(key: 5, recipeTitle: 'Canh rau', at: soon);
    await service().scheduleTimer(key: 0, recipeTitle: 'Trứng rán', at: tomorrow);

    expect(plugin.scheduled, hasLength(2));
    final first = plugin.scheduled[LocalNotificationService.scheduledTimerId(0)]!;
    expect(
      (first.channel, first.at, first.title),
      (NotificationChannel.timer, tomorrow, 'Hết giờ rồi'),
    );
    expect(first.body, contains('Trứng rán'));

    await service().cancelTimer(0);
    expect(plugin.scheduled.keys, [LocalNotificationService.scheduledTimerId(5)]);
  });

  test('hẹn báo hết giờ: bỏ qua khi tắt trong Cài đặt hoặc giờ đã qua', () async {
    await prefs().setTimerDone(false);
    await service().scheduleTimer(key: 0, recipeTitle: 'Trứng rán', at: tomorrow);
    await prefs().setTimerDone(true);
    await service().scheduleTimer(
      key: 1,
      recipeTitle: 'Trứng rán',
      at: DateTime.now().subtract(const Duration(seconds: 1)),
    );

    expect(plugin.scheduled, isEmpty);
  });

  test('id báo hết giờ nằm giữa id báo ngay và id nhắc bữa; key ngoài khoảng thì lỗi', () {
    final ids = {
      for (var k = 0; k <= maxTimerKey; k++) LocalNotificationService.scheduledTimerId(k),
    };
    expect(ids, hasLength(maxTimerKey + 1));
    final firstMeal = LocalNotificationService.mealReminderId(DateTime(1970), Meal.breakfast);
    expect(ids.every((id) => id > LocalNotificationService.timerId && id < firstMeal), isTrue);
    expect(() => LocalNotificationService.scheduledTimerId(maxTimerKey + 1), throwsRangeError);
  });

  test('nhắc bữa: chỉ hẹn khi đã bật', () async {
    await service().mealReminder(meal: Meal.dinner, at: tomorrow, recipeTitle: 'Canh rau');
    expect(plugin.scheduled, isEmpty);

    await prefs().setMealReminder(true);
    await service().mealReminder(meal: Meal.dinner, at: tomorrow, recipeTitle: 'Canh rau');

    final reminder = plugin.scheduled.values.single;
    expect(reminder.channel, NotificationChannel.meal);
    expect(reminder.at, tomorrow);
    expect(reminder.title, 'Sắp tới bữa tối');
    expect(reminder.body, contains('Canh rau'));
  });

  test('nhắc bữa: bỏ qua giờ đã qua; cùng ngày và bữa thì thay lịch cũ', () async {
    await prefs().setMealReminder(true);
    await service().mealReminder(
      meal: Meal.lunch,
      at: DateTime.now().subtract(const Duration(minutes: 1)),
      recipeTitle: 'Cơm rang',
    );
    expect(plugin.scheduled, isEmpty);

    await service().mealReminder(meal: Meal.lunch, at: tomorrow, recipeTitle: 'Cơm rang');
    await service().mealReminder(
      meal: Meal.lunch,
      at: tomorrow.add(const Duration(minutes: 1)),
      recipeTitle: 'Mì xào',
    );
    expect(plugin.scheduled.values.single.body, contains('Mì xào'));
  });

  test('huỷ nhắc bữa không đụng thông báo khác', () async {
    await prefs().setMealReminder(true);
    await service().mealReminder(meal: Meal.lunch, at: tomorrow, recipeTitle: 'Cơm rang');
    await service().mealReminder(meal: Meal.dinner, at: tomorrow, recipeTitle: 'Canh rau');
    await plugin.schedule(
      id: LocalNotificationService.timerId,
      channel: NotificationChannel.timer,
      at: tomorrow,
      title: 't',
      body: 'b',
    );

    await service().cancelMealReminders();

    expect(plugin.scheduled.keys, [LocalNotificationService.timerId]);
  });

  test('id nhắc bữa khác nhau theo ngày và bữa, vừa int 32 bit', () {
    final ids = {
      for (final day in [DateTime(2026, 10, 26), DateTime(2026, 10, 27), DateTime(2100)])
        for (final meal in Meal.values) LocalNotificationService.mealReminderId(day, meal),
    };
    expect(ids, hasLength(9));
    expect(ids.every((id) => id > LocalNotificationService.timerId && id < 1 << 31), isTrue);
  });
}
