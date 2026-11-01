import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class Events implements Analytics {
  final records = <(String, Map<String, Object>?)>[];
  @override
  void track(String event, [Map<String, Object>? params]) => records.add((event, params));
}

Recipe dish(String id, DishRole role, {int minutes = 10, int servings = 1}) => Recipe(
  id: id,
  name: 'Món $id',
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: servings,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
  role: role,
);

MealSuggestion suggestion(List<Recipe> dishes, {String? note}) {
  final total = dishes.fold(0, (sum, d) => sum + d.minutes);
  return MealSuggestion(
    dishes: dishes,
    scale: MealScale.two,
    totalMinutes: total,
    availability: const Availability(),
    reasons: ['Đủ đồ', 'Dùng nốt trứng', '~$total phút'],
    relaxedNote: note,
  );
}

final a1 = dish('a1', DishRole.main, servings: 2);
final a2 = dish('a2', DishRole.soup);
final b1 = dish('b1', DishRole.main);
final b2 = dish('b2', DishRole.soup);
final c1 = dish('c1', DishRole.main);
final c2 = dish('c2', DishRole.side);
final mealA = suggestion([a1, a2]);
final mealB = suggestion([b1, b2]);
final mealC = suggestion([c1, c2]);

/// Bữa đầu tiên không dùng món nào bị loại; hết thì trả [fallback] (bữa đã nới tiêu chí).
MealSuggester fakeSuggester(
  List<MealSuggestion> meals, {
  MealSuggestion? fallback,
  List<MealPrefs>? calls,
}) => (prefs, {meal, exclude = const <String>{}}) {
  calls?.add(prefs);
  return meals.where((m) => m.dishes.every((d) => !exclude.contains(d.id))).firstOrNull ?? fallback;
};

void expectEvent((String, Map<String, Object>?) record, String name, Map<String, Object> params) {
  expect(record.$1, name);
  expect(record.$2, params);
}

void main() {
  late Events events;
  late InMemoryLocalStore store;

  Future<ProviderContainer> setUp(
    MealSuggester suggester, {
    List<Recipe> ranked = const [],
    TodayPrefs? prefs,
  }) async {
    events = Events();
    store = InMemoryLocalStore();
    if (prefs != null) await store.writeString('discover.todayPrefs', jsonEncode(prefs.toJson()));
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(events),
        todayClockProvider.overrideWithValue(() => DateTime(2026, 11, 1, 18, 30)),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        mealSuggesterProvider.overrideWith((ref) async => suggester),
        suggestionsProvider.overrideWith((ref, args) async => ranked),
      ],
    );
    addTearDown(container.dispose);
    container.listen(todayViewModelProvider, (_, _) {});
    container.listen(todayMealsProvider, (_, _) {});
    await container.read(mealSuggesterProvider.future);
    await container.read(ingredientsProvider.future);
    return container;
  }

  TodayMeals meals(ProviderContainer c) => c.read(todayMealsProvider).requireValue;
  List<String> mainIds(ProviderContainer c) => meals(c).main!.ids;
  TodayViewModel vm(ProviderContainer c) => c.read(todayViewModelProvider.notifier);

  test('đọc tiêu chí đã lưu, bữa tối theo giờ, today_suggest một lần', () async {
    final calls = <MealPrefs>[];
    final c = await setUp(
      fakeSuggester([mealA, mealB, mealC], calls: calls),
      prefs: const TodayPrefs(
        byWeather: false,
        meal: MealPrefs(scale: MealScale.tray, feel: DishFeel.cooling),
      ),
    );
    expect(c.read(todayViewModelProvider).meal, Meal.dinner);
    expect(mainIds(c), ['a1', 'a2']);
    expect(meals(c).alternatives.map((m) => m.ids), [
      ['b1', 'b2'],
      ['c1', 'c2'],
    ]);
    expect(calls.first.scale, MealScale.tray);
    expect(calls.first.feel, DishFeel.cooling);

    vm(c).suggested();
    vm(c).suggested();
    expect(events.records, hasLength(1));
    expectEvent(events.records.single, 'today_suggest', {'scale': 'two', 'dishes': 2});
  });

  test('Theo thời tiết khi chưa bật thì không lọc cảm giác', () async {
    final calls = <MealPrefs>[];
    final c = await setUp(
      fakeSuggester([mealA], calls: calls),
      prefs: const TodayPrefs(byWeather: true, meal: MealPrefs(feel: DishFeel.warming)),
    );
    meals(c);
    expect(calls.first.feel, isNull);
  });

  test('đổi cả bữa bỏ qua món đã xem, hết bữa hợp tiêu chí thì quay vòng', () async {
    final c = await setUp(
      fakeSuggester([mealA, mealB, mealC], fallback: suggestion([a1], note: 'Đã nới.')),
    );
    vm(c).shuffle();
    expect(mainIds(c), ['b1', 'b2']);
    expect(c.read(todayViewModelProvider).skipped, {'a1', 'a2'});
    expect(meals(c).alternatives.map((m) => m.ids), [
      ['c1', 'c2'],
    ]);
    vm(c).shuffle();
    expect(mainIds(c), ['c1', 'c2']);
    expect(meals(c).alternatives, isEmpty);
    // Bỏ tiếp thì phải nới tiêu chí: coi như hết, quay về bữa đầu.
    vm(c).shuffle();
    expect(mainIds(c), ['a1', 'a2']);
    expect(c.read(todayViewModelProvider).skipped, isEmpty);
    expect(meals(c).relaxedNote, isNull);
  });

  test('đổi tiêu chí thì gợi ý lại từ đầu', () async {
    final c = await setUp(fakeSuggester([mealA, mealB, mealC]));
    vm(c).shuffle();
    await vm(c).swapDish(0);
    vm(c).toggleReasons();
    await c
        .read(todayPrefsProvider.notifier)
        .save(const TodayPrefs(meal: MealPrefs(scale: MealScale.one)));
    final state = c.read(todayViewModelProvider);
    expect(state.skipped, isEmpty);
    expect(state.swaps, isEmpty);
    expect(state.showReasons, isFalse);
    expect(mainIds(c), ['a1', 'a2']);
  });

  test('chọn Hoặc thử thứ hai thì bữa đó thành bữa chính', () async {
    final c = await setUp(fakeSuggester([mealA, mealB, mealC]));
    vm(c).pickAlt(1);
    expect(mainIds(c), ['c1', 'c2']);
    vm(c).pickAlt(5);
    expect(mainIds(c), ['c1', 'c2']);
  });

  test('câu nới tiêu chí lấy từ bữa gợi ý', () async {
    final c = await setUp(
      fakeSuggester([
        suggestion([a1], note: 'Đã bỏ tiêu chí Tiết kiệm.'),
      ]),
    );
    expect(meals(c).relaxedNote, 'Đã bỏ tiêu chí Tiết kiệm.');
  });

  test('không có bữa nào thì main null', () async {
    final c = await setUp(fakeSuggester(const []));
    expect(meals(c).main, isNull);
    vm(c).shuffle();
    vm(c).suggested();
    expect(events.records, isEmpty);
  });

  test('đổi một món: cùng vai, tính lại phút và lý do, đổi bữa thì bỏ', () async {
    final egg = dish('egg', DishRole.main, minutes: 20);
    final tofu = dish('tofu', DishRole.main, minutes: 5);
    final c = await setUp(
      fakeSuggester([mealA, mealB]),
      ranked: [a1, a2, egg, b2, tofu],
    );
    await vm(c).swapDish(0);
    expect(mainIds(c), ['egg', 'a2']);
    expect(meals(c).main!.totalMinutes, 30);
    expect(meals(c).main!.reasons, ['Đủ đồ', '~30 phút']);
    await vm(c).swapDish(0);
    expect(mainIds(c), ['tofu', 'a2']);
    // Hết ứng viên thì quay vòng về món đầu chưa có trong bữa.
    await vm(c).swapDish(0);
    expect(mainIds(c), ['a1', 'a2']);

    await vm(c).swapDish(0);
    vm(c).shuffle();
    expect(mainIds(c), ['b1', 'b2']);
    expect(c.read(todayViewModelProvider).swaps, isEmpty);
  });

  test('Không hợp: chê mọi món của bữa, ghi lý do, đóng danh sách', () async {
    final c = await setUp(fakeSuggester([mealA, mealB]));
    vm(c).toggleReasons();
    expect(c.read(todayViewModelProvider).showReasons, isTrue);
    await vm(c).dislike(DislikeReason.tooLong);
    final disliked = c.read(dislikedProvider);
    expect(disliked.keys, containsAll(['a1', 'a2']));
    expect(disliked['a1']?.reason, DislikeReason.tooLong);
    expectEvent(events.records.last, 'today_dislike', {'reason': 'tooLong'});
    expect(c.read(todayViewModelProvider).showReasons, isFalse);
  });

  test('Lưu lại / bỏ lưu, đổi món hay đổi bữa thì về chưa lưu', () async {
    final egg = dish('egg', DishRole.main);
    final c = await setUp(
      fakeSuggester([mealA, mealB]),
      ranked: [egg],
      prefs: const TodayPrefs(meal: MealPrefs(tags: {RecipeTag.party, RecipeTag.cheap})),
    );
    expect(meals(c).isSaved, isFalse);
    expect(await vm(c).toggleSave(), isTrue);
    expect(meals(c).isSaved, isTrue);
    final saved = c.read(savedMealsProvider).single;
    expect(saved.recipeIds, ['a1', 'a2']);
    expect(saved.servings, 2);
    expect(saved.tags, [RecipeTag.cheap, RecipeTag.party]);
    expectEvent(events.records.last, 'save_meal', {'dishes': 2, 'tags': 2});

    await vm(c).swapDish(0);
    expect(meals(c).isSaved, isFalse);
    vm(c).shuffle();
    expect(meals(c).isSaved, isFalse);
    vm(c).shuffle();
    expect(mainIds(c), ['a1', 'a2']);
    expect(meals(c).isSaved, isTrue);

    expect(await vm(c).toggleSave(), isFalse);
    expect(c.read(savedMealsProvider), isEmpty);
    expect(meals(c).isSaved, isFalse);
  });

  test('Thêm vào thực đơn: ghi add_meal_to_plan khi thêm được', () async {
    final c = await setUp(fakeSuggester([mealA]));
    List<Recipe>? shown;
    await vm(c).addToPlan((dishes) async {
      shown = dishes;
      return false;
    });
    expect(shown, [a1, a2]);
    expect(events.records, isEmpty);
    await vm(c).addToPlan((_) async => true);
    expectEvent(events.records.single, 'add_meal_to_plan', {'dishes': 2});
  });
}
