import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

const _todayPrefsKey = 'discover.todayPrefs';

/// Tiêu chí người dùng chọn ở màn Gợi ý cho mình (TodayPrefs), lưu vào LocalStore.
///
/// Trước khi gọi [suggestMeal], Today (#117) gọi [resolved] để quy "Theo thời tiết" ra [DishFeel].
@immutable
class TodayPrefs {
  const TodayPrefs({
    this.meal = const MealPrefs(),
    this.byWeather = false,
  });

  /// Tiêu chí bữa ăn (quy mô, thời gian, cảm giác, tag).
  final MealPrefs meal;

  /// true = Theo thời tiết (feel phụ thuộc thời tiết thực tế, #115). Mặc định tắt: thời tiết chỉ
  /// chạy khi người dùng tự bật.  false và `meal.feel == null` là "Tuỳ bạn".
  final bool byWeather;

  /// Trả [MealPrefs] đã quy "Theo thời tiết" ra feel.
  ///
  /// [weatherFeel] là cảm giác từ thời tiết thực (#115); null khi tính năng chưa bật.
  MealPrefs resolved({DishFeel? weatherFeel}) {
    if (!byWeather) return meal;
    // Khi byWeather nhưng thời tiết chưa bật → feel = null (Tuỳ bạn).
    return MealPrefs(
      scale: meal.scale,
      maxMinutes: meal.maxMinutes,
      feel: weatherFeel,
      fridge: meal.fridge,
      tags: meal.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'scale': meal.scale.name,
    'maxMinutes': meal.maxMinutes,
    'feel': meal.feel?.id,
    'byWeather': byWeather,
    'fridge': meal.fridge,
    'tags': [for (final t in meal.tags) t.id],
  };

  static TodayPrefs tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return const TodayPrefs();
    try {
      final scale = MealScale.values.firstWhere(
        (s) => s.name == json['scale'],
        orElse: () => MealScale.two,
      );
      // null là "Thong thả" (đã lưu); chỉ khi thiếu khoá hoặc sai kiểu mới về mặc định 30.
      final maxMinutes = switch (json['maxMinutes']) {
        final int v => v,
        null when json.containsKey('maxMinutes') => null,
        _ => 30,
      };
      final feel = json['feel'] is String ? DishFeel.tryParse(json['feel'] as String) : null;
      final byWeather = json['byWeather'] == true;
      final fridge = json['fridge'] != false;
      final rawTags = json['tags'];
      final tags = <RecipeTag>{
        if (rawTags is List)
          for (final t in rawTags)
            if (t is String)
              ...switch (RecipeTag.tryParse(t)) {
                final tag? => [tag],
                _ => <RecipeTag>[],
              },
      };
      return TodayPrefs(
        meal: MealPrefs(
          scale: scale,
          maxMinutes: maxMinutes,
          feel: feel,
          fridge: fridge,
          tags: tags,
        ),
        byWeather: byWeather,
      );
    } catch (_) {
      return const TodayPrefs();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayPrefs && other.meal == meal && other.byWeather == byWeather;

  @override
  int get hashCode => Object.hash(meal, byWeather);
}

/// Controller lưu/đọc [TodayPrefs] từ LocalStore.
class TodayPrefsController extends Notifier<TodayPrefs> {
  @override
  TodayPrefs build() {
    final raw = ref.watch(localStoreProvider).readString(_todayPrefsKey);
    if (raw == null) return const TodayPrefs();
    try {
      return TodayPrefs.tryParse(jsonDecode(raw) as Object?);
    } catch (_) {
      return const TodayPrefs();
    }
  }

  Future<void> save(TodayPrefs prefs) async {
    state = prefs;
    await ref.read(localStoreProvider).writeString(_todayPrefsKey, jsonEncode(prefs.toJson()));
  }
}

/// Tiêu chí gợi ý hôm nay; Today (#117) đọc và gọi [TodayPrefs.resolved] trước khi gợi ý.
final todayPrefsProvider = NotifierProvider<TodayPrefsController, TodayPrefs>(
  TodayPrefsController.new,
);
