import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/domain/saved.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import '../../core/fake_analytics.dart';

Recipe _recipe(String id, {int missing = 1, String? name}) => Recipe(
  id: id,
  name: name ?? id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [
    const RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
    for (var i = 1; i < missing; i++) RecipeIngredient(id: 'x$i', amount: 1, unit: 'g'),
  ],
  steps: const [],
);

/// Chủ nhật 2/11/2026, 12:00.
final _now = DateTime(2026, 11, 2, 12);

void main() {
  late ProviderContainer container;
  late FakeAnalytics analytics;
  late DateTime clock;

  ProviderContainer make({InMemoryLocalStore? store}) {
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => store ?? InMemoryLocalStore()),
        analyticsProvider.overrideWithValue(analytics),
        savedClockProvider.overrideWithValue(() => clock),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
          ],
        ),
        recipesProvider.overrideWith(
          (ref) async => [
            _recipe('a', name: 'Món A'),
            _recipe('b', name: 'Món B'),
            _recipe('c', name: 'Món C'),
            _recipe('many', missing: 3, name: 'Thiếu nhiều'),
          ],
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    analytics = FakeAnalytics();
    clock = _now;
    container = make();
  });

  Future<SavedState> load([String? highlight]) async {
    container.listen(savedViewModelProvider(highlight), (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return container.read(savedViewModelProvider(highlight)).requireValue;
  }

  SavedState state([String? highlight]) =>
      container.read(savedViewModelProvider(highlight)).requireValue;
  SavedViewModel vm([String? highlight]) =>
      container.read(savedViewModelProvider(highlight).notifier);

  Future<void> saveRecipe(String id, DateTime at) {
    clock = at;
    return container.read(savedIdsProvider.notifier).save(id);
  }

  Future<void> saveMeal(List<String> ids, DateTime at, {List<RecipeTag> tags = const []}) {
    clock = at;
    return container
        .read(savedMealsProvider.notifier)
        .saveMeal(SavedMeal(recipeIds: ids, servings: 2, tags: tags));
  }

  String label(SavedEntry e) => switch (e) {
    SavedRecipeEntry(:final recipe) => recipe.id,
    SavedMealEntry(:final meal) => 'meal:${meal.key}',
  };

  test('chưa lưu gì thì rỗng', () async {
    final s = await load();
    expect(s.entries, isEmpty);
    expect(s.groups(_now), isEmpty);
  });

  test('gộp món và bữa, mới lưu trước, nhóm theo thời gian', () async {
    await load();
    await saveRecipe('a', _now.subtract(const Duration(days: 10)));
    await saveMeal(['b', 'c'], _now.subtract(const Duration(days: 1)));
    await saveRecipe('c', _now.subtract(const Duration(hours: 1)));
    await saveMeal(['a'], _now.subtract(const Duration(days: 3)));

    expect(state().entries.map(label), ['c', 'meal:b,c', 'meal:a', 'a']);
    final groups = state().groups(_now);
    expect(
      [for (final (g, _) in groups) g],
      [
        SavedGroup.today,
        SavedGroup.yesterday,
        SavedGroup.thisWeek,
        SavedGroup.earlier,
      ],
    );
    expect(groups[1].$2.single, isA<SavedMealEntry>());
  });

  test('món lưu từ bản cũ (không có giờ) nằm cuối, ở Trước đó', () async {
    final store = InMemoryLocalStore();
    await store.writeList('discover.saved', ['b', 'a']);
    container = make(store: store);
    await load();
    await saveRecipe('c', _now);

    expect(state().entries.map(label), ['c', 'a', 'b']);
    expect(state().groups(_now).last.$1, SavedGroup.earlier);
  });

  test('bỏ id không còn trong dữ liệu', () async {
    await load();
    await saveRecipe('gone', _now);
    await saveRecipe('b', _now);
    expect(state().entries.map(label), ['b']);
  });

  test('món kèm độ sẵn đồ, đổi theo Tủ đồ; thiếu quá 2 thứ thì ẩn', () async {
    await load();
    await saveRecipe('a', _now);
    await saveRecipe('many', _now.subtract(const Duration(minutes: 1)));
    final a = state().entries.first as SavedRecipeEntry;
    expect(a.availability!.missing, ['trứng']);
    expect((state().entries.last as SavedRecipeEntry).availability, isNull);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    expect((state().entries.first as SavedRecipeEntry).availability!.isReady, isTrue);
  });

  test('tìm khớp tên món, tên món trong bữa và tag, bỏ dấu', () async {
    await load();
    await saveRecipe('a', _now);
    await saveMeal(['b', 'c'], _now);
    await saveMeal(['a', 'b'], _now, tags: [RecipeTag.cheap]);

    vm().setQuery('mon c');
    expect(state().visible.map(label), ['meal:b,c']);

    vm().setQuery(RecipeTag.cheap.label.toUpperCase());
    expect(state().visible.map(label), ['meal:a,b']);

    vm().setQuery('xyz');
    expect(state().groups(_now), isEmpty);
    expect(state().entries, hasLength(3));
  });

  test('highlight chỉ đánh dấu bữa có khoá trùng', () async {
    await load('a');
    await saveRecipe('a', _now);
    await saveMeal(['a'], _now);
    final s = state('a');
    expect(
      [
        for (final e in s.entries)
          if (s.isHighlight(e)) label(e),
      ],
      ['meal:a'],
    );
  });

  test('bỏ lưu món rồi Hoàn tác: về chỗ cũ, giữ giờ lưu, ghi analytics', () async {
    await load();
    final old = _now.subtract(const Duration(days: 2));
    await saveRecipe('a', old);
    await saveRecipe('b', _now);

    final outcome = await vm().unsave(state().entries.last);
    expect(outcome.name, 'Món A');
    expect(state().entries.map(label), ['b']);
    expect(container.read(savedAtProvider).containsKey('a'), isFalse);
    expect(analytics.params.last, {'kind': 'recipe', 'undo': false});

    clock = _now.add(const Duration(hours: 1));
    await outcome.undo();
    expect(state().entries.map(label), ['b', 'a']);
    expect(container.read(savedAtProvider)['a'], old);
    expect(analytics.params.last, {'kind': 'recipe', 'undo': true});
  });

  test('bỏ lưu bữa rồi Hoàn tác, ghi analytics', () async {
    await load();
    await saveMeal(['a', 'b'], _now);

    final outcome = await vm().unsave(state().entries.single);
    expect(outcome.name, 'Món A + Món B');
    expect(state().entries, isEmpty);
    expect(analytics.params.last, {'kind': 'meal', 'undo': false});

    await outcome.undo();
    expect(state().entries.map(label), ['meal:a,b']);
    expect(container.read(savedMealsProvider).single.savedAt, _now);
    expect(analytics.params.last, {'kind': 'meal', 'undo': true});
  });

  test('dữ liệu lỗi thì state lỗi', () async {
    final failing = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        recipesProvider.overrideWith(
          (ref) => Future<List<Recipe>>.error(const FormatException('hỏng')),
        ),
      ],
    );
    addTearDown(failing.dispose);
    final sub = failing.listen(savedViewModelProvider(null), (_, _) {});
    await expectLater(failing.read(recipesProvider.future), throwsFormatException);
    expect(sub.read().hasError, isTrue);
  });
}
