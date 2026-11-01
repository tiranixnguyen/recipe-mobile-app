import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/today_prefs.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

void main() {
  group('TodayPrefs.tryParse', () {
    test('mặc định khi null', () {
      const def = TodayPrefs();
      expect(TodayPrefs.tryParse(null), def);
    });

    test('mặc định khi không phải Map', () {
      expect(TodayPrefs.tryParse('bad'), const TodayPrefs());
      expect(TodayPrefs.tryParse(42), const TodayPrefs());
    });

    test('đọc đầy đủ', () {
      final json = {
        'scale': 'tray',
        'maxMinutes': 15,
        'feel': 'cooling',
        'byWeather': false,
        'fridge': false,
        'tags': ['cheap', 'healthy'],
      };
      final prefs = TodayPrefs.tryParse(json);
      expect(prefs.meal.scale, MealScale.tray);
      expect(prefs.meal.maxMinutes, 15);
      expect(prefs.meal.feel, DishFeel.cooling);
      expect(prefs.byWeather, false);
      expect(prefs.meal.fridge, false);
      expect(prefs.meal.tags, {RecipeTag.cheap, RecipeTag.healthy});
    });

    test('scale lạ → mặc định two', () {
      final prefs = TodayPrefs.tryParse({'scale': 'unknown'});
      expect(prefs.meal.scale, MealScale.two);
    });

    test('feel lạ → null', () {
      final prefs = TodayPrefs.tryParse({'scale': 'two', 'feel': 'unknown_feel'});
      expect(prefs.meal.feel, isNull);
    });

    test('tag lạ bị bỏ qua', () {
      final prefs = TodayPrefs.tryParse({
        'tags': ['cheap', 'nonexistent'],
      });
      expect(prefs.meal.tags, {RecipeTag.cheap});
    });

    test('dữ liệu hỏng → mặc định', () {
      expect(TodayPrefs.tryParse({'maxMinutes': 'not_a_number'}), isNotNull);
    });
  });

  group('TodayPrefs JSON round-trip', () {
    test('round-trip đầy đủ', () {
      const prefs = TodayPrefs(
        meal: MealPrefs(
          scale: MealScale.tray,
          maxMinutes: 15,
          feel: DishFeel.warming,
          fridge: false,
          tags: {RecipeTag.cheap, RecipeTag.mild},
        ),
        byWeather: false,
      );
      final json = jsonDecode(jsonEncode(prefs.toJson())) as Object?;
      final parsed = TodayPrefs.tryParse(json);
      expect(parsed, prefs);
    });

    test('round-trip mặc định', () {
      const prefs = TodayPrefs();
      final json = jsonDecode(jsonEncode(prefs.toJson())) as Object?;
      expect(TodayPrefs.tryParse(json), prefs);
    });
  });

  group('TodayPrefs.resolved', () {
    test('byWeather=true, thời tiết tắt → feel null', () {
      const prefs = TodayPrefs(byWeather: true);
      final result = prefs.resolved();
      expect(result.feel, isNull);
    });

    test('byWeather=true, thời tiết bật → feel từ weatherFeel', () {
      const prefs = TodayPrefs(byWeather: true);
      final result = prefs.resolved(weatherFeel: DishFeel.cooling);
      expect(result.feel, DishFeel.cooling);
    });

    test('byWeather=false → giữ feel cố định', () {
      const prefs = TodayPrefs(
        meal: MealPrefs(feel: DishFeel.warming),
        byWeather: false,
      );
      final result = prefs.resolved(weatherFeel: DishFeel.cooling);
      expect(result.feel, DishFeel.warming);
    });

    test('resolved giữ nguyên scale, maxMinutes, fridge, tags', () {
      const prefs = TodayPrefs(
        meal: MealPrefs(
          scale: MealScale.one,
          maxMinutes: 15,
          fridge: false,
          tags: {RecipeTag.cheap},
        ),
        byWeather: true,
      );
      final result = prefs.resolved();
      expect(result.scale, MealScale.one);
      expect(result.maxMinutes, 15);
      expect(result.fridge, false);
      expect(result.tags, {RecipeTag.cheap});
    });
  });

  group('TodayPrefs ==', () {
    test('bằng nhau', () {
      const a = TodayPrefs();
      const b = TodayPrefs();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('khác byWeather', () {
      const a = TodayPrefs(byWeather: true);
      const b = TodayPrefs(byWeather: false);
      expect(a, isNot(b));
    });
  });
}
