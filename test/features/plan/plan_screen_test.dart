import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/meal_slot.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

Recipe _recipe(String id, String name) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Future<List<Recipe>> Function()? recipes,
  String location = '/plan',
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...planTabRoutes,
      for (final path in ['/shopping', '/recipe/:id', '/meal-cook'])
        GoRoute(path: path, builder: (_, state) => Text('at ${state.uri}')),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      // Thứ Ba.
      nowProvider.overrideWithValue(DateTime(2026, 10, 20, 8)),
      recipesProvider.overrideWith(
        (ref) =>
            (recipes ??
            () async => [_recipe('trung', 'Trứng chiên hành'), _recipe('canh', 'Canh cà chua')])(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Navigator).first));

Finder _emptySlots() => find.byWidgetPredicate((w) => w is MealSlot && w.dishes.isEmpty);

void main() {
  testWidgets('hôm nay, 3 ô trống, 0/21; Đi chợ mở danh sách', (tester) async {
    await _pump(tester);

    expect(find.text('Thứ Ba · Hôm nay'), findsOneWidget);
    expect(find.text('Đã lên 0/21 bữa'), findsOneWidget);
    expect(_emptySlots(), findsNWidgets(3));

    await tester.tap(find.text(PlanStrings.shopping));
    await tester.pumpAndSettle();
    expect(find.text('at /shopping'), findsOneWidget);
  });

  testWidgets('chọn ngày khác thì đổi tiêu đề', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('T5'));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Năm'), findsOneWidget);
  });

  testWidgets('/plan?day= mở sẵn ngày đó; đổi ngày bằng go cũng chuyển theo', (tester) async {
    expect(planLocation(), '/plan');
    expect(planLocation(day: 3), '/plan?day=3');
    final container = await _pump(tester, location: planLocation(day: 3));
    expect(find.text('Thứ Năm'), findsOneWidget);

    final router = GoRouter.of(tester.element(find.byType(MealSlot).first));
    router.go(planLocation(day: 5));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Bảy'), findsOneWidget);

    // Ngày ngoài tuần thì bỏ qua, giữ ngày đang xem.
    router.go('/plan?day=9');
    await tester.pumpAndSettle();
    expect(find.text('Thứ Bảy'), findsOneWidget);
    expect(container.read(plannedMealsProvider), isEmpty);
  });

  testWidgets('goToPlanDay mở lại ngày đó dù URL không đổi và người dùng đã chọn ngày khác', (
    tester,
  ) async {
    await _pump(tester);
    final context = tester.element(find.byType(MealSlot).first);
    goToPlanDay(context, 3);
    await tester.pumpAndSettle();
    expect(find.text('Thứ Năm'), findsOneWidget);

    await tester.tap(find.text('T7'));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Bảy'), findsOneWidget);

    goToPlanDay(context, 3);
    await tester.pumpAndSettle();
    expect(find.text('Thứ Năm'), findsOneWidget);
  });

  testWidgets('thêm hai món vào một bữa từ sheet tìm, rồi xoá một món', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.text(MealSlot.addLabel).first);
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.pickTitle('Sáng')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'trung');
    await tester.pumpAndSettle();
    expect(find.text('Canh cà chua'), findsNothing);
    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MealSlot, 'Trứng chiên hành'), findsOneWidget);
    expect(find.text('Đã lên 1/21 bữa'), findsOneWidget);
    expect(_emptySlots(), findsNWidgets(2));

    // Bữa đã có món: link "+ Thêm món" trên dòng nhãn.
    await tester.tap(find.text('+ ${MealSlot.addLabel}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canh cà chua'));
    await tester.pumpAndSettle();
    expect(find.text('Sáng · 2 món'), findsOneWidget);
    expect(find.text('Đã lên 1/21 bữa'), findsOneWidget);
    expect(container.read(plannedMealsProvider).map((p) => p.recipeId), ['trung', 'canh']);

    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('Đổi món'), findsNothing);
    await tester.tap(find.text(PlanStrings.removeRecipe));
    await tester.pumpAndSettle();
    expect(find.text('Trứng chiên hành'), findsNothing);
    expect(find.text('Canh cà chua'), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(container.read(plannedMealsProvider).single.recipeId, 'canh');
  });

  testWidgets('bữa nhiều món có Nấu bữa này mở Nấu cả bữa; nấu xong thì Đã nấu', (tester) async {
    final container = await _pump(tester);
    final plan = container.read(plannedMealsProvider.notifier);
    final day = DateTime(2026, 10, 20);
    await plan.addToPlan('trung', day, Meal.lunch);
    await tester.pump();
    expect(find.text(PlanStrings.cookMeal), findsNothing);

    await plan.addToPlan('canh', day, Meal.lunch);
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        PlanStrings.cookMealLabel(Meal.lunch, ['Trứng chiên hành', 'Canh cà chua']),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(PlanStrings.cookMeal));
    await tester.pumpAndSettle();
    expect(find.text('at /meal-cook?day=2026-10-20&meal=lunch'), findsOneWidget);

    await plan.markCooked(day, Meal.lunch, ['trung', 'canh']);
    router(tester).pop();
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.cookMeal), findsNothing);
    expect(find.text(PlanStrings.cooked), findsOneWidget);

    // Bữa đã nấu vẫn nấu lại được.
    await tester.tap(find.bySemanticsLabel(PlanStrings.cookAgainLabel(Meal.lunch)));
    await tester.pumpAndSettle();
    expect(find.text('at /meal-cook?day=2026-10-20&meal=lunch'), findsOneWidget);
  });

  testWidgets('Xem món mở Chi tiết', (tester) async {
    final container = await _pump(tester);
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('trung', DateTime(2026, 10, 20), Meal.dinner);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlanStrings.viewRecipe));
    await tester.pumpAndSettle();
    expect(find.text('at /recipe/trung'), findsOneWidget);
  });

  testWidgets('dữ liệu lỗi thì hiện câu lỗi, vẫn đi chợ được', (tester) async {
    await _pump(tester, recipes: () => Future.error(const FormatException('hỏng')));

    expect(find.text(PlanStrings.loadError), findsOneWidget);
    expect(find.byType(MealSlot), findsNothing);
    expect(find.text(PlanStrings.shopping), findsOneWidget);
  });
}
