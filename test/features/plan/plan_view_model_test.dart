import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/domain/recipe_picker.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_view_model.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/recipe_picker_view_model.dart';

import '../../core/fake_analytics.dart';

Recipe _recipe(String id, {List<Meal> meals = const [], int minutes = 10}) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: meals,
  ingredients: const [],
  steps: const [],
);

final _recipes = [
  _recipe('a', minutes: 15),
  _recipe('b', meals: [Meal.breakfast]),
  _recipe('c', minutes: 25),
  _recipe('d'),
];

/// Thứ Ba 20/10/2026, 19h.
final _now = DateTime(2026, 10, 20, 19);
final _today = DateTime(2026, 10, 20);

/// Lần gọi gợi ý: bữa và món bị loại.
typedef _Call = ({Meal? meal, Set<String> exclude});

void main() {
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<PlanState>> sub;
  late FakeAnalytics analytics;
  late List<_Call> calls;

  /// Gợi ý lần lượt món đầu tiên chưa bị loại; [none] thì không gợi ý được gì.
  MealSuggester suggester({bool none = false}) => (prefs, {meal, exclude = const <String>{}}) {
    calls.add((meal: meal, exclude: {...exclude}));
    if (none) return null;
    final pick = _recipes.where((r) => !exclude.contains(r.id)).take(1).toList();
    if (pick.isEmpty) return null;
    return MealSuggestion(
      dishes: pick,
      scale: prefs.scale,
      totalMinutes: pick.first.minutes,
      availability: const Availability(),
      reasons: const [],
    );
  };

  void create({DateTime? now, bool noSuggestion = false}) {
    analytics = FakeAnalytics();
    calls = [];
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        nowProvider.overrideWithValue(now ?? _now),
        recipesProvider.overrideWith((ref) async => _recipes),
        analyticsProvider.overrideWithValue(analytics),
        mealSuggesterProvider.overrideWith((ref) async => suggester(none: noSuggestion)),
      ],
    );
    addTearDown(container.dispose);
    sub = container.listen(planViewModelProvider, (_, _) {});
  }

  Future<PlanState> loaded() async {
    await container.read(recipesProvider.future);
    return sub.read().requireValue;
  }

  PlanState read() => sub.read().requireValue;
  PlanViewModel viewModel() => container.read(planViewModelProvider.notifier);
  PlannedMealsController plan() => container.read(plannedMealsProvider.notifier);
  List<String> ids(Meal meal) => [for (final d in read().meals[meal]!) d.recipe.id];

  test('mặc định hôm nay, chế độ Ngày, 3 bữa trống, ngày trống', () async {
    create();
    final state = await loaded();
    expect(state.selectedDate, _today);
    expect(state.isToday, isTrue);
    expect(state.mode, PlanMode.day);
    expect(state.title, 'Thứ Ba, 20/10 · Hôm nay');
    expect(state.dayWord, 'nay');
    expect(state.meals.keys, Meal.values);
    expect(state.dayEmpty, isTrue);
    expect(state.summaries.values, everyElement('Chưa có món'));
    expect(state.metas.values, everyElement('Còn trống'));
  });

  group('bữa tâm điểm theo giờ hôm nay', () {
    for (final (hour, meal) in [(7, Meal.breakfast), (11, Meal.lunch), (18, Meal.dinner)]) {
      test('$hour giờ → ${meal.label}', () async {
        create(now: DateTime(2026, 10, 20, hour, 30));
        expect((await loaded()).focusMeal, meal);
      });
    }
  });

  test('ngày khác mở bữa đầu tiên có món; người dùng chọn thì giữ theo từng ngày', () async {
    create();
    await loaded();
    await plan().addToPlan('a', DateTime(2026, 10, 21), Meal.lunch);

    viewModel().next();
    expect(read().selectedDate, DateTime(2026, 10, 21));
    expect(read().isToday, isFalse);
    expect(read().title, 'Thứ Tư, 21/10');
    expect(read().focusMeal, Meal.lunch);

    viewModel().focus(Meal.dinner);
    expect(read().focusMeal, Meal.dinner);

    viewModel().previous();
    expect(read().focusMeal, Meal.dinner, reason: 'hôm nay 19h vẫn là Tối');
    viewModel().focus(Meal.breakfast);
    viewModel().next();
    expect(read().focusMeal, Meal.dinner, reason: 'giữ lựa chọn của Thứ Tư');
    viewModel().previous();
    expect(read().focusMeal, Meal.breakfast);
  });

  test('đổi ngày bằng lịch và mũi tên qua tuần, qua tháng; về hôm nay', () async {
    create();
    await loaded();

    viewModel().selectDate(DateTime(2026, 11, 2, 9), meal: Meal.dinner);
    expect(read().selectedDate, DateTime(2026, 11, 2));
    expect(read().focusMeal, Meal.dinner);
    expect(read().title, 'Thứ Hai, 2/11');

    viewModel().previous();
    expect(read().selectedDate, DateTime(2026, 11, 1));
    expect(read().dayWord, 'chủ nhật');

    viewModel().setMode(PlanMode.week);
    expect(read().title, 'Tuần 26/10 – 1/11');
    viewModel().previous();
    expect(read().selectedDate, DateTime(2026, 10, 25));
    expect(read().title, 'Tuần 19/10 – 25/10');

    viewModel().goToday();
    expect(read().selectedDate, _today);
    expect(read().mode, PlanMode.week);
  });

  test('thêm món vào ngày đang xem, nhãn tóm tắt, lưu lại', () async {
    create();
    await loaded();
    viewModel().selectDate(DateTime(2026, 10, 22));
    await viewModel().addDish(Meal.dinner, 'a');
    await viewModel().addDish(Meal.dinner, 'c');
    await viewModel().addDish(Meal.dinner, 'd');
    await viewModel().addDish(Meal.dinner, 'a');

    expect(ids(Meal.dinner), ['a', 'c', 'd']);
    expect(read().summaries[Meal.dinner], '3 món · 50 phút · a, c +1 món');
    expect(read().metas[Meal.dinner], '3 món · ~50 phút');
    expect(read().dayEmpty, isFalse);
    expect(analytics.events, ['plan_add', 'plan_add', 'plan_add']);
    expect(analytics.params.first, {'dishes': 1});
    expect(container.read(localStoreProvider).readString('plan.meals'), contains('2026-10-22'));
  });

  test('bỏ món rồi Hoàn tác: về đúng vị trí, giữ khẩu phần', () async {
    create();
    await loaded();
    await plan().addToPlan('a', _today, Meal.dinner);
    await plan().addToPlan('c', _today, Meal.dinner, servings: 3);
    await plan().addToPlan('d', _today, Meal.dinner);

    final removed = await viewModel().removeDish(Meal.dinner, 'c');
    expect(removed, isNotNull);
    expect(ids(Meal.dinner), ['a', 'd']);
    expect(analytics.events, ['plan_remove']);

    await viewModel().undoRemove(removed!);
    expect(ids(Meal.dinner), ['a', 'c', 'd']);
    expect(read().meals[Meal.dinner]![1].servings, 3);

    // Hoàn tác lần nữa không nhân đôi.
    await viewModel().undoRemove(removed);
    expect(ids(Meal.dinner), ['a', 'c', 'd']);
    expect(await viewModel().removeDish(Meal.lunch, 'a'), isNull);
  });

  test('đổi món giữ vị trí và khẩu phần; món mới đã có thì chỉ bỏ món cũ', () async {
    create();
    await loaded();
    await plan().addToPlan('a', _today, Meal.dinner);
    await plan().addToPlan('c', _today, Meal.dinner, servings: 2);
    await plan().addToPlan('d', _today, Meal.dinner);

    await viewModel().swapDish(Meal.dinner, 'c', 'b');
    expect(ids(Meal.dinner), ['a', 'b', 'd']);
    expect(read().meals[Meal.dinner]![1].servings, 2);

    await viewModel().swapDish(Meal.dinner, 'b', 'a');
    expect(ids(Meal.dinner), ['a', 'd']);
  });

  test('bữa đã nấu khi mọi món trong bữa đã nấu', () async {
    create();
    await plan().addToPlan('a', _now, Meal.dinner);
    await plan().addToPlan('c', _now, Meal.dinner);
    await plan().addToPlan('a', _now, Meal.lunch);
    expect((await loaded()).cookedMeals, isEmpty);

    await plan().markCooked(_now, Meal.dinner, ['a', 'c']);
    expect(read().cookedMeals, {Meal.dinner});
  });

  test('món không còn trong dữ liệu bị bỏ khỏi bữa', () async {
    create();
    await loaded();
    await plan().addToPlan('mon-cu', _today, Meal.dinner);
    await plan().addToPlan('a', _today, Meal.dinner);
    expect(ids(Meal.dinner), ['a']);
  });

  test('Gợi ý cho ngày này: lấp bữa trống, không lặp món trong ngày', () async {
    create();
    await loaded();
    await plan().addToPlan('a', _today, Meal.lunch);

    expect(await viewModel().suggestDay(), 2);
    expect(ids(Meal.breakfast), ['b']);
    expect(ids(Meal.lunch), ['a']);
    expect(ids(Meal.dinner), ['c']);
    expect(calls.map((c) => c.meal), [Meal.breakfast, Meal.dinner]);
    expect(calls.map((c) => c.exclude), [
      {'a'},
      {'a', 'b'},
    ]);
    expect(analytics.events, ['plan_add']);
    expect(analytics.params.single, {'dishes': 2});
  });

  test('Gợi ý món cho một bữa; không có gợi ý thì trả 0, không ghi gì', () async {
    create();
    await loaded();
    await plan().addToPlan('a', _today, Meal.breakfast);
    expect(await viewModel().suggestMeal(Meal.dinner), 1);
    expect(ids(Meal.dinner), ['b']);

    create(noSuggestion: true);
    await loaded();
    expect(await viewModel().suggestMeal(Meal.dinner), 0);
    expect(read().dayEmpty, isTrue);
    expect(analytics.events, isEmpty);
  });

  test('picker: món đã lưu mới lưu trước, tìm theo tên', () async {
    create();
    final picker = container.listen(recipePickerViewModelProvider(Meal.breakfast), (_, _) {});
    await loaded();
    await container.read(savedIdsProvider.notifier).toggle('a');
    await container.read(savedIdsProvider.notifier).toggle('c');

    PickerSections sections = picker.read().requireValue;
    expect(sections.saved.map((r) => r.id), ['c', 'a']);
    expect(sections.all.map((r) => r.id), ['b', 'd']);

    container.read(recipePickerViewModelProvider(Meal.breakfast).notifier).search('A');
    sections = picker.read().requireValue;
    expect(sections.saved.map((r) => r.id), ['a']);
    expect(sections.all, isEmpty);
  });
}
