import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved_meal/saved_meal_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

import '../../core/fake_analytics.dart';
import 'meal_fixtures.dart';

final _savedAt = DateTime(2026, 10, 30, 19);
final _meal = const SavedMeal(
  recipeIds: ['trung', 'canh'],
  servings: 2,
  tags: [RecipeTag.cheap],
).withSavedAt(_savedAt);

class _Env {
  _Env({this.saved = true}) {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        analyticsProvider.overrideWithValue(analytics),
        recipesProvider.overrideWith((ref) async => mealRecipes),
        ingredientsProvider.overrideWith((ref) async => mealIngredientsFixture),
      ],
    );
    addTearDown(container.dispose);
  }

  final bool saved;
  final analytics = FakeAnalytics();
  late final ProviderContainer container;

  Future<void> open([String? key]) async {
    if (saved) await container.read(savedMealsProvider.notifier).saveMeal(_meal);
    container.listen(savedMealViewModelProvider(key ?? _meal.key), (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
  }

  SavedMealViewModel get vm => container.read(savedMealViewModelProvider(_meal.key).notifier);

  MealDetailState get state => container.read(savedMealViewModelProvider(_meal.key)).requireValue!;

  List<String> get keys => [for (final m in container.read(savedMealsProvider)) m.key];
  List<String> get ids => [for (final d in state.dishes) d.recipe.id];
}

void main() {
  test('state: món theo thứ tự, thời gian, dụng cụ, nguyên liệu gộp so với Tủ đồ', () async {
    final env = _Env();
    await env.container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await env.open();

    final state = env.state;
    expect(env.ids, ['trung', 'canh']);
    expect((state.servings, state.saved), (2, true));
    expect(state.tags, [RecipeTag.cheap]);
    expect((state.minutes, state.tools), (35, 'Bếp từ, Nồi cơm điện'));
    expect(state.dishes.first.availability.missing, ['hành lá']);
    expect(state.ingredients.have.map((i) => (i.name, i.amountText)), [('Trứng gà', '4 quả')]);
    expect(state.ingredients.missing.map((i) => (i.name, i.amountText, i.uses)), [
      ('Hành lá', '4 nắm', 'Cả 2 món'),
      ('Cà chua', '4 quả', 'Canh cà chua'),
    ]);
    expect(state.ingredients.basicSpices, ['Dầu ăn']);
    expect(state.canRemove, isTrue);
    expect(state.picker, isNull);
    expect(state.groups, isEmpty);
  });

  test('không còn bữa với khoá đó thì null', () async {
    final env = _Env(saved: false);
    await env.open();
    expect(env.container.read(savedMealViewModelProvider(_meal.key)).requireValue, isNull);
  });

  group('sửa món', () {
    test('thêm: vào cuối, ghi lại bữa đã lưu giữ giờ lưu và vị trí; Hoàn tác trả về', () async {
      final env = _Env();
      await env.container
          .read(savedMealsProvider.notifier)
          .saveMeal(const SavedMeal(recipeIds: ['rau'], servings: 1));
      await env.open();

      final change = (await env.vm.add('dau'))!;
      expect(
        (change.kind, change.name, change.from),
        (MealChangeKind.added, 'Đậu phụ sốt cà chua', null),
      );
      expect(env.ids, ['trung', 'canh', 'dau']);
      expect(env.keys, ['trung,canh,dau', 'rau']);
      final stored = env.container.read(savedMealsProvider).first;
      expect((stored.savedAt, stored.servings), (_savedAt, 2));
      expect(stored.tags, [RecipeTag.cheap]);

      await change.undo();
      expect(env.ids, ['trung', 'canh']);
      expect(env.keys, ['trung,canh', 'rau']);
      expect(env.container.read(savedMealsProvider).first.savedAt, _savedAt);
    });

    test('đổi: giữ vị trí món; không đổi sang món đã có', () async {
      final env = _Env();
      await env.open();

      expect(await env.vm.swap('trung', 'canh'), isNull);
      expect(await env.vm.swap('khong-co', 'rau'), isNull);
      final change = (await env.vm.swap('trung', 'rau'))!;
      expect(
        (change.kind, change.name, change.from),
        (
          MealChangeKind.swapped,
          'Rau muống xào tỏi',
          'Trứng chiên hành',
        ),
      );
      expect(env.ids, ['rau', 'canh']);
      expect(env.keys, ['rau,canh']);

      await change.undo();
      expect(env.keys, ['trung,canh']);
    });

    test('bỏ: không bỏ được món duy nhất; Hoàn tác trả món về đúng chỗ', () async {
      final env = _Env();
      await env.open();

      final change = (await env.vm.remove('trung'))!;
      expect(change.kind, MealChangeKind.removed);
      expect(env.ids, ['canh']);
      expect(env.state.canRemove, isFalse);
      expect(await env.vm.remove('canh'), isNull);
      expect(env.keys, ['canh']);

      await change.undo();
      expect(env.ids, ['trung', 'canh']);
      expect(env.keys, ['trung,canh']);
    });

    test('Hoàn tác vẫn ghi lại bữa khi màn đã đóng', () async {
      final env = _Env();
      await env.open();
      final change = (await env.vm.add('rau'))!;

      env.container.invalidate(savedMealViewModelProvider(_meal.key));
      await change.undo();
      expect(env.keys, ['trung,canh']);
    });

    test('chưa lưu thì chỉ sửa trên màn, không ghi Đã lưu', () async {
      final env = _Env(saved: false);
      await env.container.read(savedMealsProvider.notifier).saveMeal(_meal);
      await env.open();
      await env.vm.toggleSave();
      expect(env.container.read(savedMealsProvider), isEmpty);

      final change = (await env.vm.add('rau'))!;
      expect(env.ids, ['trung', 'canh', 'rau']);
      expect(env.container.read(savedMealsProvider), isEmpty);
      expect(env.state.saved, isFalse);

      await change.undo();
      expect(env.ids, ['trung', 'canh']);
      expect(env.container.read(savedMealsProvider), isEmpty);
    });
  });

  group('lưu / bỏ lưu', () {
    test('bỏ lưu ở lại màn với đủ món; Hoàn tác lưu lại với giờ cũ', () async {
      final env = _Env();
      await env.open();

      final outcome = (await env.vm.toggleSave())!;
      expect(outcome.name, 'Trứng chiên hành + Canh cà chua');
      expect(env.container.read(savedMealsProvider), isEmpty);
      expect(env.ids, ['trung', 'canh']);
      expect(env.state.saved, isFalse);
      expect(env.analytics.params.last, {'kind': 'meal', 'undo': false});

      await outcome.undo();
      expect(env.state.saved, isTrue);
      expect(env.container.read(savedMealsProvider).single.savedAt, _savedAt);
    });

    test('lưu lại bữa đang sửa với khẩu phần và tiêu chí cũ', () async {
      final env = _Env();
      await env.open();
      await env.vm.toggleSave();
      await env.vm.add('rau');

      expect(await env.vm.toggleSave(), isNull);
      final stored = env.container.read(savedMealsProvider).single;
      expect((stored.key, stored.servings), ('trung,canh,rau', 2));
      expect(stored.tags, [RecipeTag.cheap]);
      expect(env.state.saved, isTrue);
      expect(env.analytics.events.last, 'save_meal');
      expect(env.analytics.params.last, {'dishes': 3, 'tags': 1});
    });
  });

  group('đi chợ', () {
    test('thêm đồ thiếu: chỉ thứ chưa có, trả added / skipped, badge và nút cập nhật', () async {
      final env = _Env();
      await env.container.read(pantryItemsProvider.notifier).addToPantry('egg');
      await env.container.read(shoppingItemsProvider.notifier).addIngredient('tomato');
      await env.open();
      expect(env.state.missingIds, ['scallion', 'tomato']);
      expect(env.state.toAddIds, ['scallion']);
      expect(env.state.shoppingCount, 1);

      final result = await env.vm.addMissingToShopping();
      expect((result.added, result.skipped), (1, 1));
      expect(env.state.toAddIds, isEmpty);
      expect(env.state.shoppingCount, 2);
      expect(env.state.ingredients.missing.every((i) => i.inShopping), isTrue);
      expect(env.analytics.events.last, 'add_missing_to_shopping');
      expect(env.analytics.params.last, {'from': 'meal', 'items': 1});

      final again = await env.vm.addMissingToShopping();
      expect((again.added, again.skipped), (0, 2));
      expect(env.analytics.events.where((e) => e == 'add_missing_to_shopping'), hasLength(1));
    });

    test('Thêm vào thực đơn: ghi add_meal_to_plan khi thêm được', () async {
      final env = _Env();
      await env.open();

      List<Recipe>? shown;
      await env.vm.addToPlan((dishes) async {
        shown = dishes;
        return false;
      });
      expect(shown, [mealEgg, mealSoup]);
      expect(env.analytics.events, isNot(contains('add_meal_to_plan')));

      await env.vm.addToPlan((_) async => true);
      expect(env.analytics.events.last, 'add_meal_to_plan');
      expect(env.analytics.params.last, {'dishes': 2});
    });

    test('Bắt đầu nấu trả đường dẫn nấu cả bữa với món đang sửa', () async {
      final env = _Env();
      await env.open();
      await env.vm.add('rau');
      expect(env.vm.startCooking(), mealCookDishesLocation(['trung', 'canh', 'rau'], 2));
      expect(env.vm.startCooking(), '/meal-cook?dishes=trung%2Ccanh%2Crau&servings=2');
    });
  });

  group('sheet chọn món', () {
    test('thêm: Tất cả, món đã lưu trước, món trong bữa đánh dấu inMeal', () async {
      final env = _Env();
      await env.container.read(savedIdsProvider.notifier).save('rau');
      await env.open();

      env.vm.openAdd();
      final state = env.state;
      expect((state.picker!.swapId, state.picker!.role), (null, null));
      expect([for (final g in state.groups) g.saved], [true, false]);
      expect([for (final i in state.groups.first.items) i.recipe.id], ['rau']);
      expect(
        {
          for (final g in state.groups)
            for (final i in g.items) i.recipe.id: i.inMeal,
        },
        {'rau': false, 'canh': true, 'dau': false, 'trung': true},
      );
      final tofu = state.groups.last.items.firstWhere((i) => i.recipe.id == 'dau');
      expect(tofu.availability.missing, ['đậu phụ', 'cà chua']);

      env.vm.closePicker();
      expect(env.state.picker, isNull);
      expect(env.state.groups, isEmpty);
    });

    test('đổi: lọc sẵn theo loại của món; từ khoá và loại', () async {
      final env = _Env();
      await env.open();

      env.vm.openSwap('canh');
      expect(env.state.picker!.swapId, 'canh');
      expect(env.state.picker!.role, DishRole.soup);
      expect(
        [
          for (final g in env.state.groups)
            for (final i in g.items) i.recipe.id,
        ],
        ['canh'],
      );

      env.vm.setRole(null);
      env.vm.setQuery('DAU phu');
      expect(
        [
          for (final g in env.state.groups)
            for (final i in g.items) i.recipe.id,
        ],
        ['dau'],
      );
      env.vm.setQuery('khong-co-mon-nay');
      expect(env.state.groups, isEmpty);
    });

    test('đổi món mặn thì lọc sẵn Món mặn', () async {
      final env = _Env();
      await env.open();
      env.vm.openSwap('trung');
      expect(env.state.picker!.role, DishRole.main);
    });
  });
}
