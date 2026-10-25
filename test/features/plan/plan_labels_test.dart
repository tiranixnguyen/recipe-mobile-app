import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/domain/plan_labels.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';

Recipe _recipe(String id, String name) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);

void main() {
  group('whenLabel', () {
    test('nay, mai, rồi tên ngày', () {
      expect(whenLabel(Meal.dinner, 1, 1), 'Tối nay');
      expect(whenLabel(Meal.lunch, 2, 1), 'Trưa mai');
      expect(whenLabel(Meal.breakfast, 3, 1), 'Sáng thứ Năm');
      expect(whenLabel(Meal.dinner, 6, 1), 'Tối Chủ nhật');
      expect(whenLabel(Meal.lunch, 0, 1), 'Trưa thứ Hai');
    });
  });

  group('joinText', () {
    final a = _recipe('a', 'Cơm rang dưa cải');
    final b = _recipe('b', 'Canh rau');

    test('bữa trống thì null', () {
      expect(joinText(const [], 'x'), isNull);
    });

    test('kể món đang có và tổng món sau khi thêm', () {
      expect(joinText([a], 'x'), 'Sẽ thêm cùng Cơm rang dưa cải · bữa này thành 2 món');
      expect(
        joinText([a, b], 'x'),
        'Sẽ thêm cùng Cơm rang dưa cải, Canh rau · bữa này thành 3 món',
      );
    });

    test('không tính chính món đang thêm nếu nó đã có', () {
      expect(joinText([a, b], 'a'), 'Sẽ thêm cùng Canh rau · bữa này thành 2 món');
      expect(joinText([a], 'a'), isNull);
    });
  });

  group('week', () {
    test('tuần bắt đầu Thứ Hai, qua tháng vẫn đúng', () {
      // Thứ Bảy 31/10/2026.
      final sat = DateTime(2026, 10, 31, 20);
      expect(weekdayIndex(sat), 5);
      final start = weekStartOf(sat);
      expect(start, DateTime(2026, 10, 26));
      expect(dayOfWeek(start, 6), DateTime(2026, 11, 1));
      expect(indexInWeek(start, DateTime(2026, 11, 1)), 6);
      expect(indexInWeek(start, DateTime(2026, 11, 2)), isNull);
    });
  });
}
