import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

Recipe dish(String id, String name, DishRole role) => Recipe(
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
  role: role,
);

final tofu = dish('tofu', 'Đậu phụ non sốt cà chua nấm hương kiểu nhà làm', DishRole.main);
final soup = dish('soup', 'Canh cà chua trứng nấu đậu phụ non và rau mùi', DishRole.soup);
final greens = dish('greens', 'Rau muống xào tỏi', DishRole.side);
final egg = dish('egg', 'Trứng chiên hành', DishRole.main);
final rice = dish('rice', 'Cơm rang dưa cải', DishRole.single);

MealSuggestion suggestion(List<Recipe> dishes) => MealSuggestion(
  dishes: dishes,
  scale: MealScale.tray,
  totalMinutes: dishes.length * 15,
  availability: const Availability(missing: ['rau muống']),
  reasons: const ['Thiếu 1 thứ', 'Dùng nốt cà chua', '~45 phút'],
);

final meals = [
  suggestion([tofu, soup, greens]),
  suggestion([egg]),
  suggestion([rice]),
];

MealSuggester fake() =>
    (prefs, {meal, exclude = const <String>{}}) =>
        meals.where((m) => m.dishes.every((d) => !exclude.contains(d.id))).firstOrNull;

Future<GoRouter> pump(WidgetTester tester, {bool dark = false}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Trang chủ')),
      ),
      ...discoverRoutes,
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => Scaffold(body: Text('Món ${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        recipesProvider.overrideWith((ref) async => [tofu, soup, greens, egg, rice]),
        todayClockProvider.overrideWithValue(() => DateTime(2026, 11, 1, 18, 30)),
        mealSuggesterProvider.overrideWith((ref) async => fake()),
        suggestionsProvider.overrideWith((ref, args) async => [tofu, egg, soup]),
      ],
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp.router(
          theme: dark ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  router.push(todayLocation);
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('Today 360dp, text 1.3, ${dark ? 'tối' : 'sáng'}: bữa, đổi món, lưu, Không hợp', (
      tester,
    ) async {
      await pump(tester, dark: dark);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('Bữa tối nay'), findsOneWidget);
      expect(find.text(DiscoverStrings.todaySubtitle), findsOneWidget);
      expect(find.text(tofu.name), findsOneWidget);
      expect(find.text('Rau/món thêm'), findsOneWidget);
      expect(find.text('3 món · ~45 phút · Bếp từ'), findsOneWidget);
      expect(find.text('Thiếu: rau muống'), findsOneWidget);
      final list = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text(DiscoverStrings.todayAlternatives),
        200,
        scrollable: list,
      );
      expect(find.text('Trứng chiên hành'), findsOneWidget);
      expect(find.text('1 món · ~15 phút'), findsWidgets);
      await tester.scrollUntilVisible(find.text(tofu.name), -200, scrollable: list);
      expect(tester.takeException(), isNull);

      // Đổi món mặn: món cùng vai kế tiếp trong danh sách gợi ý.
      final swap = find.bySemanticsLabel('Đổi ${tofu.name}');
      await tester.ensureVisible(swap);
      await tester.pumpAndSettle();
      await tester.tap(swap);
      await tester.pumpAndSettle();
      expect(find.text(tofu.name), findsNothing);
      expect(find.text(egg.name), findsWidgets);

      // Lưu lại → Đã lưu + snackbar có Xem.
      await tester.tap(find.text(DiscoverStrings.todaySave));
      await tester.pumpAndSettle();
      expect(find.text(DiscoverStrings.todaySaved), findsOneWidget);
      expect(find.text(DiscoverStrings.todaySavedMeal), findsOneWidget);
      expect(find.text(DiscoverStrings.todayView), findsOneWidget);

      // Đổi cả bữa: bữa khác nên về Lưu lại.
      await tester.tap(find.text(DiscoverStrings.todayShuffle));
      await tester.pumpAndSettle();
      expect(find.text(DiscoverStrings.todaySave), findsOneWidget);

      await tester.tap(find.text(DiscoverStrings.todayDislike));
      await tester.pumpAndSettle();
      expect(find.text(DiscoverStrings.todayReasonsPrompt), findsOneWidget);
      expect(find.text('Vừa ăn rồi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dải tiêu chí mở Gợi ý cho mình, bấm tên món mở Chi tiết', (tester) async {
    final router = await pump(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Tiêu chí: Cơm nhà 2 món, Nhanh gọn, .*Bấm để sửa$')),
      findsOneWidget,
    );
    await tester.tap(find.text(tofu.name));
    await tester.pumpAndSettle();
    expect(find.text('Món tofu'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    final criteria = find.bySemanticsLabel(RegExp(r'^Tiêu chí: '));
    Future<void> openPrefs() async {
      await tester.tap(criteria);
      await tester.pumpAndSettle();
      expect(find.text(DiscoverStrings.prefsTitle), findsOneWidget);
    }

    // Back từ Gợi ý cho mình quay lại Hôm nay ăn gì, không về Khám phá.
    await openPrefs();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Trang chủ'), findsNothing);

    // Gợi ý (hoặc Bỏ qua) cũng quay lại đúng màn đó, không chồng thêm Hôm nay ăn gì.
    await openPrefs();
    await tester.tap(find.text(DiscoverStrings.prefsScaleOne));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DiscoverStrings.prefsCta('1 món gọn lẹ')));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Tiêu chí: 1 món gọn lẹ, ')),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
