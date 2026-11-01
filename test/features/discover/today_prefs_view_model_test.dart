import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/data/today_prefs.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today_prefs/today_prefs_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

ProviderContainer _makeContainer({InMemoryLocalStore? store}) {
  final s = store ?? InMemoryLocalStore();
  return ProviderContainer(overrides: [localStoreProvider.overrideWithValue(s)]);
}

void main() {
  group('TodayPrefsViewModel mặc định', () {
    test('state mặc định đúng prototype', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final state = c.read(todayPrefsViewModelProvider);
      expect(state.prefs.meal.scale, MealScale.two);
      expect(state.prefs.meal.maxMinutes, 30);
      expect(state.prefs.byWeather, isTrue);
      expect(state.prefs.meal.fridge, isTrue);
      expect(state.prefs.meal.tags, isEmpty);
      expect(state.moreOpen, isFalse);
      expect(state.weatherEnabled, isFalse);
    });
  });

  group('setScale', () {
    test('đổi quy mô', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).setScale(MealScale.one);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.scale, MealScale.one);
    });
  });

  group('setMinutes', () {
    test('đặt 15 phút', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).setMinutes(15);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.maxMinutes, 15);
    });

    test('đặt null (Thong thả)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).setMinutes(null);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.maxMinutes, isNull);
    });
  });

  group('pickWeather / pickFeel', () {
    test('pickWeather → byWeather true', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      vm.pickFeel(DishFeel.cooling); // chọn cố định trước
      vm.pickWeather();
      final state = c.read(todayPrefsViewModelProvider);
      expect(state.prefs.byWeather, isTrue);
    });

    test('pickFeel cooling → byWeather false, feel cooling', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).pickFeel(DishFeel.cooling);
      final state = c.read(todayPrefsViewModelProvider);
      expect(state.prefs.byWeather, isFalse);
      expect(state.prefs.meal.feel, DishFeel.cooling);
    });

    test('pickFeel warming', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).pickFeel(DishFeel.warming);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.feel, DishFeel.warming);
    });
  });

  group('toggleFridge', () {
    test('tắt/bật fridge', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.fridge, isTrue);
      vm.toggleFridge();
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.fridge, isFalse);
      vm.toggleFridge();
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.fridge, isTrue);
    });
  });

  group('toggleTag', () {
    test('thêm tag', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).toggleTag(RecipeTag.cheap);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.tags, {RecipeTag.cheap});
    });

    test('bỏ tag đã chọn', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      vm.toggleTag(RecipeTag.cheap);
      vm.toggleTag(RecipeTag.cheap);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.tags, isEmpty);
    });

    test('chọn nhiều tag', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      vm.toggleTag(RecipeTag.cheap);
      vm.toggleTag(RecipeTag.healthy);
      expect(c.read(todayPrefsViewModelProvider).prefs.meal.tags, {
        RecipeTag.cheap,
        RecipeTag.healthy,
      });
    });

    test('pickedTags đếm đúng', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      expect(c.read(todayPrefsViewModelProvider).pickedTags, 0);
      vm.toggleTag(RecipeTag.cheap);
      vm.toggleTag(RecipeTag.mild);
      expect(c.read(todayPrefsViewModelProvider).pickedTags, 2);
    });
  });

  group('toggleMore', () {
    test('mở/đóng more panel', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      expect(c.read(todayPrefsViewModelProvider).moreOpen, isFalse);
      vm.toggleMore();
      expect(c.read(todayPrefsViewModelProvider).moreOpen, isTrue);
      vm.toggleMore();
      expect(c.read(todayPrefsViewModelProvider).moreOpen, isFalse);
    });
  });

  group('submit', () {
    test('trước submit, store chưa có gì', () async {
      final store = InMemoryLocalStore();
      final c = _makeContainer(store: store);
      addTearDown(c.dispose);
      c.read(todayPrefsViewModelProvider.notifier).setScale(MealScale.one);
      // Chưa submit → store rỗng
      expect(store.readString('discover.todayPrefs'), isNull);
    });

    test('sau submit, container mới đọc lại đúng', () async {
      final store = InMemoryLocalStore();
      final c = _makeContainer(store: store);
      addTearDown(c.dispose);
      final vm = c.read(todayPrefsViewModelProvider.notifier);
      vm.setScale(MealScale.tray);
      vm.setMinutes(15);
      vm.pickFeel(DishFeel.cooling);
      vm.toggleTag(RecipeTag.cheap);
      await vm.submit();

      // Container mới với cùng store
      final c2 = _makeContainer(store: store);
      addTearDown(c2.dispose);
      final loaded = c2.read(todayPrefsProvider);
      expect(loaded.meal.scale, MealScale.tray);
      expect(loaded.meal.maxMinutes, 15);
      expect(loaded.meal.feel, DishFeel.cooling);
      expect(loaded.meal.tags, {RecipeTag.cheap});
      expect(loaded.byWeather, isFalse);
    });

    test('weatherEnabled luôn false (chưa có #115)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(c.read(todayPrefsViewModelProvider).weatherEnabled, isFalse);
    });
  });
}
