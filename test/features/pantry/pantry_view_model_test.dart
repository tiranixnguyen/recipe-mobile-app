import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_view_model.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
];

Recipe _recipe(String id, List<String> needs) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [for (final n in needs) RecipeIngredient(id: n, amount: 1, unit: 'g')],
  steps: const [],
);

void main() {
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<PantryState>> sub;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith(
          (ref) async => [
            _recipe('trung-chien', ['egg', 'scallion', 'salt']),
            _recipe('com-trung', ['egg', 'rice']),
            _recipe('canh', ['egg', 'tomato', 'scallion']),
            _recipe('n1', ['egg']),
            _recipe('n2', ['rice']),
          ],
        ),
      ],
    );
    sub = container.listen(pantryViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<PantryState> loaded() async {
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return sub.read().requireValue;
  }

  test('nhóm theo thứ tự IngredientGroup, bỏ gia vị cơ bản', () async {
    final state = await loaded();
    expect(state.groups.map((g) => g.group), [
      IngredientGroup.protein,
      IngredientGroup.vegetable,
      IngredientGroup.starch,
    ]);
    expect(state.groups[1].items.map((i) => i.id), ['scallion', 'tomato']);
    expect(state.have, isEmpty);
    expect(state.ready, isEmpty);
  });

  test('bật/tắt thì món nấu được cập nhật ngay và lưu LocalStore', () async {
    await loaded();
    final viewModel = container.read(pantryViewModelProvider.notifier);

    await viewModel.toggle('egg');
    var state = sub.read().requireValue;
    expect(state.have, {'egg'});
    expect(state.ready.map((r) => r.id), ['n1']);
    expect(state.near.map((m) => m.recipe.id), ['trung-chien', 'com-trung', 'n2']);
    expect(container.read(localStoreProvider).readList('pantry.items'), ['egg']);

    await viewModel.toggle('scallion');
    state = sub.read().requireValue;
    expect(state.ready.map((r) => r.id), ['trung-chien', 'n1']);

    await viewModel.toggle('egg');
    state = sub.read().requireValue;
    expect(state.have, {'scallion'});
    expect(state.ready, isEmpty);
    expect(container.read(localStoreProvider).readList('pantry.items'), ['scallion']);
  });

  test('chỉ giữ tối đa 3 món thiếu ít', () async {
    await loaded();
    final near = sub.read().requireValue.near;
    expect(near.length, PantryViewModel.nearLimit);
    expect(near.first.availability.missing, ['trứng']);
  });

  test('dữ liệu lỗi thì state lỗi', () async {
    final failing = ProviderContainer(
      overrides: [
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith((ref) => Future.error(const FormatException('hỏng'))),
      ],
    );
    addTearDown(failing.dispose);
    final failingSub = failing.listen(pantryViewModelProvider, (_, _) {});
    await expectLater(failing.read(recipesProvider.future), throwsFormatException);

    expect(failingSub.read().hasError, isTrue);
  });
}
