import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class Events implements Analytics {
  final records = <(String, Map<String, Object>?)>[];
  @override
  void track(String event, [Map<String, Object>? params]) => records.add((event, params));
}

void main() {
  test('đổi bữa, đổi món và chê lưu qua Pantry trước khi phát event', () async {
    final events = Events();
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(events),
        recipesProvider.overrideWith((ref) async => const <Recipe>[]),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(todayViewModelProvider, (_, _) {});
    final vm = container.read(todayViewModelProvider.notifier);
    vm.setMeal(Meal.dinner);
    vm.setMinutes(15);
    vm.suggested();
    expect(events.records.single.$1, 'today_suggest');
    expect(events.records.single.$2, {'meal': 'dinner'});
    vm.next();
    expect(subscription.read().index, 1);
    vm.toggleReasons();
    expect(subscription.read().showReasons, isTrue);
    await vm.dislike('dish', DislikeReason.justAte);
    expect(container.read(dislikedProvider)['dish']?.reason, DislikeReason.justAte);
    expect(events.records.last.$1, 'today_dislike');
    expect(events.records.last.$2, {'reason': 'justAte'});
    expect(subscription.read().showReasons, isFalse);
  });

  test('chê món đang hiện thì món kế tiếp là món thứ hai, không nhảy qua', () async {
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(Events()),
        // Món bị chê rời danh sách như `suggest()` thật.
        suggestionsProvider.overrideWith((ref, args) async {
          final disliked = ref.watch(dislikedProvider);
          return [
            for (final id in ['a', 'b', 'c'])
              if (!disliked.containsKey(id)) recipe(id),
          ];
        }),
      ],
    );
    addTearDown(container.dispose);
    final state = container.listen(todayViewModelProvider, (_, _) {});
    final recipes = container.listen(todayRecipesProvider, (_, _) {});
    final vm = container.read(todayViewModelProvider.notifier);
    vm.setMinutes(null);
    String current() => recipes.read().value![state.read().index % recipes.read().value!.length].id;

    await container.read(todayRecipesProvider.future);
    expect(current(), 'a');
    vm.toggleReasons();
    await vm.dislike('a', DislikeReason.tooLong);
    await container.read(todayRecipesProvider.future);
    expect(current(), 'b');
    expect(state.read().showReasons, isFalse);

    vm.next();
    expect(current(), 'c');
    vm.setMeal(Meal.lunch);
    expect(state.read().index, 0);
  });
}

Recipe recipe(String id) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);
