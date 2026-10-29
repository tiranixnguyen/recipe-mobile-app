import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/discover/presentation/search/search_screen.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';

const dish = Recipe(
  id: 'egg',
  name: 'Trứng hấp',
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: [Tool.rice],
  diets: [Diet.veg],
  meals: [Meal.dinner],
  ingredients: [RecipeIngredient(id: 'egg', amount: 1, unit: 'quả')],
  steps: [],
);
const slowDish = Recipe(
  id: 'slow-egg',
  name: 'Trứng kho',
  description: '',
  imageAsset: '',
  minutes: 40,
  servings: 2,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.dinner],
  ingredients: [RecipeIngredient(id: 'egg', amount: 2, unit: 'quả')],
  steps: [],
);
const ingredient = Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein);

void main() {
  for (final dark in [false, true]) {
    testWidgets('Search 360dp scale 1.3, ${dark ? 'tối' : 'sáng'}: query, chip, back', (
      tester,
    ) async {
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
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
            ingredientsProvider.overrideWith((ref) async => [ingredient]),
            recipesProvider.overrideWith((ref) async => [dish, slowDish]),
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
      // Nạp sẵn dữ liệu như khi mở từ Khám phá, để kiểm tra frame đầu.
      final container = ProviderScope.containerOf(tester.element(find.text('Trang chủ')));
      final recipes = container.listen(recipesProvider, (_, _) {});
      final ingredients = container.listen(ingredientsProvider, (_, _) {});
      addTearDown(recipes.close);
      addTearDown(ingredients.close);
      await tester.runAsync(
        () => Future.wait([
          container.read(recipesProvider.future),
          container.read(ingredientsProvider.future),
        ]),
      );
      router.push(searchLocation(query: 'trung', maxMinutes: 15));
      await tester.pump();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('1 món có trung, dưới 15 phút'), findsOneWidget);
      expect(find.text('Trứng kho'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Trứng hấp'), findsOneWidget);
      expect(find.text('10 phút · 1 người · Nồi cơm điện'), findsOneWidget);
      expect(find.text('Thiếu: trứng'), findsOneWidget);
      await tester.tap(find.text('Dưới 15 phút'));
      await tester.pumpAndSettle();
      expect(find.text('2 món có trung'), findsOneWidget);
      expect(find.text('40 phút · 2 người · Bếp từ'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'không có món');
      await tester.pumpAndSettle();
      expect(find.text('0 món có không có món'), findsOneWidget);
      expect(find.text('Trứng hấp'), findsNothing);
      await tester.tap(find.byTooltip('Xoá từ khoá'));
      await tester.pumpAndSettle();
      expect(find.text('2 món phù hợp'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
    });
  }
}
