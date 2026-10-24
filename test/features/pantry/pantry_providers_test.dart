import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

const _egg = Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein);

Recipe _recipe(String id, {List<Meal> meals = const []}) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: 'assets/images/recipes/$id.jpg',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: meals,
  ingredients: const [RecipeIngredient(id: 'egg', amount: 1, unit: 'quả')],
  steps: const [RecipeStep(text: 'Nấu.')],
);

void main() {
  late ProviderContainer container;
  final recipes = [
    _recipe('a'),
    _recipe('b', meals: [Meal.breakfast]),
    _recipe('c'),
  ];

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => const [_egg]),
        recipesProvider.overrideWith((ref) async => recipes),
      ],
    );
  });

  tearDown(() => container.dispose());

  LocalStore store() => container.read(localStoreProvider);

  group('pantryItemsProvider', () {
    test('mặc định rỗng', () {
      expect(container.read(pantryItemsProvider), isEmpty);
    });

    test('thêm, bớt và lưu lại', () async {
      final pantry = container.read(pantryItemsProvider.notifier);
      await pantry.addToPantry('egg');
      await pantry.addToPantry('tomato');
      await pantry.removeFromPantry('tomato');

      expect(container.read(pantryItemsProvider), {'egg'});
      expect(store().readList('pantry.items'), ['egg']);

      container.invalidate(pantryItemsProvider);
      expect(container.read(pantryItemsProvider), {'egg'});
    });

    test('xoá dữ liệu đưa về rỗng', () async {
      await container.read(pantryItemsProvider.notifier).addToPantry('egg');
      await container.read(clearLocalDataProvider)();
      expect(container.read(pantryItemsProvider), isEmpty);
    });
  });

  group('availabilityProvider', () {
    test('null khi danh mục chưa tải, rồi cập nhật theo Tủ đồ', () async {
      final recipe = recipes.first;
      final sub = container.listen(availabilityProvider(recipe), (_, _) {});
      expect(sub.read(), isNull);

      await container.read(ingredientsProvider.future);
      expect(sub.read(), const Availability(missing: ['trứng']));

      await container.read(pantryItemsProvider.notifier).addToPantry('egg');
      expect(sub.read()!.isReady, isTrue);
    });
  });

  group('dislikedProvider', () {
    test('chê món lưu lý do và lúc chê', () async {
      final at = DateTime(2026, 10, 24, 19);
      await container.read(dislikedProvider.notifier).dislike('a', DislikeReason.tooLong, at: at);

      expect(container.read(dislikedProvider), {
        'a': Dislike(reason: DislikeReason.tooLong, at: at),
      });
      expect(store().readString('pantry.disliked'), isNotNull);

      container.invalidate(dislikedProvider);
      expect(container.read(dislikedProvider)['a']!.reason, DislikeReason.tooLong);
    });

    test('bản ghi sai kiểu bị bỏ, giữ phần còn lại', () async {
      await store().writeString(
        'pantry.disliked',
        '{"a": {"reason": 1, "at": "2026-10-24T19:00:00.000"}, "b": "tooLong",'
            ' "c": {"reason": "tooLong", "at": "2026-10-24T19:00:00.000"}}',
      );
      container.invalidate(dislikedProvider);
      expect(container.read(dislikedProvider).keys, ['c']);
    });

    test('dữ liệu hỏng hoặc lý do lạ bị bỏ qua', () async {
      await store().writeString(
        'pantry.disliked',
        '{"a": {"reason": "boring", "at": "2026-10-24T19:00:00.000"}}',
      );
      container.invalidate(dislikedProvider);
      expect(container.read(dislikedProvider), isEmpty);

      await store().writeString('pantry.disliked', 'not json');
      container.invalidate(dislikedProvider);
      expect(container.read(dislikedProvider), isEmpty);
    });

    test('nhãn đúng 4 lý do của màn Hôm nay ăn gì', () {
      expect(DislikeReason.values.map((r) => r.label), [
        'Vừa ăn rồi',
        'Thiếu đồ',
        'Lâu quá',
        'Không hợp khẩu vị',
      ]);
    });
  });

  group('suggestionsProvider', () {
    test('lọc theo bữa và bỏ món đã chê', () async {
      const args = (meal: Meal.dinner, count: 3);
      container.listen(suggestionsProvider(args), (_, _) {});
      expect((await container.read(suggestionsProvider(args).future)).map((r) => r.id), [
        'a',
        'c',
      ]);

      await container.read(dislikedProvider.notifier).dislike('a', DislikeReason.justAte);
      expect((await container.read(suggestionsProvider(args).future)).map((r) => r.id), ['c']);
    });
  });
}
