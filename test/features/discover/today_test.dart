import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/domain/today.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

Recipe dish(String id, DishRole role, {DishFeel? feel}) => Recipe(
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
  role: role,
  feel: feel,
);

void main() {
  test('bữa theo giờ có ranh giới chính xác', () {
    expect(mealForHour(0), Meal.breakfast);
    expect(mealForHour(9), Meal.breakfast);
    expect(mealForHour(10), Meal.lunch);
    expect(mealForHour(14), Meal.lunch);
    expect(mealForHour(15), Meal.dinner);
    expect(mealForHour(23), Meal.dinner);
  });

  group('swapCandidate', () {
    final meat = dish('meat', DishRole.main);
    final soup = dish('soup', DishRole.soup);
    final ranked = [
      meat,
      soup,
      dish('egg', DishRole.main),
      dish('soup2', DishRole.soup),
      dish('tofu', DishRole.main),
    ];

    test('lấy món cùng vai, chưa có trong bữa, theo thứ tự xếp hạng', () {
      final next = swapCandidate(ranked, [meat, soup], 0, const {});
      expect(next?.recipe.id, 'egg');
      expect(next?.tried, {'meat', 'egg'});
      expect(swapCandidate(ranked, [meat, soup], 1, const {})?.recipe.id, 'soup2');
    });

    test('bỏ món đã thử, thử hết thì quay vòng', () {
      final egg = ranked[2];
      final second = swapCandidate(ranked, [egg, soup], 0, const {'meat', 'egg'});
      expect(second?.recipe.id, 'tofu');
      final tofu = ranked[4];
      final third = swapCandidate(ranked, [tofu, soup], 0, second!.tried);
      // Quay về món đầu tiên chưa nằm trong bữa.
      expect(third?.recipe.id, 'meat');
      expect(third?.tried, {'tofu', 'meat'});
    });

    test('tránh cảm giác ngược, không có ứng viên thì null', () {
      final warm = dish('warm', DishRole.soup, feel: DishFeel.warming);
      final cool = dish('cool', DishRole.soup, feel: DishFeel.cooling);
      expect(
        swapCandidate([warm, cool], [meat, soup], 1, const {}, feel: DishFeel.cooling)?.recipe.id,
        'cool',
      );
      expect(swapCandidate([meat, soup], [meat, soup], 1, const {}), isNull);
    });
  });

  test('mealNames: tối đa 2 tên rồi +N món', () {
    expect(mealNames(['A']), 'A');
    expect(mealNames(['A', 'B']), 'A, B');
    expect(mealNames(['A', 'B', 'C', 'D']), 'A, B +2 món');
  });

  group('criteriaLabels', () {
    test('mặc định: 2 món · Nhanh gọn · Dọn tủ lạnh (Tuỳ bạn không có chip)', () {
      expect(criteriaLabels(const TodayPrefs()), ['Cơm nhà 2 món', 'Nhanh gọn', 'Dọn tủ lạnh']);
    });

    test('Theo thời tiết khi chưa bật hiện Theo giờ', () {
      expect(criteriaLabels(const TodayPrefs(byWeather: true)), [
        'Cơm nhà 2 món',
        'Nhanh gọn',
        'Theo giờ',
        'Dọn tủ lạnh',
      ]);
    });

    test('cảm giác, thời gian lạ và tag theo thứ tự enum', () {
      const prefs = TodayPrefs(
        byWeather: false,
        meal: MealPrefs(
          scale: MealScale.tray,
          maxMinutes: 45,
          feel: DishFeel.warming,
          fridge: false,
          tags: {RecipeTag.party, RecipeTag.cheap},
        ),
      );
      expect(criteriaLabels(prefs), [
        'Mâm cơm (3+ món)',
        'Dưới 45 phút',
        'Ấm bụng',
        'Tiết kiệm',
        'Đãi bạn',
      ]);
    });

    test('Tuỳ bạn không hiện chip, Thong thả khi không giới hạn', () {
      const prefs = TodayPrefs(
        byWeather: false,
        meal: MealPrefs(scale: MealScale.one, maxMinutes: null, fridge: false),
      );
      expect(criteriaLabels(prefs), ['1 món gọn lẹ', 'Thong thả']);
    });
  });
}
