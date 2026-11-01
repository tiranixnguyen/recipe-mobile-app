import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành', group: IngredientGroup.spice),
];

const _recipeReady = Recipe(
  id: 'trung-chien',
  name: 'Trứng chiên hành',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.dinner],
  ingredients: [
    RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
  ],
  steps: [],
);

const _recipeNear = Recipe(
  id: 'canh-trung',
  name: 'Canh cà chua trứng',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.dinner],
  ingredients: [
    RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
    RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả'),
  ],
  steps: [],
);

/// Màn đích chỉ in ra đường dẫn để kiểm điều hướng.
Widget _location(BuildContext context, GoRouterState state) => Text('at ${state.uri}');

Future<void> _pump(
  WidgetTester tester, {
  List<Recipe> recipes = const [_recipeReady, _recipeNear],
  List<String> pantry = const ['egg', 'scallion'],
  List<PlannedMeal> planned = const [],
  DateTime? now,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 2000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final fixedNow = now ?? DateTime(2026, 10, 24, 18, 30); // 18h30: tối
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DiscoverScreen()),
      for (final path in [
        '/search',
        '/today',
        '/today/prefs',
        '/settings',
        '/pantry',
        '/plan',
        '/shopping',
        '/meal-cook',
        '/recipe/:id',
        '/recipe/:id/prep',
      ])
        GoRoute(path: path, builder: _location),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        discoverNowProvider.overrideWithValue(fixedNow),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith((ref) async => recipes),
        pantryItemsProvider.overrideWith(() => _FakePantryController(pantry.toSet())),
        plannedMealsProvider.overrideWith(() => _FakePlannedController(planned)),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakePantryController extends PantryItemsController {
  _FakePantryController(this._initial);
  final Set<String> _initial;
  @override
  Set<String> build() => _initial;
}

class _FakePlannedController extends PlannedMealsController {
  _FakePlannedController(this._initial);
  final List<PlannedMeal> _initial;
  @override
  List<PlannedMeal> build() => _initial;
}

Future<void> _tapAndExpect(WidgetTester tester, Finder target, String location) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.text('at $location'), findsOneWidget);
}

void main() {
  testWidgets('hiển thị header, carousel, ô tìm kiếm và chip lọc nhanh', (tester) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.appName), findsOneWidget);
    expect(find.text(DiscoverStrings.searchPlaceholder), findsOneWidget);
    expect(find.text(DiscoverStrings.quickUnder15), findsOneWidget);
    expect(find.text(DiscoverStrings.quickRiceCooker), findsOneWidget);
    expect(find.text(DiscoverStrings.quickVeg), findsOneWidget);
    expect(find.text(DiscoverStrings.quickDinner), findsOneWidget);

    // Carousel: hiển thị thẻ tối
    expect(find.text('Tối nay thong thả'), findsOneWidget);
  });

  testWidgets('bữa tới chưa có món: hiện tiêu đề, văn bản mời thử món và nút + Thêm', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.upcomingTitle('tối')), findsOneWidget);
    expect(find.text(DiscoverStrings.upcomingEmpty('tối')), findsOneWidget);
    expect(find.text(DiscoverStrings.addDish), findsWidgets);
  });

  testWidgets('bữa tới đã có món: hiện món và nút Nấu món này, bấm vùng món thì sang Thực đơn', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 24, 18, 30);
    final today = dateOnly(now);
    final planned = [
      PlannedMeal(day: today, meal: Meal.dinner, recipeId: 'trung-chien'),
    ];

    // Tủ chỉ có trứng: trung-chien không đủ đồ, nên tên món không lặp lại ở Nấu được ngay.
    await _pump(tester, planned: planned, now: now, pantry: const ['egg']);

    expect(find.text(_recipeReady.name), findsOneWidget);
    expect(find.text(DiscoverStrings.cookDish), findsOneWidget);

    // Bấm Nấu món này
    await _tapAndExpect(tester, find.text(DiscoverStrings.cookDish), '/recipe/trung-chien/prep');
  });

  testWidgets('bữa tới đã có món: bấm vùng món (ngoài nút Nấu) thì sang Thực đơn', (tester) async {
    final now = DateTime(2026, 10, 24, 18, 30);
    final today = dateOnly(now);
    final planned = [
      PlannedMeal(day: today, meal: Meal.dinner, recipeId: 'trung-chien'),
    ];

    await _pump(tester, planned: planned, now: now);

    await _tapAndExpect(
      tester,
      find.bySemanticsLabel(RegExp('^${RegExp.escape(DiscoverStrings.openUpcomingPlan('tối'))}')),
      '/plan',
    );
  });

  testWidgets('Nấu được ngay: hiện món đủ đồ, bấm Mở tủ đồ chuyển sang tab Pantry', (tester) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.readyToCook), findsOneWidget);
    expect(find.text(DiscoverStrings.openPantry), findsOneWidget);
    expect(find.text(DiscoverStrings.readyEmptyPantryTitle), findsNothing);
    await _tapAndExpect(tester, find.text(DiscoverStrings.openPantry), '/pantry');
  });

  testWidgets('Nấu được ngay: tủ trống thì hiện thẻ dẫn vào Tủ đồ, bấm chuyển sang tab Pantry', (
    tester,
  ) async {
    await _pump(tester, pantry: const []);

    expect(find.text(DiscoverStrings.readyToCook), findsOneWidget);
    expect(find.text(DiscoverStrings.openPantry), findsNothing);
    expect(find.text(DiscoverStrings.readyEmptyPantryTitle), findsOneWidget);
    await _tapAndExpect(tester, find.text(DiscoverStrings.readyEmptyPantryTitle), '/pantry');
  });

  testWidgets('Đi chợ: bấm vào thẻ mở màn Shopping', (tester) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.shoppingTitle), findsOneWidget);
    await _tapAndExpect(tester, find.text(DiscoverStrings.shoppingEmpty), '/shopping');
  });

  testWidgets('ô tìm mở Tìm kiếm', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.byType(SearchField), '/search');
  });

  testWidgets('chip nhanh mở Tìm kiếm có bộ lọc', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.text(DiscoverStrings.quickUnder15), '/search?maxMinutes=15');
  });

  testWidgets('nút Cài đặt mở Settings', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.byTooltip(DiscoverStrings.settings), '/settings');
  });
}
