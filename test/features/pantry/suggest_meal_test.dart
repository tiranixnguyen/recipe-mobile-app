import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

const _ingredients = {
  'egg': Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  'tomato': Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  'tofu': Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
  'greens': Ingredient(id: 'greens', name: 'Rau cải', group: IngredientGroup.vegetable),
  'salt': Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
};

Recipe _recipe(
  String id,
  DishRole role, {
  int minutes = 10,
  DishFeel? feel,
  List<RecipeTag> tags = const [],
  List<Tool> tools = const [Tool.stove],
  List<String> ingredients = const ['egg'],
}) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: 'assets/images/recipes/$id.jpg',
  minutes: minutes,
  servings: 1,
  tools: tools,
  diets: const [],
  meals: const [],
  ingredients: [for (final i in ingredients) RecipeIngredient(id: i, amount: 1, unit: 'phần')],
  steps: const [RecipeStep(text: 'Nấu.')],
  role: role,
  feel: feel,
  tags: tags,
);

MealSuggestion? _suggest(
  List<Recipe> recipes, [
  MealPrefs prefs = const MealPrefs(),
  Set<String> pantry = const {'egg'},
  Set<String> exclude = const {},
  Set<Tool> tools = const {},
  Set<String> saved = const {},
]) => suggestMeal(
  recipes,
  prefs,
  pantry: pantry,
  ingredientsById: _ingredients,
  exclude: exclude,
  tools: tools,
  saved: saved,
);

List<String> _ids(MealSuggestion? s) => [for (final r in s!.dishes) r.id];

void main() {
  final menu = [
    _recipe('mi', DishRole.single),
    _recipe('trung', DishRole.main),
    _recipe('dau-phu', DishRole.main, ingredients: ['tofu', 'tomato']),
    _recipe('canh', DishRole.soup, minutes: 15, ingredients: ['egg', 'tomato']),
    _recipe('rau', DishRole.side, ingredients: ['greens', 'salt']),
  ];

  group('quy mô', () {
    test('1 món gọn lẹ lấy món một mình', () {
      final meal = _suggest(menu, const MealPrefs(scale: MealScale.one));
      expect(_ids(meal), ['mi']);
      expect(meal!.scale, MealScale.one);
      expect(meal.relaxedNote, isNull);
    });

    test('1 món mà không có món một mình thì lấy món mặn', () {
      expect(
        _ids(_suggest(menu.skip(1).toList(), const MealPrefs(scale: MealScale.one))),
        ['trung'],
      );
    });

    test('cơm nhà 2 món: món mặn + canh hoặc rau', () {
      final meal = _suggest(menu);
      expect(meal!.dishes.map((r) => r.role), [
        DishRole.main,
        isIn({DishRole.soup, DishRole.side}),
      ]);
      expect(meal.totalMinutes, meal.dishes.fold(0, (sum, r) => sum + r.minutes));
    });

    test('mâm cơm: món mặn, canh, rau, không trùng món', () {
      final meal = _suggest(menu, const MealPrefs(scale: MealScale.tray, maxMinutes: 45));
      expect(meal!.dishes.map((r) => r.role), [DishRole.main, DishRole.soup, DishRole.side]);
      expect(meal.dishes.toSet(), hasLength(3));
    });

    test('mâm cơm thiếu rau thì thêm món mặn thứ hai, không lặp món', () {
      final noSide = menu.where((r) => r.role != DishRole.side).toList();
      final meal = _suggest(noSide, const MealPrefs(scale: MealScale.tray, maxMinutes: 45));
      expect(meal!.dishes.map((r) => r.role), [DishRole.main, DishRole.soup, DishRole.main]);
      expect(_ids(meal).toSet(), hasLength(3));
    });
  });

  group('lọc cứng', () {
    test('exclude loại món vừa bỏ qua', () {
      expect(_ids(_suggest(menu, const MealPrefs(scale: MealScale.one), const {'egg'}, {'mi'})), [
        'trung',
      ]);
    });

    test('chỉ món nấu được bằng dụng cụ đang có', () {
      final recipes = [
        _recipe('mi-ly', DishRole.single, tools: [Tool.kettle]),
        _recipe('mi', DishRole.single),
      ];
      expect(
        _ids(
          _suggest(recipes, const MealPrefs(scale: MealScale.one), const {}, const {}, {
            Tool.kettle,
          }),
        ),
        ['mi-ly'],
      );
    });

    test('không có món nào hợp lệ thì null, kể cả sau khi nới', () {
      expect(_suggest(const []), isNull);
      expect(_suggest(menu, const MealPrefs(), const {}, {for (final r in menu) r.id}), isNull);
    });
  });

  group('nới tiêu chí', () {
    test('bỏ tag trước, ghi câu', () {
      final meal = _suggest(menu, const MealPrefs(scale: MealScale.one, tags: {RecipeTag.party}));
      expect(_ids(meal), ['mi']);
      expect(meal!.relaxedNote, 'Đã bỏ tiêu chí Đãi bạn để có đủ gợi ý.');
    });

    test('tag có ở một món thì giữ, không nới', () {
      final recipes = [
        ...menu,
        _recipe('mi-tron', DishRole.single, tags: [RecipeTag.snack]),
      ];
      final meal = _suggest(
        recipes,
        const MealPrefs(scale: MealScale.one, tags: {RecipeTag.snack}),
      );
      expect(_ids(meal), ['mi-tron']);
      expect(meal!.relaxedNote, isNull);
    });

    test('rồi bỏ cảm giác; gộp vào một câu', () {
      final meal = _suggest(
        menu,
        const MealPrefs(scale: MealScale.one, feel: DishFeel.cooling, tags: {RecipeTag.party}),
      );
      expect(meal!.relaxedNote, 'Đã bỏ tiêu chí Đãi bạn và Giải nhiệt để có đủ gợi ý.');
      expect(meal.reasons, isNot(contains('Giải nhiệt')));
    });

    test('cảm giác: cần ít nhất một món đúng, không món nào ngược', () {
      final recipes = [
        _recipe('trung-hap', DishRole.main, feel: DishFeel.warming),
        _recipe('trung', DishRole.main, minutes: 15),
        _recipe('canh', DishRole.soup, feel: DishFeel.cooling),
        _recipe('rau', DishRole.side),
      ];
      final meal = _suggest(recipes, const MealPrefs(feel: DishFeel.cooling));
      expect(_ids(meal), ['trung', 'canh']);
      expect(meal!.reasons, contains('Giải nhiệt'));
      expect(meal.relaxedNote, isNull);
    });

    test('rồi nới thời gian 30 → 45 → bỏ giới hạn', () {
      final slow = [
        _recipe('kho', DishRole.main, minutes: 25),
        _recipe('canh', DishRole.soup, minutes: 15),
      ];
      expect(_suggest(slow)!.relaxedNote, 'Đã nới thời gian lên 45 phút để có đủ gợi ý.');

      final slower = [
        _recipe('kho', DishRole.main, minutes: 35),
        _recipe('canh', DishRole.soup, minutes: 15),
      ];
      final meal = _suggest(slower, const MealPrefs(feel: DishFeel.warming));
      expect(meal!.relaxedNote, 'Đã bỏ tiêu chí Ấm bụng, bỏ giới hạn thời gian để có đủ gợi ý.');
      expect(meal.totalMinutes, 50);
    });

    test('cuối cùng hạ quy mô, kèm câu', () {
      final noSide = [
        _recipe('trung', DishRole.main),
        _recipe('canh', DishRole.soup),
      ];
      final meal = _suggest(noSide, const MealPrefs(scale: MealScale.tray));
      expect(_ids(meal), ['trung', 'canh']);
      expect(meal!.scale, MealScale.two);
      expect(
        meal.relaxedNote,
        'Chưa đủ món cho mâm cơm, đã gợi ý cơm nhà 2 món. '
        'Đã bỏ giới hạn thời gian để có đủ gợi ý.',
      );

      final onlySingle = _suggest([
        _recipe('mi', DishRole.single),
      ], const MealPrefs(maxMinutes: null));
      expect(onlySingle!.scale, MealScale.one);
      expect(onlySingle.relaxedNote, 'Chưa đủ món cho cơm nhà 2 món, đã gợi ý 1 món gọn lẹ.');
    });
  });

  group('xếp hạng', () {
    test('đủ đồ lên trước thiếu đồ', () {
      final recipes = [
        _recipe('thieu', DishRole.single, ingredients: ['tofu']),
        _recipe('du', DishRole.single),
      ];
      final meal = _suggest(recipes, const MealPrefs(scale: MealScale.one));
      expect(_ids(meal), ['du']);
      expect(meal!.reasons.first, 'Đủ đồ');
    });

    test('ưu tiên đồ trong tủ: dùng nhiều đồ đang có hơn; tắt thì theo thời gian', () {
      final recipes = [
        _recipe('mi', DishRole.single, minutes: 5, ingredients: ['egg']),
        _recipe('dau-phu', DishRole.single, minutes: 20, ingredients: ['tofu', 'tomato']),
      ];
      const pantry = {'egg', 'tofu', 'tomato'};
      final fridge = _suggest(recipes, const MealPrefs(scale: MealScale.one), pantry);
      expect(_ids(fridge), ['dau-phu']);
      expect(fridge!.reasons, ['Đủ đồ', 'Dùng nốt đậu phụ và cà chua', '~20 phút']);

      final any = _suggest(recipes, const MealPrefs(scale: MealScale.one, fridge: false), pantry);
      expect(_ids(any), ['mi']);
      expect(any!.reasons, ['Đủ đồ', '~5 phút']);
    });

    test('cùng điểm thì món đã lưu lên trước', () {
      final recipes = [_recipe('a', DishRole.single), _recipe('b', DishRole.single)];
      expect(
        _ids(
          _suggest(
            recipes,
            const MealPrefs(scale: MealScale.one),
            const {'egg'},
            const {},
            const {},
            {'b'},
          ),
        ),
        ['b'],
      );
    });

    test('thiếu đồ gộp các món, không trùng, gia vị cơ bản không tính', () {
      final recipes = [
        _recipe('dau-phu', DishRole.main, ingredients: ['tofu', 'tomato']),
        _recipe('canh', DishRole.soup, ingredients: ['tomato', 'greens', 'salt']),
      ];
      final meal = _suggest(recipes, const MealPrefs(), const {});
      expect(meal!.availability.missing, ['đậu phụ', 'cà chua', 'rau cải']);
      expect(meal.reasons.first, 'Thiếu 3 thứ');
    });
  });

  test('dữ liệu đóng gói ghép được cả ba quy mô, không phải hạ', () {
    final recipes = [
      for (final json in jsonDecode(File('assets/data/recipes.json').readAsStringSync()) as List)
        Recipe.fromJson(json as Map<String, dynamic>),
    ];
    for (final scale in MealScale.values) {
      final meal = suggestMeal(
        recipes,
        MealPrefs(scale: scale, maxMinutes: null),
        pantry: const {},
        ingredientsById: const {},
      );
      expect(meal?.scale, scale, reason: '$scale');
      expect(meal!.dishes.length, scale.index + 1);
    }
  });
}
