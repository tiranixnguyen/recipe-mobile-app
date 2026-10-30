import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
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

final _recipes = [
  _recipe('trung', 'Trứng chiên hành'),
  _recipe('canh', 'Canh cà chua'),
  _recipe('com', 'Cơm rang dưa cải'),
];

/// Thứ Ba 20/10/2026.
final _today = DateTime(2026, 10, 20);

/// Gợi ý luôn là món đầu tiên chưa dùng trong ngày.
MealSuggestion? _suggest(MealPrefs prefs, {Meal? meal, Set<String> exclude = const {}}) {
  final pick = _recipes.where((r) => !exclude.contains(r.id)).take(1).toList();
  return pick.isEmpty
      ? null
      : MealSuggestion(
          dishes: pick,
          scale: prefs.scale,
          totalMinutes: 15,
          availability: const Availability(),
          reasons: const [],
        );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Future<List<Recipe>> Function()? recipes,
  String location = '/plan',
  DateTime? now,
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...planTabRoutes,
      for (final path in ['/shopping', '/recipe/:id', '/recipe/:id/prep', '/meal-cook'])
        GoRoute(path: path, builder: (_, state) => Text('at ${state.uri}')),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      // 8h: bữa tâm điểm hôm nay là Sáng.
      nowProvider.overrideWithValue(now ?? DateTime(2026, 10, 20, 8)),
      recipesProvider.overrideWith((ref) => (recipes ?? () async => _recipes)()),
      mealSuggesterProvider.overrideWith((ref) async => _suggest),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

GoRouter _router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Navigator).first));

String _empty(Meal meal, [String day = 'nay']) => PlanStrings.emptyMeal(meal, day);

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// Mở bữa thu gọn [meal] đang có tóm tắt [summary].
Future<void> _open(WidgetTester tester, Meal meal, String summary) async {
  final row = find.bySemanticsLabel(PlanStrings.openMeal(meal.label, summary));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

/// Chọn [action] trong menu ⋯ của món [name].
Future<void> _menu(WidgetTester tester, String name, String action) async {
  final more = find.byTooltip(PlanStrings.dishMenu(name));
  await tester.ensureVisible(more);
  await tester.tap(more);
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

/// Chọn món [name] trong sheet chọn món đang mở.
Future<void> _pick(WidgetTester tester, String name) async {
  await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(name)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hôm nay 8h: Sáng mở sẵn, Trưa Tối thu gọn, gợi ý cho ngày trống', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Thứ Ba, 20/10 · Hôm nay'), findsOneWidget);
    expect(find.text(PlanStrings.suggestDay), findsOneWidget);
    expect(find.text(_empty(Meal.breakfast)), findsOneWidget);
    expect(find.text('Còn trống'), findsOneWidget);
    expect(find.text(PlanStrings.addDish), findsOneWidget);
    expect(find.text(PlanStrings.suggestMeal), findsOneWidget);
    expect(find.bySemanticsLabel(PlanStrings.openMeal('Trưa', 'Chưa có món')), findsOneWidget);
    expect(find.bySemanticsLabel(PlanStrings.openMeal('Tối', 'Chưa có món')), findsOneWidget);
  });

  testWidgets('18h30: Tối là bữa tâm điểm; bấm bữa thu gọn thì mở bữa đó', (tester) async {
    await _pump(tester, now: DateTime(2026, 10, 20, 18, 30));
    expect(find.text(_empty(Meal.dinner)), findsOneWidget);

    await _open(tester, Meal.breakfast, 'Chưa có món');
    expect(find.text(_empty(Meal.breakfast)), findsOneWidget);
    expect(find.text(_empty(Meal.dinner)), findsNothing);
    expect(find.bySemanticsLabel(PlanStrings.openMeal('Tối', 'Chưa có món')), findsOneWidget);
  });

  testWidgets('mũi tên đổi ngày qua tuần; ngày khác dùng tên ngày trong câu trống', (tester) async {
    await _pump(tester);

    await _tapTooltip(tester, PlanStrings.nextDay);
    expect(find.text('Thứ Tư, 21/10'), findsOneWidget);
    expect(find.text(_empty(Meal.breakfast, 'thứ tư')), findsOneWidget);

    await _tapTooltip(tester, PlanStrings.previousDay);
    await _tapTooltip(tester, PlanStrings.previousDay);
    await _tapTooltip(tester, PlanStrings.previousDay);
    expect(find.text('Chủ nhật, 18/10'), findsOneWidget);
  });

  testWidgets('sheet lịch: lật tháng, chọn ngày, Hôm nay, Đóng', (tester) async {
    await _pump(tester);

    await _tapTooltip(tester, PlanStrings.calendarLabel('Thứ Ba, 20/10 · Hôm nay'));
    expect(find.text(PlanStrings.calendarTitle), findsOneWidget);
    expect(find.text('Tháng 10, 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Ba 20/10, hôm nay'), findsOneWidget);

    await _tapTooltip(tester, PlanStrings.nextMonth);
    expect(find.text('Tháng 11, 2026'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Thứ Năm 5/11'));
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.calendarTitle), findsNothing);
    expect(find.text('Thứ Năm, 5/11'), findsOneWidget);

    // Mở lại ở tháng của ngày đang xem.
    await _tapTooltip(tester, PlanStrings.calendarLabel('Thứ Năm, 5/11'));
    expect(find.text('Tháng 11, 2026'), findsOneWidget);
    await tester.tap(find.text(PlanStrings.close));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Năm, 5/11'), findsOneWidget);

    await _tapTooltip(tester, PlanStrings.calendarLabel('Thứ Năm, 5/11'));
    await tester.tap(find.text(PlanStrings.today));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Ba, 20/10 · Hôm nay'), findsOneWidget);
  });

  testWidgets('Thêm món từ sheet chọn món; một món thì Nấu bữa này mở Nấu cả bữa', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.text(PlanStrings.addDish));
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.pickTitle('Sáng')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'trung');
    await tester.pumpAndSettle();
    await _pick(tester, 'Trứng chiên hành');

    expect(container.read(plannedMealsProvider).single.recipeId, 'trung');
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text('1 món · ~15 phút'), findsOneWidget);
    expect(find.text(PlanStrings.suggestDay), findsNothing);
    expect(find.text(PlanStrings.suggestMeal), findsNothing);

    await tester.tap(find.text(PlanStrings.cookMeal));
    await tester.pumpAndSettle();
    expect(find.text('at /meal-cook?day=2026-10-20&meal=breakfast'), findsOneWidget);
  });

  testWidgets('menu ⋯: Bỏ khỏi bữa có Hoàn tác về đúng chỗ; Đổi món giữ vị trí', (tester) async {
    final container = await _pump(tester);
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', _today, Meal.breakfast);
    await plan.addToPlan('canh', _today, Meal.breakfast);
    await tester.pumpAndSettle();
    List<String> ids() => [for (final p in container.read(plannedMealsProvider)) p.recipeId];

    await _menu(tester, 'Trứng chiên hành', PlanStrings.removeDish);
    expect(ids(), ['canh']);
    expect(find.text(PlanStrings.removed('Trứng chiên hành', Meal.breakfast)), findsOneWidget);
    await tester.tap(find.text(PlanStrings.undo));
    await tester.pumpAndSettle();
    expect(ids(), ['trung', 'canh']);

    await _menu(tester, 'Trứng chiên hành', PlanStrings.swapDish);
    await _pick(tester, 'Cơm rang dưa cải');
    expect(ids(), ['com', 'canh']);
    expect(find.text('Trứng chiên hành'), findsNothing);
  });

  testWidgets('bấm card món mở Chi tiết; bữa thu gọn tóm tắt món', (tester) async {
    final container = await _pump(tester);
    final plan = container.read(plannedMealsProvider.notifier);
    for (final id in ['trung', 'canh', 'com']) {
      await plan.addToPlan(id, _today, Meal.dinner);
    }
    await tester.pumpAndSettle();
    const summary = '3 món · 45 phút · Trứng chiên hành, Canh cà chua +1 món';
    await _open(tester, Meal.dinner, summary);

    await tester.tap(find.text('Canh cà chua'));
    await tester.pumpAndSettle();
    expect(find.text('at /recipe/canh'), findsOneWidget);
  });

  testWidgets('bữa nhiều món có Nấu bữa này mở Nấu cả bữa; nấu xong vẫn hiện nút + Đã nấu', (
    tester,
  ) async {
    final container = await _pump(tester);
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', _today, Meal.breakfast);
    await plan.addToPlan('canh', _today, Meal.breakfast);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        PlanStrings.cookMealLabel(Meal.breakfast, ['Trứng chiên hành', 'Canh cà chua']),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(PlanStrings.cookMeal));
    await tester.pumpAndSettle();
    expect(find.text('at /meal-cook?day=2026-10-20&meal=breakfast'), findsOneWidget);

    await plan.markCooked(_today, Meal.breakfast, ['trung', 'canh']);
    _router(tester).pop();
    await tester.pumpAndSettle();
    // Nút vẫn hiện; bên cạnh tên bữa có nhãn "Đã nấu".
    expect(find.text(PlanStrings.cookMeal), findsOneWidget);
    expect(find.text(PlanStrings.cooked), findsOneWidget);
  });

  testWidgets('Gợi ý cho ngày này lấp cả ngày; Gợi ý món lấp một bữa', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.text(PlanStrings.suggestMeal));
    await tester.pumpAndSettle();
    expect(container.read(plannedMealsProvider).single.recipeId, 'trung');

    await _tapTooltip(tester, PlanStrings.nextDay);
    await tester.tap(find.text(PlanStrings.suggestDay));
    await tester.pumpAndSettle();
    expect(
      container
          .read(plannedMealsProvider)
          .where((p) => p.day == DateTime(2026, 10, 21))
          .map((p) => (p.meal, p.recipeId)),
      [(Meal.breakfast, 'trung'), (Meal.lunch, 'canh'), (Meal.dinner, 'com')],
    );
    expect(find.text(PlanStrings.suggestDay), findsNothing);
  });

  testWidgets('planLocation mở sẵn ngày và bữa; goToPlanDay mở lại dù URL không đổi', (
    tester,
  ) async {
    expect(planLocation(), '/plan');
    expect(
      planLocation(date: DateTime(2026, 10, 30), meal: Meal.dinner),
      '/plan?date=2026-10-30&meal=dinner',
    );
    await _pump(
      tester,
      location: planLocation(date: DateTime(2026, 10, 30), meal: Meal.dinner),
    );
    expect(find.text('Thứ Sáu, 30/10'), findsOneWidget);
    expect(find.text(_empty(Meal.dinner, 'thứ sáu')), findsOneWidget);

    final context = tester.element(find.byType(Scaffold).first);
    await _tapTooltip(tester, PlanStrings.nextDay);
    expect(find.text('Thứ Bảy, 31/10'), findsOneWidget);

    goToPlanDay(context, DateTime(2026, 10, 30), meal: Meal.dinner);
    await tester.pumpAndSettle();
    expect(find.text('Thứ Sáu, 30/10'), findsOneWidget);
  });

  testWidgets('dữ liệu lỗi thì hiện câu lỗi', (tester) async {
    await _pump(tester, recipes: () => Future.error(const FormatException('hỏng')));

    expect(find.text(PlanStrings.loadError), findsOneWidget);
    expect(find.text(PlanStrings.addDish), findsNothing);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, tên dài nhiều món, theme $name: không tràn', (tester) async {
      final long = [
        for (var i = 0; i < 5; i++)
          _recipe('m$i', 'Đậu phụ non sốt cà chua nấm hương kiểu nhà làm số $i'),
      ];
      final container = await _pump(
        tester,
        recipes: () async => long,
        theme: theme,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      final plan = container.read(plannedMealsProvider.notifier);
      for (final r in long) {
        await plan.addToPlan(r.id, _today, Meal.breakfast);
        await plan.addToPlan(r.id, _today, Meal.lunch);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Bữa trưa thu gọn: 3 ảnh nhỏ và "+2".
      await tester.scrollUntilVisible(find.text('+2'), 300);
      expect(tester.takeException(), isNull);
    });
  }
}
