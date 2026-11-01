import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/getting_started.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import '../../core/fake_analytics.dart';

void main() {
  late InMemoryLocalStore store;
  late FakeAnalytics analytics;
  late ProviderContainer container;

  setUp(() {
    store = InMemoryLocalStore();
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() => container.dispose());

  Set<StartStep> done() => container.read(gettingStartedProvider).done;

  test('thêm đồ vào tủ thì tick pantry và lưu xuống store', () async {
    container.listen(gettingStartedProvider, (_, _) {});
    expect(done(), isEmpty);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');

    expect(done(), {StartStep.pantry});
    expect(store.readList('system.startDone'), ['pantry']);
    expect(analytics.events, ['start_step_done']);
    expect(analytics.params.single, {'step': 'pantry'});
  });

  test('bỏ hết đồ trong tủ thì pantry vẫn tick', () async {
    container.listen(gettingStartedProvider, (_, _) {});
    final pantry = container.read(pantryItemsProvider.notifier);
    await pantry.addToPantry('egg');
    expect(done(), {StartStep.pantry});

    await pantry.removeFromPantry('egg');

    expect(container.read(pantryItemsProvider), isEmpty);
    expect(done(), {StartStep.pantry});
  });

  test('bước đã tick còn nguyên sau khi mở lại app', () async {
    container.listen(gettingStartedProvider, (_, _) {});
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    expect(done(), {StartStep.pantry});
    await container.read(pantryItemsProvider.notifier).removeFromPantry('egg');

    final reopened = ProviderContainer(overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(reopened.dispose);

    expect(reopened.read(gettingStartedProvider).done, {StartStep.pantry});
  });

  test('cook chỉ xong khi có món được chấm', () async {
    container.listen(gettingStartedProvider, (_, _) {});
    final history = container.read(cookHistoryProvider.notifier);

    await history.record('trung');
    expect(done(), isNot(contains(StartStep.cook)));
    expect(container.read(latestUnratedCookProvider), container.read(cookHistoryProvider).last.id);

    final id = container.read(cookHistoryProvider).last.id;
    await history.updateDishRating(id, 0, CookRating.good);
    expect(done(), contains(StartStep.cook));
    expect(container.read(latestUnratedCookProvider), isNull);
  });

  test('lên thực đơn thì tick plan', () async {
    container.listen(gettingStartedProvider, (_, _) {});
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('trung', DateTime.now(), Meal.dinner);
    expect(done(), {StartStep.plan});
  });

  test('người dùng cũ đủ cả bốn bước lần đầu thì tự ẩn và không bắn start_step_done', () async {
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await container.read(shoppingItemsProvider.notifier).addIngredient('hanh');
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('trung', DateTime.now(), Meal.dinner);
    await container.read(cookHistoryProvider.notifier).record('trung', rating: CookRating.ok);

    final state = container.read(gettingStartedProvider);

    expect(state.allDone, isTrue);
    expect(state.hidden, isTrue);
    expect(store.readString('system.startHidden'), 'true');
    expect(analytics.events, isEmpty);
  });

  test('người dùng mới không bị ẩn', () {
    expect(container.read(gettingStartedProvider).hidden, isFalse);
    expect(store.readString('system.startHidden'), 'false');
  });

  test('hide() xong thì mọi gợi ý đều tắt, kể cả sau khi mở lại app', () async {
    await container.read(onboardingDoneProvider.notifier).complete();
    expect(container.read(startHintProvider(StartHintSpot.pantryAdd)), isTrue);

    await container.read(gettingStartedProvider.notifier).hide();

    for (final spot in StartHintSpot.values) {
      expect(container.read(startHintProvider(spot)), isFalse, reason: '$spot');
    }
    final reopened = ProviderContainer(overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(reopened.dispose);
    expect(reopened.read(gettingStartedProvider).hidden, isTrue);
  });

  test('chưa qua Onboarding thì không hiện gợi ý nào', () {
    for (final spot in StartHintSpot.values) {
      expect(container.read(startHintProvider(spot)), isFalse, reason: '$spot');
    }
  });
}
