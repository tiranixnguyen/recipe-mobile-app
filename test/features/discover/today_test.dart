import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/today.dart';

void main() {
  test('bữa theo giờ có ranh giới chính xác', () {
    expect(mealForHour(0), Meal.breakfast);
    expect(mealForHour(9), Meal.breakfast);
    expect(mealForHour(10), Meal.lunch);
    expect(mealForHour(14), Meal.lunch);
    expect(mealForHour(15), Meal.dinner);
    expect(mealForHour(23), Meal.dinner);
  });

  test('lý do theo đồ trong tủ và bữa', () {
    expect(todayReason(const [], Meal.dinner), 'Bạn có đủ đồ · hợp bữa tối');
    expect(todayReason(const ['hành lá'], Meal.dinner), 'Thiếu hành lá · hợp bữa tối');
    expect(
      todayReason(const ['trứng', 'hành lá'], Meal.lunch),
      'Thiếu trứng, hành lá · hợp bữa trưa',
    );
    expect(todayReason(null, Meal.breakfast), 'Hợp bữa sáng');
  });

  test('món chính và hai món "Hoặc thử" lấy theo vòng', () {
    String? pick(List<String> items, int index) {
      final picked = todayPick(items, index);
      return picked == null ? null : '${picked.main}|${picked.alternatives.join(',')}';
    }

    expect(pick(const [], 0), isNull);
    expect(pick(const ['a', 'b', 'c', 'd'], 0), 'a|b,c');
    expect(pick(const ['a', 'b', 'c', 'd'], 3), 'd|a,b');
    expect(pick(const ['a', 'b', 'c'], 4), 'b|c,a');
    expect(pick(const ['a', 'b'], 1), 'b|a');
    expect(pick(const ['a'], 5), 'a|');
  });
}
