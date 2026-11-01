import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/getting_started.dart';
import 'package:recipe_mobile_app/features/system/presentation/getting_started/getting_started_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import '../../core/fake_analytics.dart';

void main() {
  final today = DateTime(2026, 11, 1);
  late FakeAnalytics analytics;
  late ProviderContainer container;

  setUp(() async {
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        analyticsProvider.overrideWithValue(analytics),
        startClockProvider.overrideWithValue(() => today),
      ],
    );
    await container.read(onboardingDoneProvider.notifier).complete();
    container.listen(gettingStartedViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  GettingStartedCardState state() => container.read(gettingStartedViewModelProvider);
  StartRow row(StartStep step) => state().rows.firstWhere((r) => r.step == step);

  test('mới vào: 4 dòng, 0 xong, chỉ dòng pantry được làm nổi', () {
    expect(state().visible, isTrue);
    expect(state().rows.map((r) => r.step), StartStep.values);
    expect(state().doneCount, 0);
    expect([for (final r in state().rows) r.next], [true, false, false, false]);
    expect(row(StartStep.pantry).target, const StartTarget(pantryLocation, tab: true));
    expect(row(StartStep.plan).target, StartTarget(planLocation(date: today), tab: true));
  });

  test('chưa qua Onboarding thì thẻ không hiện', () async {
    final fresh = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(InMemoryLocalStore())],
    );
    addTearDown(fresh.dispose);
    expect(fresh.read(gettingStartedViewModelProvider).visible, isFalse);
  });

  test('dòng đã xong mất nút, bước kế nhảy sang bước chưa xong đầu tiên', () async {
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');

    expect(row(StartStep.pantry).done, isTrue);
    expect(row(StartStep.pantry).target, isNull);
    expect(row(StartStep.shopping).next, isTrue);
    expect(state().doneCount, 1);
  });

  test('bước cook: không có bữa hôm nay thì vào Hôm nay ăn gì', () {
    expect(row(StartStep.cook).target, const StartTarget(todayLocation));
  });

  test('bước cook: có bữa hôm nay chưa nấu thì vào bữa đó (bữa sớm nhất)', () async {
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', today, Meal.dinner);
    await plan.addToPlan('trung', today, Meal.lunch);

    expect(
      row(StartStep.cook).target,
      StartTarget(planLocation(date: today, meal: Meal.lunch), tab: true),
    );
  });

  test('bước cook: bữa hôm nay đã nấu rồi thì không dẫn vào bữa đó', () async {
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', today, Meal.lunch);
    await plan.markCooked(today, Meal.lunch, ['trung']);

    expect(row(StartStep.cook).target, const StartTarget(todayLocation));
  });

  test('bước cook: nấu xong chưa chấm thì dẫn tới Chi tiết lần nấu gần nhất', () async {
    final history = container.read(cookHistoryProvider.notifier);
    await history.record('trung');
    await history.record('bun');
    final latest = container.read(cookHistoryProvider).last.id;

    expect(row(StartStep.cook).target, StartTarget(historyEntryLocation(latest)));
    expect(row(StartStep.cook).done, isFalse);
  });

  test('xong cả bốn bước thì allDone, Đóng ẩn thẻ và ghi start_hide', () async {
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await container.read(shoppingItemsProvider.notifier).addIngredient('hanh');
    await container.read(plannedMealsProvider.notifier).addToPlan('trung', today, Meal.dinner);
    await container.read(cookHistoryProvider.notifier).record('trung', rating: CookRating.good);
    expect(state().allDone, isTrue);
    analytics.events.clear();
    analytics.params.clear();

    await container.read(gettingStartedViewModelProvider.notifier).hide();

    expect(state().visible, isFalse);
    expect(analytics.events, ['start_hide']);
    expect(analytics.params.single, {'done': 4});
  });

  test('open() ghi start_step_open với tên bước', () {
    container.read(gettingStartedViewModelProvider.notifier).open(StartStep.plan);

    expect(analytics.events, ['start_step_open']);
    expect(analytics.params.single, {'step': 'plan'});
  });
}
