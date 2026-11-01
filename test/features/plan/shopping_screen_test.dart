import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_screen.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'rice', name: 'Gạo', group: IngredientGroup.starch),
];

const _fried = Recipe(
  id: 'fried',
  name: 'Trứng chiên',
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: [],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<ShoppingLine> lines = const [
    ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['fried']),
    ShoppingLine(ingredientId: 'scallion', unit: 'nắm', amount: 1.5, recipeIds: ['fried']),
  ],
  ThemeData? theme,
}) async {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      ingredientsProvider.overrideWith((ref) async => _ingredients),
      recipesProvider.overrideWith((ref) async => [_fried]),
      shoppingListProvider.overrideWith((ref) => AsyncData(lines)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/plan',
    routes: [
      GoRoute(path: '/plan', builder: (_, _) => const Text('plan')),
      GoRoute(
        path: '/pantry',
        builder: (_, _) => const Scaffold(body: Text('pantry')),
      ),
      GoRoute(path: shoppingLocation, builder: (_, _) => const ShoppingScreen()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: theme ?? AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push(shoppingLocation);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('hiển thị nhóm, món dùng, số lẻ kiểu Việt và tiến độ ($name)', (tester) async {
      await _pump(tester, theme: theme);

      expect(find.text(PlanStrings.shoppingTitle), findsOneWidget);
      expect(find.text(PlanStrings.shoppingProgress(0, 2)), findsOneWidget);
      expect(find.text('Hành lá · 1,5 nắm'), findsOneWidget);
      expect(find.text('Trứng gà · 2 quả'), findsOneWidget);
      expect(find.text('Trứng chiên'), findsNWidgets(2));
      // Rau củ trước Đạm.
      expect(
        tester.getTopLeft(find.text('Rau củ')).dy,
        lessThan(tester.getTopLeft(find.text('Đạm')).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text(PlanStrings.shoppingProgress(1, 2)), findsOneWidget);
    });
  }

  testWidgets('báo đã bỏ thứ có sẵn trong Tủ đồ', (tester) async {
    final container = await _pump(tester);
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await tester.pumpAndSettle();
    expect(find.text(PlanStrings.shoppingInPantry(['trứng gà'])), findsOneWidget);
    expect(find.text('Trứng gà · 2 quả'), findsNothing);
  });

  testWidgets('Xong, cất vào tủ: thứ đã tick vào Tủ đồ, báo snackbar, sang Tủ đồ', (tester) async {
    final container = await _pump(tester);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlanStrings.shoppingFinish));
    await tester.pumpAndSettle();

    expect(container.read(pantryItemsProvider), {'scallion'});
    expect(find.text(PlanStrings.shoppingStored(1)), findsOneWidget);
    expect(find.text('pantry'), findsOneWidget);
  });

  testWidgets('trống: EmptyState, không có footer', (tester) async {
    await _pump(tester, lines: const []);
    expect(find.text(PlanStrings.shoppingEmptyTitle), findsOneWidget);
    expect(find.text(PlanStrings.shoppingFinish), findsNothing);
  });
}
