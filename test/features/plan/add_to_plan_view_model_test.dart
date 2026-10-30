import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/presentation/add_to_plan/add_to_plan_view_model.dart';

import '../../core/fake_analytics.dart';

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
  _recipe('canh', 'Canh chua cà chua', servings: 2),
  _recipe('lau', 'Lẩu', servings: 8),
];

final _today = DateTime(2026, 10, 20);

void main() {
  late ProviderContainer container;
  late FakeAnalytics analytics;

  ProviderContainer create(DateTime now) {
    analytics = FakeAnalytics();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        nowProvider.overrideWithValue(now),
        recipesProvider.overrideWith((ref) async => _recipes),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderSubscription<AsyncValue<AddToPlanState>>> listen(List<String> ids) async {
    final sub = container.listen(addToPlanViewModelProvider(addToPlanKey(ids)), (_, _) {});
    await container.read(recipesProvider.future);
    return sub;
  }

  AddToPlanViewModel viewModel(List<String> ids) =>
      container.read(addToPlanViewModelProvider(addToPlanKey(ids)).notifier);

  group('17h Thứ Ba 20/10/2026', () {
    setUp(() => container = create(DateTime(2026, 10, 20, 17)));

    test('mặc định hôm nay, bữa tới theo giờ (Tối), khẩu phần chuẩn, bữa trống', () async {
      final state = (await listen(['trung'])).read().requireValue;

      expect(state.recipes.map((r) => r.id), ['trung']);
      expect(state.subline, 'Trứng chiên hành · 15 phút · Bếp từ');
      expect(state.date, _today);
      expect(state.meal, Meal.dinner);
      expect(state.servings, 1);
      expect(state.mealSummaries.values, everyElement('Trống'));
      expect(state.joinText, isNull);
      expect(state.confirmLabel, 'Thêm vào Tối nay');
    });

    test('7 ngày cuốn từ hôm nay, ô cuối là thứ Hai tuần sau', () async {
      final sub = await listen(['trung']);
      var state = sub.read().requireValue;
      expect(state.days.map((d) => d.short), ['T3', 'T4', 'T5', 'T6', 'T7', 'CN', 'T2']);
      expect(state.days.map((d) => d.label), [
        'Thứ Ba, hôm nay',
        'Thứ Tư, ngày mai',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ nhật',
        'Thứ Hai tuần sau',
      ]);
      expect(state.days.map((d) => d.selected), [true, false, false, false, false, false, false]);

      viewModel(['trung']).pickDay(state.days[6].date);
      viewModel(['trung']).pickMeal(Meal.breakfast);
      state = sub.read().requireValue;
      expect(state.date, DateTime(2026, 10, 26));
      expect(state.days.last.selected, isTrue);
      expect(state.confirmLabel, 'Thêm vào Sáng thứ Hai tuần sau');

      viewModel(['trung']).pickDay(state.days[1].date);
      viewModel(['trung']).pickMeal(Meal.lunch);
      expect(sub.read().requireValue.confirmLabel, 'Thêm vào Trưa mai');
    });

    test('khẩu phần chuẩn lớn hơn 6 thì kẹp về 6; chỉnh trong 1–6', () async {
      final sub = await listen(['lau']);
      expect(sub.read().requireValue.servings, 6);
      viewModel(['lau']).setServings(0);
      expect(sub.read().requireValue.servings, 1);
      viewModel(['lau']).setServings(3);
      expect(sub.read().requireValue.servings, 3);
    });

    test('bữa đã có món: tóm tắt tên, dòng "Sẽ thêm cùng"', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      await plan.addToPlan('com-rang', _today, Meal.lunch);
      await plan.addToPlan('dau-phu', _today, Meal.dinner);
      await plan.addToPlan('com-rang', _today, Meal.dinner);
      await plan.addToPlan('canh', _today, Meal.dinner);
      await plan.addToPlan('trung', DateTime(2026, 10, 22), Meal.breakfast);
      final sub = await listen(['trung']);

      var state = sub.read().requireValue;
      expect(state.mealSummaries, {
        Meal.breakfast: 'Trống',
        Meal.lunch: 'Cơm rang dưa cải',
        Meal.dinner: 'Đậu phụ sốt cà chua, Cơm rang dưa cải +1 món',
      });
      expect(
        state.joinText,
        'Sẽ thêm cùng Đậu phụ sốt cà chua, Cơm rang dưa cải +1 món · bữa này thành 4 món',
      );

      viewModel(['trung']).pickMeal(Meal.breakfast);
      expect(sub.read().requireValue.joinText, isNull);

      // Món đang thêm đã có trong bữa thì không tính lại.
      viewModel(['trung']).pickDay(DateTime(2026, 10, 22));
      state = sub.read().requireValue;
      expect(state.mealSummaries[Meal.breakfast], 'Trứng chiên hành');
      expect(state.joinText, isNull);
    });

    test('confirm nối món vào cuối bữa với khẩu phần đã chọn, trả ngày và bữa', () async {
      await container.read(plannedMealsProvider.notifier).addToPlan('dau-phu', _today, Meal.dinner);
      await listen(['trung']);

      viewModel(['trung']).setServings(2);
      final added = await viewModel(['trung']).confirm();

      expect(added, (date: _today, meal: Meal.dinner));
      expect(container.read(plannedMealsProvider), [
        PlannedMeal(day: _today, meal: Meal.dinner, recipeId: 'dau-phu'),
        PlannedMeal(day: _today, meal: Meal.dinner, recipeId: 'trung', servings: 2),
      ]);
      expect(analytics.events, ['plan_add']);
      expect(analytics.params.single, {'dishes': 1});
    });

    test('cả bữa: dòng phụ "A + B · 2 món", ghép bữa, thêm tất cả vào một bữa', () async {
      await container.read(plannedMealsProvider.notifier).addToPlan('dau-phu', _today, Meal.lunch);
      final ids = ['trung', 'canh'];
      final sub = await listen(ids);

      var state = sub.read().requireValue;
      expect(state.subline, 'Trứng chiên hành + Canh chua cà chua · 2 món');
      // Khẩu phần chuẩn lớn nhất trong các món.
      expect(state.servings, 2);
      expect(state.joinText, isNull);

      viewModel(ids).pickMeal(Meal.lunch);
      state = sub.read().requireValue;
      expect(state.joinText, 'Sẽ thêm cùng Đậu phụ sốt cà chua · bữa này thành 3 món');

      expect(await viewModel(ids).confirm(), (date: _today, meal: Meal.lunch));
      expect(container.read(plannedMealsProvider).map((p) => (p.meal, p.recipeId, p.servings)), [
        (Meal.lunch, 'dau-phu', 1),
        (Meal.lunch, 'trung', 2),
        (Meal.lunch, 'canh', 2),
      ]);
      expect(analytics.params.single, {'dishes': 2});
    });

    test('món không có trong dữ liệu thì lỗi', () async {
      final sub = await listen(['trung', 'mon-cu']);
      expect(sub.read().hasError, isTrue);
    });
  });

  for (final (hour, meal, label) in [
    (7, Meal.breakfast, 'Thêm vào Sáng nay'),
    (11, Meal.lunch, 'Thêm vào Trưa nay'),
    (22, Meal.dinner, 'Thêm vào Tối nay'),
  ]) {
    test('$hour giờ: mặc định ${meal.label} hôm nay', () async {
      container = create(DateTime(2026, 10, 20, hour, 30));
      final state = (await listen(['trung'])).read().requireValue;
      expect((state.date, state.meal), (_today, meal));
      expect(state.confirmLabel, label);
    });
  }
}
