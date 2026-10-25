import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/domain/recipe_detail.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import 'fixtures.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [detailRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => detailIngredientsFixture),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<DetailState>> _read(ProviderContainer container, String id) async {
  final provider = detailViewModelProvider(id);
  container.listen(provider, (_, _) {});
  await container.read(recipesProvider.future);
  await container.read(ingredientsProvider.future);
  return container.read(provider);
}

void main() {
  test('state đủ phần: món, thiếu gì, nguyên liệu, gia vị, bước kèm thời gian', () async {
    final container = _container();
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');

    final state = (await _read(container, 'trung')).requireValue;
    expect(state.recipe.id, 'trung');
    expect(state.availability.missing, ['hành lá']);
    expect(state.ingredients.map((i) => (i.name, i.status)), [
      ('Trứng gà', IngredientStatus.inPantry),
      ('Hành lá', IngredientStatus.missing),
    ]);
    expect(state.basicSpices, ['Dầu ăn', 'tiêu']);
    expect(state.steps, [
      (text: 'Đánh trứng với hành', timeLabel: null),
      (text: 'Làm nóng dầu', timeLabel: '1 phút'),
      (text: 'Chiên mặt dưới', timeLabel: '3 phút'),
    ]);
  });

  test('Tủ đồ đổi thì trạng thái đổi theo', () async {
    final container = _container();
    expect((await _read(container, 'trung')).requireValue.availability.isReady, isFalse);

    final pantry = container.read(pantryItemsProvider.notifier);
    await pantry.addToPantry('egg');
    await pantry.addToPantry('scallion');
    final state = container.read(detailViewModelProvider('trung')).requireValue;
    expect(state.availability.isReady, isTrue);
    expect(state.ingredients.map((i) => i.status), everyElement(IngredientStatus.inPantry));
  });

  test('id không có thì lỗi RecipeNotFound', () async {
    final state = await _read(_container(), 'khong-co');
    expect(state.error, isA<RecipeNotFound>().having((e) => e.id, 'id', 'khong-co'));
  });
}
