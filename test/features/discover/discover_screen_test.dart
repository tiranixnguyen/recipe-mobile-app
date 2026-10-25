import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

const _ingredients = [Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein)];

const _recipe = Recipe(
  id: 'trung-chien',
  name: 'Trứng chiên hành',
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [RecipeIngredient(id: 'egg', amount: 2, unit: 'quả')],
  steps: [],
);

/// Màn đích chỉ in ra đường dẫn để kiểm điều hướng.
Widget _location(BuildContext context, GoRouterState state) => Text('at ${state.uri}');

Future<void> _pump(
  WidgetTester tester, {
  List<Recipe> recipes = const [_recipe],
  Future<List<Recipe>> Function()? loadRecipes,
  ThemeData? theme,
  bool compact = false,
}) async {
  tester.view.physicalSize = Size((compact ? 360 : 390) * 3, (compact ? 800 : 1400) * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DiscoverScreen()),
      for (final path in ['/search', '/today', '/settings', '/pantry', '/recipe/:id'])
        GoRoute(path: path, builder: _location),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith((ref) => (loadRecipes ?? () async => recipes)()),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        builder: compact
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              )
            : null,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapAndExpect(WidgetTester tester, Finder target, String location) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.text('at $location'), findsOneWidget);
}

void main() {
  testWidgets('món nấu được có badge, món nhanh có số người', (tester) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.heroTitle), findsOneWidget);
    expect(find.widgetWithText(RecipeCard, 'Trứng chiên hành'), findsOneWidget);
    expect(find.widgetWithText(AvailabilityBadge, 'Thiếu: trứng'), findsOneWidget);
    expect(find.text('10 phút · 1 người · Bếp từ'), findsOneWidget);
  });

  testWidgets('không món nào nấu được thì mời mở Tủ đồ', (tester) async {
    await _pump(tester, recipes: const []);

    expect(find.text(DiscoverStrings.cookableEmpty), findsOneWidget);
    expect(find.text(DiscoverStrings.quick), findsNothing);
    await _tapAndExpect(tester, find.text(DiscoverStrings.openPantry), '/pantry');
  });

  testWidgets('Gợi ý cho mình mở Hôm nay ăn gì', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.text(DiscoverStrings.heroAction), '/today');
  });

  testWidgets('ô tìm mở Tìm kiếm', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.text(DiscoverStrings.searchPlaceholder), '/search');
  });

  testWidgets('chip nhanh mở Tìm kiếm có sẵn bộ lọc', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.text(DiscoverStrings.quickUnder15), '/search?maxMinutes=15');
  });

  testWidgets('nút Cài đặt', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.byTooltip(DiscoverStrings.settings), '/settings');
  });

  testWidgets('bấm món mở Chi tiết', (tester) async {
    await _pump(tester);
    await _tapAndExpect(tester, find.byType(RecipeCard), '/recipe/trung-chien');
  });

  for (final (label, target) in [
    (DiscoverStrings.quickRiceCooker, '/search?tool=rice'),
    (DiscoverStrings.quickVeg, '/search?diet=veg'),
    (DiscoverStrings.quickDinner, '/search?meal=dinner'),
  ]) {
    testWidgets('chip $label chuyển đúng bộ lọc', (tester) async {
      await _pump(tester);
      await tester.ensureVisible(find.text(label));
      await _tapAndExpect(tester, find.text(label), target);
    });
  }

  testWidgets('lỗi tải công thức hiện thông báo thay vì danh sách', (tester) async {
    await _pump(tester, loadRecipes: () => Future.error(const FormatException('invalid')));
    expect(find.text(DiscoverStrings.loadError), findsOneWidget);
    expect(find.byType(RecipeCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    for (final recipes in [
      const [_recipe],
      const <Recipe>[],
    ]) {
      testWidgets('Main $name, ${recipes.isEmpty ? 'trống' : 'có món'}: 360dp, chữ 1.3', (
        tester,
      ) async {
        await _pump(tester, theme: theme, compact: true, recipes: recipes);
        expect(find.text(DiscoverStrings.heroTitle), findsOneWidget);
        expect(find.text(DiscoverStrings.cookable), findsOneWidget);
        await tester.ensureVisible(find.text(DiscoverStrings.cookable));
        if (recipes.isEmpty) {
          expect(find.text(DiscoverStrings.cookableEmpty), findsOneWidget);
        } else {
          expect(find.byType(RecipeCard), findsOneWidget);
          await tester.ensureVisible(find.byType(RecipeCard));
        }
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(DiscoverStrings.heroAction));
        await _tapAndExpect(tester, find.text(DiscoverStrings.heroAction), '/today');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
