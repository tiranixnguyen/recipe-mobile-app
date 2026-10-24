import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

Recipe _recipe(String id, {int missing = 1}) => Recipe(
  id: id,
  name: id,
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

void main() {
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<List<SavedRecipe>>> sub;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
          ],
        ),
        recipesProvider.overrideWith(
          (ref) async => [_recipe('a'), _recipe('b'), _recipe('c'), _recipe('many', missing: 3)],
        ),
      ],
    );
    sub = container.listen(savedViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<List<SavedRecipe>> loaded() async {
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return sub.read().requireValue;
  }

  Future<void> toggle(String id) => container.read(savedIdsProvider.notifier).toggle(id);

  test('chưa lưu gì thì rỗng', () async {
    expect(await loaded(), isEmpty);
  });

  test('mới lưu lên đầu, bỏ lưu thì mất khỏi danh sách', () async {
    await loaded();
    await toggle('a');
    await toggle('c');
    expect(sub.read().requireValue.map((s) => s.recipe.id), ['c', 'a']);

    await toggle('c');
    expect(sub.read().requireValue.map((s) => s.recipe.id), ['a']);
  });

  test('bỏ id không còn trong dữ liệu', () async {
    await loaded();
    await toggle('gone');
    await toggle('b');
    expect(sub.read().requireValue.map((s) => s.recipe.id), ['b']);
  });

  test('kèm độ sẵn đồ, đổi theo Tủ đồ', () async {
    await loaded();
    await toggle('a');
    expect(sub.read().requireValue.single.availability!.missing, ['trứng']);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    expect(sub.read().requireValue.single.availability!.isReady, isTrue);
  });

  test('thiếu quá 2 thứ thì không kèm độ sẵn đồ (ẩn badge)', () async {
    await loaded();
    await toggle('many');
    expect(sub.read().requireValue.single.availability, isNull);
  });
}
