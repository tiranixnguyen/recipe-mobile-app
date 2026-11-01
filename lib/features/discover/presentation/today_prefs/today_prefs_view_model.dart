import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/today_prefs.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

@immutable
class TodayPrefsState {
  const TodayPrefsState({
    required this.prefs,
    this.moreOpen = false,
    this.weatherEnabled = false,
  });

  final TodayPrefs prefs;

  /// true khi người dùng mở nhóm "Thêm tiêu chí".
  final bool moreOpen;

  /// true khi tính năng thời tiết (#115) đã bật. Hiện luôn false.
  final bool weatherEnabled;

  /// Số tag đang chọn; dùng cho nhãn "Thêm tiêu chí (n)".
  int get pickedTags => prefs.meal.tags.length;

  TodayPrefsState copyWith({
    TodayPrefs? prefs,
    bool? moreOpen,
    bool? weatherEnabled,
  }) => TodayPrefsState(
    prefs: prefs ?? this.prefs,
    moreOpen: moreOpen ?? this.moreOpen,
    weatherEnabled: weatherEnabled ?? this.weatherEnabled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayPrefsState &&
          other.prefs == prefs &&
          other.moreOpen == moreOpen &&
          other.weatherEnabled == weatherEnabled;

  @override
  int get hashCode => Object.hash(prefs, moreOpen, weatherEnabled);
}

/// ViewModel của màn TodayPrefs. Giữ bản nháp cho đến khi người dùng bấm nút chính.
class TodayPrefsViewModel extends Notifier<TodayPrefsState> {
  @override
  TodayPrefsState build() {
    final prefs = ref.read(todayPrefsProvider);
    return TodayPrefsState(
      prefs: prefs,
      moreOpen: false,
      weatherEnabled: false, // TODO(#115): bật khi thời tiết được triển khai
    );
  }

  void setScale(MealScale scale) {
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: scale,
          maxMinutes: state.prefs.meal.maxMinutes,
          feel: state.prefs.meal.feel,
          fridge: state.prefs.meal.fridge,
          tags: state.prefs.meal.tags,
        ),
        byWeather: state.prefs.byWeather,
      ),
    );
  }

  void setMinutes(int? minutes) {
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: state.prefs.meal.scale,
          maxMinutes: minutes,
          feel: state.prefs.meal.feel,
          fridge: state.prefs.meal.fridge,
          tags: state.prefs.meal.tags,
        ),
        byWeather: state.prefs.byWeather,
      ),
    );
  }

  void pickWeather() {
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: state.prefs.meal.scale,
          maxMinutes: state.prefs.meal.maxMinutes,
          feel: null,
          fridge: state.prefs.meal.fridge,
          tags: state.prefs.meal.tags,
        ),
        byWeather: true,
      ),
    );
  }

  void pickFeel(DishFeel feel) {
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: state.prefs.meal.scale,
          maxMinutes: state.prefs.meal.maxMinutes,
          feel: feel,
          fridge: state.prefs.meal.fridge,
          tags: state.prefs.meal.tags,
        ),
        byWeather: false,
      ),
    );
  }

  void toggleFridge() {
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: state.prefs.meal.scale,
          maxMinutes: state.prefs.meal.maxMinutes,
          feel: state.prefs.meal.feel,
          fridge: !state.prefs.meal.fridge,
          tags: state.prefs.meal.tags,
        ),
        byWeather: state.prefs.byWeather,
      ),
    );
  }

  void toggleTag(RecipeTag tag) {
    final tags = Set<RecipeTag>.from(state.prefs.meal.tags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(
      prefs: TodayPrefs(
        meal: MealPrefs(
          scale: state.prefs.meal.scale,
          maxMinutes: state.prefs.meal.maxMinutes,
          feel: state.prefs.meal.feel,
          fridge: state.prefs.meal.fridge,
          tags: tags,
        ),
        byWeather: state.prefs.byWeather,
      ),
    );
  }

  void toggleMore() {
    state = state.copyWith(moreOpen: !state.moreOpen);
  }

  /// Lưu lựa chọn vào store. Chỉ gọi khi người dùng bấm nút chính.
  Future<void> submit() async {
    await ref.read(todayPrefsProvider.notifier).save(state.prefs);
  }
}

final todayPrefsViewModelProvider =
    NotifierProvider.autoDispose<TodayPrefsViewModel, TodayPrefsState>(
      TodayPrefsViewModel.new,
    );
