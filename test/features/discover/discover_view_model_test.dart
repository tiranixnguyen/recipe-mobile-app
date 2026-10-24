import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
];

Recipe _recipe(String id, int minutes, List<String> needs) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [for (final n in needs) RecipeIngredient(id: n, amount: 1, unit: 'g')],
  steps: const [],
);

void main() {
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<DiscoverState>> sub;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith(
          (ref) async => [
            _recipe('slow', 40, ['egg']),
            _recipe('both', 20, ['egg', 'rice']),
            _recipe('rice-only', 15, ['rice']),
            _recipe('quick', 10, ['egg']),
            _recipe('also-20', 20, ['rice']),
          ],
        ),
      ],
    );
    sub = container.listen(discoverViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<DiscoverState> loaded() async {
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return sub.read().requireValue;
  }

  test('nhanh: ≤ 20 phút, nhanh nhất trước, cùng phút giữ thứ tự, tối đa 3', () async {
    final state = await loaded();
    expect(state.quick.map((r) => r.id), ['quick', 'rice-only', 'both']);
  });

  test('nấu được: đủ đồ trước rồi thiếu ít, cập nhật theo Tủ đồ', () async {
    var state = await loaded();
    expect(state.cookable.map((m) => m.recipe.id), [
      'slow',
      'rice-only',
      'quick',
      'also-20',
      'both',
    ]);
    expect(state.cookable.every((m) => !m.availability.isReady), isTrue);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    state = sub.read().requireValue;
    expect(state.cookable.map((m) => m.recipe.id).take(2), ['slow', 'quick']);
    expect(state.cookable.first.availability.isReady, isTrue);
    expect(state.cookable[2].availability.missing, ['cơm']);
  });

  test('tối đa 6 món nấu được', () async {
    final many = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith(
          (ref) async => [for (var i = 0; i < 8; i++) _recipe('r$i', 10, const [])],
        ),
      ],
    );
    addTearDown(many.dispose);
    final manySub = many.listen(discoverViewModelProvider, (_, _) {});
    await many.read(recipesProvider.future);
    await many.read(ingredientsProvider.future);

    expect(manySub.read().requireValue.cookable.length, DiscoverViewModel.cookableLimit);
  });
}
