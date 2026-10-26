import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/domain/recipe_picker.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_view_model.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/recipe_picker_view_model.dart';

Recipe _recipe(String id, {List<Meal> meals = const []}) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: meals,
  ingredients: const [],
  steps: const [],
);

/// Thứ Ba 20/10/2026, 19h.
final _now = DateTime(2026, 10, 20, 19);

void main() {
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<PlanState>> sub;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        nowProvider.overrideWithValue(_now),
        recipesProvider.overrideWith(
          (ref) async => [
            _recipe('a'),
            _recipe('b', meals: [Meal.breakfast]),
            _recipe('c'),
          ],
        ),
      ],
    );
    sub = container.listen(planViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<PlanState> loaded() async {
    await container.read(recipesProvider.future);
    return sub.read().requireValue;
  }

  PlanViewModel viewModel() => container.read(planViewModelProvider.notifier);

  test('mặc định là hôm nay, 3 ô trống, 0/21', () async {
    final state = await loaded();
    expect(state.selectedDay, 1);
    expect(state.today, 1);
    expect(state.selectedDate, DateTime(2026, 10, 20));
    expect(state.meals.keys, Meal.values);
    expect(state.meals.values, everyElement(isEmpty));
    expect(state.plannedCount, 0);
    expect(state.daysWithMeals, isEmpty);
  });

  test('thêm nhiều món vào một bữa, xoá một món, lưu lại', () async {
    await loaded();
    viewModel().selectDay(3);
    await viewModel().addDish(Meal.dinner, 'a');
    await viewModel().addDish(Meal.dinner, 'c');
    await viewModel().addDish(Meal.lunch, 'b');

    var state = sub.read().requireValue;
    expect(state.selectedDate, DateTime(2026, 10, 22));
    expect(state.meals[Meal.dinner]!.map((d) => d.recipe.id), ['a', 'c']);
    expect(state.meals[Meal.lunch]!.map((d) => d.recipe.id), ['b']);
    // Đếm bữa, không đếm món.
    expect(state.plannedCount, 2);
    expect(state.daysWithMeals, {3});

    await viewModel().removeDish(Meal.dinner, 'a');
    await viewModel().removeDish(Meal.lunch, 'b');
    state = sub.read().requireValue;
    expect(state.meals[Meal.dinner]!.map((d) => d.recipe.id), ['c']);
    expect(state.meals[Meal.lunch], isEmpty);
    expect(state.plannedCount, 1);

    expect(container.read(localStoreProvider).readString('plan.meals'), contains('2026-10-22'));
    container.invalidate(plannedMealsProvider);
    expect(sub.read().requireValue.meals[Meal.dinner]!.single.recipe.id, 'c');
  });

  test('thêm lại món đã có không nhân đôi, giữ khẩu phần', () async {
    await loaded();
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('a', DateTime(2026, 10, 20), Meal.dinner, servings: 3);
    await viewModel().addDish(Meal.dinner, 'a');

    final dishes = sub.read().requireValue.meals[Meal.dinner]!;
    expect(dishes.single.recipe.id, 'a');
    expect(dishes.single.servings, 3);
  });

  test('món không còn trong dữ liệu bị bỏ khỏi bữa', () async {
    await loaded();
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('mon-cu', DateTime(2026, 10, 20), Meal.dinner);
    await plan.addToPlan('a', DateTime(2026, 10, 20), Meal.dinner);

    expect(sub.read().requireValue.meals[Meal.dinner]!.map((d) => d.recipe.id), ['a']);
  });

  test('chỉ đếm món trong tuần này (T2 19/10 … CN 25/10)', () async {
    await loaded();
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('a', DateTime(2026, 10, 18), Meal.dinner);
    await plan.addToPlan('a', DateTime(2026, 10, 19), Meal.breakfast);
    await plan.addToPlan('a', DateTime(2026, 10, 25), Meal.dinner);
    await plan.addToPlan('c', DateTime(2026, 10, 25), Meal.dinner);
    await plan.addToPlan('a', DateTime(2026, 10, 26), Meal.dinner);

    final state = sub.read().requireValue;
    expect(state.plannedCount, 2);
    expect(state.daysWithMeals, {0, 6});
  });

  test('picker: món đã lưu mới lưu trước, tìm theo tên', () async {
    final picker = container.listen(recipePickerViewModelProvider(Meal.breakfast), (_, _) {});
    await loaded();
    await container.read(savedIdsProvider.notifier).toggle('a');
    await container.read(savedIdsProvider.notifier).toggle('c');

    PickerSections sections = picker.read().requireValue;
    expect(sections.saved.map((r) => r.id), ['c', 'a']);
    expect(sections.all.map((r) => r.id), ['b']);

    container.read(recipePickerViewModelProvider(Meal.breakfast).notifier).search('A');
    sections = picker.read().requireValue;
    expect(sections.saved.map((r) => r.id), ['a']);
    expect(sections.all, isEmpty);
  });
}
