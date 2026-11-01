import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_screen.dart';

Ingredient _ingredient(String id, String name, IngredientGroup group) =>
    Ingredient(id: id, name: name, group: group);

void main() {
  testWidgets('hiển thị danh sách, tiến độ và tick dòng mua', (tester) async {
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => store),
        ingredientsProvider.overrideWith(
          (ref) async => [_ingredient('egg', 'Trứng', IngredientGroup.protein)],
        ),
        shoppingListProvider.overrideWith(
          (ref) => const AsyncData([
            ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['Trứng chiên']),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: shoppingLocation,
      routes: [
        GoRoute(path: shoppingLocation, builder: (_, _) => const ShoppingScreen()),
        GoRoute(path: '/plan', builder: (_, _) => const Text('plan')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đi chợ'), findsOneWidget);
    expect(find.text('0/1 đã mua'), findsOneWidget);
    expect(find.text('Trứng · 2 quả'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('1/1 đã mua'), findsOneWidget);
  });

  testWidgets('trạng thái rỗng không hiển thị footer', (tester) async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        shoppingListProvider.overrideWith((ref) => const AsyncData(<ShoppingLine>[])),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: shoppingLocation,
      routes: [GoRoute(path: shoppingLocation, builder: (_, _) => const ShoppingScreen())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Danh sách đi chợ đang trống'), findsOneWidget);
    expect(find.text('Xong, cất vào tủ'), findsNothing);
  });
}
