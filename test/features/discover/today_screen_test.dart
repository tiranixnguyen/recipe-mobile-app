import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_screen.dart';
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
  meals: [Meal.breakfast, Meal.lunch, Meal.dinner],
  ingredients: [RecipeIngredient(id: 'egg', amount: 1, unit: 'quả')],
  steps: [],
);
const ingredient = Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein);

void main() {
  for (final dark in [false, true]) {
    testWidgets('Today 360dp, text 1.3, ${dark ? 'tối' : 'sáng'}: gợi ý, chê, back', (
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
          GoRoute(
            path: '/recipe/:id',
            builder: (_, state) => Text('Món ${state.pathParameters['id']}'),
          ),
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
      router.push(todayLocation);
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('Trứng hấp'), findsOneWidget);
      await tester.tap(find.text('Không thích'));
      await tester.pumpAndSettle();
      expect(find.text('Vừa ăn rồi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
    });
  }

  testWidgets('ba món: một chính, hai thay thế, đổi bữa/món, chê và mở chi tiết', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dishes = [
      dish,
      const Recipe(
        id: 'rice',
        name: 'Cơm trứng',
        description: '',
        imageAsset: '',
        minutes: 12,
        servings: 1,
        tools: [Tool.rice],
        diets: [],
        meals: [Meal.breakfast, Meal.lunch, Meal.dinner],
        ingredients: [],
        steps: [],
      ),
      const Recipe(
        id: 'soup',
        name: 'Canh trứng',
        description: '',
        imageAsset: '',
        minutes: 14,
        servings: 1,
        tools: [Tool.rice],
        diets: [],
        meals: [Meal.breakfast, Meal.lunch, Meal.dinner],
        ingredients: [],
        steps: [],
      ),
    ];
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
    final store = InMemoryLocalStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          ingredientsProvider.overrideWith((ref) async => [ingredient]),
          recipesProvider.overrideWith((ref) async => dishes),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(todayLocation);
    await tester.pumpAndSettle();
    expect(find.text('Trứng hấp'), findsOneWidget);
    expect(find.text('Cơm trứng'), findsOneWidget);
    expect(find.text('Canh trứng'), findsOneWidget);
    await tester.tap(find.text('Bữa trưa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bữa trưa ·'), findsOneWidget);
    await tester.tap(find.text('Đổi món'));
    await tester.pumpAndSettle();
    expect(find.text('Cơm trứng'), findsWidgets);
    await tester.tap(find.text('Không thích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vừa ăn rồi'));
    await tester.pumpAndSettle();
    expect(store.readString('pantry.disliked'), contains('rice'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Nấu món này'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Món '), findsOneWidget);
  });
}
