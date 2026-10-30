import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

const _recipe = Recipe(
  id: 'trung',
  name: 'Trứng chiên hành',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

const _other = Recipe(
  id: 'dau-phu',
  name: 'Đậu phụ sốt cà chua',
  description: '',
  imageAsset: '',
  minutes: 20,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

const _canh = Recipe(
  id: 'canh',
  name: 'Canh chua cà chua',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

/// Mở sheet bằng nút "Mở"; trả container và kết quả `showAddToPlanSheet` (null khi chưa đóng).
/// [meal] thì mở `showAddMealToPlanSheet` cho các món đó.
Future<(ProviderContainer, bool? Function())> _open(
  WidgetTester tester, {
  List<Recipe>? meal,
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      // 17h Thứ Ba: mặc định Tối nay.
      nowProvider.overrideWithValue(DateTime(2026, 10, 20, 17)),
      recipesProvider.overrideWith((ref) async => const [_recipe, _other, _canh]),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(plannedMealsProvider.notifier)
      .addToPlan('dau-phu', DateTime(2026, 10, 20), Meal.dinner);
  bool? result;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async => result = meal == null
                ? await showAddToPlanSheet(context, _recipe)
                : await showAddMealToPlanSheet(context, meal),
            child: const Text('Mở'),
          ),
        ),
      ),
      GoRoute(path: '/plan', builder: (_, state) => Text('at ${state.uri}')),
    ],
  );
  addTearDown(router.dispose);
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
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
  return (container, () => result);
}

void main() {
  testWidgets('mặc định Tối nay, có dòng Sẽ thêm cùng; thêm thì nối vào bữa, sang Thực đơn', (
    tester,
  ) async {
    final (container, result) = await _open(tester);

    expect(find.text(PlanStrings.addTitle), findsOneWidget);
    expect(find.text('Trứng chiên hành · 15 phút · Bếp từ'), findsOneWidget);
    expect(find.text(PlanStrings.addDays), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Ba, hôm nay'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà chua'), findsOneWidget);
    expect(find.text('Sẽ thêm cùng Đậu phụ sốt cà chua · bữa này thành 2 món'), findsOneWidget);

    await tester.tap(find.byTooltip('Thêm một người'));
    await tester.pump();
    expect(find.text('2 người'), findsOneWidget);

    await tester.tap(find.text('Thêm vào Tối nay'));
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.addTitle), findsNothing);
    expect(result(), isTrue);
    expect(find.text('at /plan?date=2026-10-20&meal=dinner'), findsOneWidget);
    expect(container.read(plannedMealsProvider).map((p) => (p.recipeId, p.servings)), [
      ('dau-phu', 1),
      ('trung', 2),
    ]);
  });

  testWidgets('chọn ngày và bữa đổi nút; Huỷ không thêm gì và trả false', (tester) async {
    final (container, result) = await _open(tester);

    await tester.tap(find.text('T4'));
    await tester.tap(find.text('Trưa'));
    await tester.pump();
    expect(find.text('Thêm vào Trưa mai'), findsOneWidget);
    expect(find.textContaining('Sẽ thêm cùng'), findsNothing);

    await tester.tap(find.text('T6'));
    await tester.tap(find.text('Sáng'));
    await tester.pump();
    expect(find.text('Thêm vào Sáng thứ Sáu'), findsOneWidget);

    await tester.tap(find.text(PlanStrings.cancel));
    await tester.pumpAndSettle();
    expect(result(), isFalse);
    expect(find.text('Mở'), findsOneWidget);
    expect(container.read(plannedMealsProvider).single.recipeId, 'dau-phu');
  });

  testWidgets('cả bữa: dòng phụ nhiều món, thêm tất cả rồi mở đúng bữa', (tester) async {
    final (container, result) = await _open(tester, meal: const [_recipe, _canh]);

    expect(find.text('Trứng chiên hành + Canh chua cà chua · 2 món'), findsOneWidget);
    expect(find.text('Sẽ thêm cùng Đậu phụ sốt cà chua · bữa này thành 3 món'), findsOneWidget);

    await tester.tap(find.text('Thêm vào Tối nay'));
    await tester.pumpAndSettle();
    expect(result(), isTrue);
    expect(find.text('at /plan?date=2026-10-20&meal=dinner'), findsOneWidget);
    expect(container.read(plannedMealsProvider).map((p) => p.recipeId), [
      'dau-phu',
      'trung',
      'canh',
    ]);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, theme $name: không tràn', (tester) async {
      await _open(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text(PlanStrings.addTitle), findsOneWidget);
    });
  }
}
