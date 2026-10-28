import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/data/suggestions.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

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
    test('lọc bữa, chê gần đây hạ ưu tiên và lý do cập nhật theo tủ', () async {
      const args = (meal: Meal.dinner, count: 3);
      container.listen(suggestionsProvider(args), (_, _) {});
      expect((await container.read(suggestionsProvider(args).future)).map((r) => r.id), ['a', 'c']);

      await container.read(dislikedProvider.notifier).dislike('a', DislikeReason.justAte);
      expect((await container.read(suggestionsProvider(args).future)).map((r) => r.id), ['c', 'a']);
      final reason = container.listen(suggestionReasonProvider(recipes.first), (_, _) {});
      await container.read(ingredientsProvider.future);
      expect(reason.read(), 'Thiếu 1 thứ, 10 phút, bếp từ');
      await container.read(pantryItemsProvider.notifier).addToPantry('egg');
      expect(reason.read(), 'Đủ đồ, 10 phút, bếp từ');
    });

    test('dùng hồ sơ và món đã lưu thật; chê cũ không hạ ưu tiên', () async {
      final now = DateTime(2026, 10, 26, 18);
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
          ingredientsProvider.overrideWith((ref) async => const [_egg]),
          recipesProvider.overrideWith((ref) async => recipes),
          pantryClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      await c.read(pantryItemsProvider.notifier).addToPantry('egg');
      const args = (meal: Meal.dinner, count: 3);
      c.listen(suggestionsProvider(args), (_, _) {});
      await c
          .read(dislikedProvider.notifier)
          .dislike('a', DislikeReason.notMyTaste, at: now.subtract(const Duration(days: 4)));
      await c.read(savedIdsProvider.notifier).toggle('c');
      expect((await c.read(suggestionsProvider(args).future)).map((r) => r.id), ['c', 'a']);
      await c
          .read(kitchenProfileProvider.notifier)
          .save(const KitchenProfile(tools: {Tool.kettle}));
      expect(await c.read(suggestionsProvider(args).future), isEmpty);
      await c.read(kitchenProfileProvider.notifier).save(const KitchenProfile());
      expect((await c.read(suggestionsProvider(args).future)).map((r) => r.id), ['c', 'a']);
    });
  });

  group('món bị chê sau khi nấu', () {
    final now = DateTime(2026, 10, 26, 18);

    ProviderContainer withClock() {
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
          ingredientsProvider.overrideWith((ref) async => const [_egg]),
          recipesProvider.overrideWith((ref) async => recipes),
          pantryClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('lùi xuống cuối gợi ý và món nấu được trong 3 ngày', () async {
      final c = withClock();
      final history = c.read(cookHistoryProvider.notifier);
      await history.record('a', rating: CookRating.bad, at: now.subtract(const Duration(days: 2)));
      await c.read(pantryItemsProvider.notifier).addToPantry('egg');
      const args = (meal: Meal.dinner, count: 3);
      c.listen(suggestionsProvider(args), (_, _) {});
      c.listen(pantryMatchesProvider, (_, _) {});
      await c.read(ingredientsProvider.future);

      expect((await c.read(suggestionsProvider(args).future)).map((r) => r.id), ['c', 'a']);
      expect(c.read(pantryMatchesProvider).requireValue.ready.map((r) => r.id), ['b', 'c', 'a']);
    });

    test('quá 3 ngày hoặc nấu lại chấm Ngon thì về chỗ cũ', () async {
      final c = withClock();
      final history = c.read(cookHistoryProvider.notifier);
      await history.record('a', rating: CookRating.bad, at: now.subtract(const Duration(days: 4)));
      await history.record('c', rating: CookRating.bad, at: now.subtract(const Duration(days: 1)));
      await history.record(
        'c',
        rating: CookRating.good,
        at: now.subtract(const Duration(hours: 1)),
      );
      const args = (meal: Meal.dinner, count: 3);
      c.listen(suggestionsProvider(args), (_, _) {});

      expect((await c.read(suggestionsProvider(args).future)).map((r) => r.id), ['a', 'c']);
    });
  });
}
