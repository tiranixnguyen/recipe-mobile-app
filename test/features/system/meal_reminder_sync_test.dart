import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fake_notification_plugin.dart';

const _recipe = Recipe(
  id: 'canh-rau',
  name: 'Canh rau',
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.dinner],
  ingredients: [],
  steps: [],
);

void main() {
  late FakeNotificationPlugin plugin;
  late ProviderContainer container;
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  setUp(() {
    plugin = FakeNotificationPlugin();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        notificationPluginProvider.overrideWithValue(plugin),
        recipesProvider.overrideWith((ref) async => const [_recipe]),
      ],
    );
    container.listen(mealReminderSyncProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> sync() async {
    await container.read(recipesProvider.future);
    await container.read(mealReminderSyncProvider);
  }

  test('bật nhắc bữa thì hẹn cho bữa đã lên, tắt thì huỷ', () async {
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('canh-rau', tomorrow, Meal.dinner);
    await sync();
    expect(plugin.scheduled, isEmpty, reason: 'mặc định tắt nhắc bữa');

    await container.read(notificationPrefsProvider.notifier).setMealReminder(true);
    await sync();
    final reminder = plugin.scheduled.values.single;
    final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    expect(reminder.at, DateTime(day.year, day.month, day.day, 18));
    expect(reminder.body, contains('Canh rau'));

    await container.read(notificationPrefsProvider.notifier).setMealReminder(false);
    await sync();
    expect(plugin.scheduled, isEmpty);
  });

  test('đổi thực đơn hay giờ nhắc thì hẹn lại', () async {
    await container.read(notificationPrefsProvider.notifier).setMealReminder(true);
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('canh-rau', tomorrow, Meal.dinner);
    await sync();

    await container
        .read(notificationPrefsProvider.notifier)
        .setMealReminderLead(const Duration(minutes: 60));
    await sync();
    expect(plugin.scheduled.values.single.at.hour, 17);
    expect(plugin.scheduled.values.single.at.minute, 30);

    await container.read(plannedMealsProvider.notifier).removeFromPlan(tomorrow, Meal.dinner);
    await sync();
    expect(plugin.scheduled, isEmpty);
  });

  test('món không còn trong dữ liệu thì bỏ qua', () async {
    await container.read(notificationPrefsProvider.notifier).setMealReminder(true);
    await container.read(plannedMealsProvider.notifier).addToPlan('mon-cu', tomorrow, Meal.dinner);
    await sync();

    expect(plugin.scheduled, isEmpty);
  });
}
