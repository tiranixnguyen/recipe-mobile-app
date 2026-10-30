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

/// Thứ Ba 27/10/2026.
final _today = DateTime(2026, 10, 27);

void main() {
  group('focusMealFor', () {
    DateTime at(int hour, [int minute = 0]) => DateTime(2026, 10, 27, hour, minute);
    const empty = <Meal, List<Object>>{};

    test('hôm nay là bữa tới theo giờ', () {
      expect(focusMealFor(_today, at(7, 30), empty), Meal.breakfast);
      expect(focusMealFor(_today, at(11, 30), empty), Meal.lunch);
      expect(focusMealFor(_today, at(18, 30), empty), Meal.dinner);
      expect(focusMealFor(_today, at(22), empty), Meal.dinner);
      // Bữa tới theo giờ dù bữa khác đã có món.
      expect(
        focusMealFor(_today, at(7, 30), {
          Meal.dinner: ['a'],
        }),
        Meal.breakfast,
      );
    });

    test('ngày khác là bữa đầu tiên có món, không có thì Sáng', () {
      final tomorrow = DateTime(2026, 10, 28);
      expect(focusMealFor(tomorrow, at(18, 30), empty), Meal.breakfast);
      expect(
        focusMealFor(tomorrow, at(18, 30), {
          Meal.breakfast: const [],
          Meal.lunch: ['a'],
          Meal.dinner: ['b'],
        }),
        Meal.lunch,
      );
    });
  });

  test('dishSummary: tối đa 2 tên rồi "+N món"', () {
    expect(dishSummary(['A']), 'A');
    expect(dishSummary(['A', 'B']), 'A, B');
    expect(dishSummary(['A', 'B', 'C', 'D']), 'A, B +2 món');
  });

  test('mealSummary và mealMeta', () {
    expect(mealSummary(['A', 'B', 'C'], 40), '3 món · 40 phút · A, B +1 món');
    expect(mealSummary([], 0), 'Chưa có món');
    expect(mealMeta(2, 40), '2 món · ~40 phút');
    expect(mealMeta(0, 0), 'Còn trống');
  });

  test('dayTitle, weekTitle, dayWord', () {
    expect(dayTitle(_today, DateTime(2026, 10, 27, 18)), 'Thứ Ba, 27/10 · Hôm nay');
    expect(dayTitle(DateTime(2026, 11, 1), _today), 'Chủ nhật, 1/11');
    expect(weekTitle(DateTime(2026, 10, 29)), 'Tuần 26/10 – 1/11');
    expect(dayWord(_today, _today), 'nay');
    expect(dayWord(DateTime(2026, 10, 28), _today), 'thứ tư');
  });

  test('whenLabel và dayOptionLabel: nay, mai, tên ngày, tuần sau', () {
    expect(whenLabel(Meal.dinner, _today, _today), 'Tối nay');
    expect(whenLabel(Meal.lunch, DateTime(2026, 10, 28), _today), 'Trưa mai');
    expect(whenLabel(Meal.breakfast, DateTime(2026, 10, 29), _today), 'Sáng thứ Năm');
    expect(whenLabel(Meal.dinner, DateTime(2026, 11, 1), _today), 'Tối Chủ nhật');
    expect(whenLabel(Meal.breakfast, DateTime(2026, 11, 2), _today), 'Sáng thứ Hai tuần sau');

    expect(dayOptionLabel(_today, _today), 'Thứ Ba, hôm nay');
    expect(dayOptionLabel(DateTime(2026, 10, 28), _today), 'Thứ Tư, ngày mai');
    expect(dayOptionLabel(DateTime(2026, 10, 30), _today), 'Thứ Sáu');
    expect(dayOptionLabel(DateTime(2026, 11, 2), _today), 'Thứ Hai tuần sau');
  });

  group('joinText', () {
    final dauPhu = _recipe('dau-phu', 'Đậu phụ sốt cà chua');
    final canh = _recipe('canh', 'Canh cà chua trứng');
    final rau = _recipe('rau', 'Rau muống xào');

    test('bữa trống hoặc chỉ có chính món đang thêm thì null', () {
      expect(joinText([], ['trung']), isNull);
      expect(joinText([_recipe('trung', 'Trứng')], ['trung']), isNull);
    });

    test('một món thêm vào bữa có sẵn', () {
      expect(
        joinText([dauPhu], ['trung']),
        'Sẽ thêm cùng Đậu phụ sốt cà chua · bữa này thành 2 món',
      );
    });

    test('cả bữa nhiều món, bỏ món trùng, tóm tắt tên dài', () {
      expect(
        joinText([dauPhu, canh, rau], ['trung', 'canh']),
        'Sẽ thêm cùng Đậu phụ sốt cà chua, Rau muống xào · bữa này thành 4 món',
      );
      expect(
        joinText([dauPhu, canh, rau], ['trung', 'com']),
        'Sẽ thêm cùng Đậu phụ sốt cà chua, Canh cà chua trứng +1 món · bữa này thành 5 món',
      );
    });
  });

  group('week', () {
    test('monthGrid: bắt đầu Thứ Hai, 5 hàng khi đủ', () {
      // Tháng 10/2026: ngày 1 là Thứ Năm, 31 ngày → 35 ô.
      final grid = monthGrid(2026, 10);
      expect(grid.length, 35);
      expect(grid.first, DateTime(2026, 9, 28));
      expect(grid.first.weekday, DateTime.monday);
      expect(grid.last, DateTime(2026, 11, 1));
    });

    test('monthGrid: 6 hàng khi tháng cần, vừa khít thì ít hàng hơn', () {
      // Tháng 8/2026: ngày 1 là Thứ Bảy, 31 ngày → 42 ô.
      final grid = monthGrid(2026, 8);
      expect(grid.length, 42);
      expect(grid.first, DateTime(2026, 7, 27));
      expect(grid.last, DateTime(2026, 9, 6));
      // Tháng 2/2027: ngày 1 là Thứ Hai, 28 ngày → đúng 4 hàng.
      expect(monthGrid(2027, 2).length, 28);
    });

    test('upcomingDays: 7 ngày cuốn từ hôm nay, qua tháng', () {
      expect(upcomingDays(DateTime(2026, 10, 27, 18, 30)), [
        for (var d = 27; d <= 31; d++) DateTime(2026, 10, d),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
      ]);
    });
  });
}
