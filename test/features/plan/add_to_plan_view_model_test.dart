import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/presentation/add_to_plan/add_to_plan_view_model.dart';

Recipe _recipe(String id, String name, {int servings = 1}) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: servings,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);

final _recipes = [
  _recipe('trung', 'Trứng chiên hành'),
  _recipe('dau-phu', 'Đậu phụ sốt cà chua'),
  _recipe('com-rang', 'Cơm rang dưa cải'),
  _recipe('lau', 'Lẩu', servings: 8),
];

void main() {
  late ProviderContainer container;

  ProviderContainer create(DateTime now) {
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        nowProvider.overrideWithValue(now),
        recipesProvider.overrideWith((ref) async => _recipes),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderSubscription<AsyncValue<AddToPlanState>>> listen(String id) async {
    final sub = container.listen(addToPlanViewModelProvider(id), (_, _) {});
    await container.read(recipesProvider.future);
    return sub;
  }

  AddToPlanViewModel viewModel(String id) =>
      container.read(addToPlanViewModelProvider(id).notifier);

  group('17h Thứ Ba 20/10/2026', () {
    setUp(() => container = create(DateTime(2026, 10, 20, 17)));

    test('mặc định bữa kế tiếp (Tối nay), khẩu phần chuẩn của món, bữa trống', () async {
      final sub = await listen('trung');
      final state = sub.read().requireValue;

      expect(state.recipe.id, 'trung');
      expect(state.today, 1);
      expect(state.day, 1);
      expect(state.meal, Meal.dinner);
      expect(state.servings, 1);
      expect(state.quickPicks.map((q) => (q.label, q.selected)), [
        ('Tối nay', true),
        ('Sáng mai', false),
        ('Trưa mai', false),
      ]);
      expect(state.mealSummaries.values, everyElement('Trống'));
      expect(state.joinText, isNull);
      expect(state.confirmLabel, 'Thêm vào Tối nay');
      expect(state.daysWithMeals, isEmpty);
    });

    test('khẩu phần chuẩn lớn hơn 6 thì kẹp về 6; chỉnh trong 1–6', () async {
      final sub = await listen('lau');
      expect(sub.read().requireValue.servings, 6);

      viewModel('lau').setServings(0);
      expect(sub.read().requireValue.servings, 1);
      viewModel('lau').setServings(3);
      expect(sub.read().requireValue.servings, 3);
    });

    test('chip nhanh, chọn ngày và bữa đổi nhãn nút và chip đang bật', () async {
      final sub = await listen('trung');

      viewModel('trung').pickQuick(sub.read().requireValue.quickPicks[2]);
      var state = sub.read().requireValue;
      expect((state.day, state.meal), (2, Meal.lunch));
      expect(state.confirmLabel, 'Thêm vào Trưa mai');
      expect(state.quickPicks.map((q) => q.selected), [false, false, true]);

      viewModel('trung').pickDay(3);
      viewModel('trung').pickMeal(Meal.breakfast);
      state = sub.read().requireValue;
      expect(state.confirmLabel, 'Thêm vào Sáng thứ Năm');
      expect(state.quickPicks.map((q) => q.selected), everyElement(isFalse));

      viewModel('trung').pickDay(6);
      viewModel('trung').pickMeal(Meal.dinner);
      expect(sub.read().requireValue.confirmLabel, 'Thêm vào Tối Chủ nhật');
    });

    test('bữa đã có món: tên món trong bữa, chấm ngày, dòng "Sẽ thêm cùng"', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      await plan.addToPlan('com-rang', DateTime(2026, 10, 20), Meal.lunch);
      await plan.addToPlan('dau-phu', DateTime(2026, 10, 20), Meal.dinner);
      await plan.addToPlan('com-rang', DateTime(2026, 10, 20), Meal.dinner);
      await plan.addToPlan('trung', DateTime(2026, 10, 22), Meal.breakfast);
      // Tuần sau không có chấm.
      await plan.addToPlan('trung', DateTime(2026, 10, 27), Meal.breakfast);
      final sub = await listen('trung');

      var state = sub.read().requireValue;
      expect(state.daysWithMeals, {1, 3});
      expect(state.mealSummaries, {
        Meal.breakfast: 'Trống',
        Meal.lunch: 'Cơm rang dưa cải',
        Meal.dinner: 'Đậu phụ sốt cà chua, Cơm rang dưa cải',
      });
      expect(
        state.joinText,
        'Sẽ thêm cùng Đậu phụ sốt cà chua, Cơm rang dưa cải · bữa này thành 3 món',
      );

      viewModel('trung').pickMeal(Meal.breakfast);
      expect(sub.read().requireValue.joinText, isNull);

      // Món đang thêm đã có trong bữa thì không tính lại.
      viewModel('trung').pickDay(3);
      state = sub.read().requireValue;
      expect(state.mealSummaries[Meal.breakfast], 'Trứng chiên hành');
      expect(state.joinText, isNull);
    });

    test('confirm nối món vào cuối bữa với khẩu phần đã chọn', () async {
      await container
          .read(plannedMealsProvider.notifier)
          .addToPlan('dau-phu', DateTime(2026, 10, 20), Meal.dinner);
      await listen('trung');

      viewModel('trung').setServings(2);
      await viewModel('trung').confirm();

      expect(container.read(plannedMealsProvider), [
        PlannedMeal(day: DateTime(2026, 10, 20), meal: Meal.dinner, recipeId: 'dau-phu'),
        PlannedMeal(
          day: DateTime(2026, 10, 20),
          meal: Meal.dinner,
          recipeId: 'trung',
          servings: 2,
        ),
      ]);
    });

    test('món không có trong dữ liệu thì lỗi', () async {
      final sub = await listen('mon-cu');
      expect(sub.read().hasError, isTrue);
    });
  });

  test('8h: chip là ba bữa hôm nay, mặc định Sáng nay', () async {
    container = create(DateTime(2026, 10, 20, 8));
    final state = (await listen('trung')).read().requireValue;
    expect(state.quickPicks.map((q) => q.label), ['Sáng nay', 'Trưa nay', 'Tối nay']);
    expect(state.confirmLabel, 'Thêm vào Sáng nay');
  });

  test('22h: bữa tối đã qua, chip là ba bữa ngày mai', () async {
    container = create(DateTime(2026, 10, 20, 22));
    final state = (await listen('trung')).read().requireValue;
    expect(state.quickPicks.map((q) => q.label), ['Sáng mai', 'Trưa mai', 'Tối mai']);
    expect((state.day, state.meal), (2, Meal.breakfast));
  });

  test('Chủ nhật: ẩn bữa sang tuần sau', () async {
    container = create(DateTime(2026, 10, 25, 17));
    final state = (await listen('trung')).read().requireValue;
    expect(state.today, 6);
    expect(state.quickPicks.map((q) => q.label), ['Tối nay']);
  });

  test('tối Chủ nhật đã qua bữa tối: không có chip, mặc định Tối nay', () async {
    container = create(DateTime(2026, 10, 25, 22));
    final state = (await listen('trung')).read().requireValue;
    expect(state.quickPicks, isEmpty);
    expect(state.confirmLabel, 'Thêm vào Tối nay');
  });
}
