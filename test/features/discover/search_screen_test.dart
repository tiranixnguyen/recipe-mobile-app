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
            recipesProvider.overrideWith((ref) async => [dish]),
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
      router.push(searchLocation(query: 'trung', maxMinutes: 15));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('1 món phù hợp'), findsOneWidget);
      expect(find.text('Trứng hấp'), findsOneWidget);
      await tester.tap(find.text('Dưới 15 phút'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
    });
  }
}
