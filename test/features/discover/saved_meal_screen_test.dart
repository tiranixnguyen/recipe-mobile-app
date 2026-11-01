import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

import 'meal_fixtures.dart';

const _meal = SavedMeal(recipeIds: ['trung', 'canh'], servings: 1);

final _fabBadge = find.byKey(const ValueKey('shopping-fab-badge'));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool saved = true,
  ThemeData? theme,
  Size size = const Size(390, 1600),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => mealRecipes),
      ingredientsProvider.overrideWith((ref) async => mealIngredientsFixture),
    ],
  );
  addTearDown(container.dispose);
  if (saved) await container.read(savedMealsProvider.notifier).saveMeal(_meal);
  await container.read(pantryItemsProvider.notifier).addToPantry('egg');
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      ...savedTabRoutes,
      ...discoverRoutes,
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => Text('recipe/${state.pathParameters['id']}'),
      ),
      GoRoute(path: '/shopping', builder: (_, _) => const Text('at shopping')),
      GoRoute(path: '/meal-cook', builder: (_, state) => Text('at ${state.uri}')),
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
  await tester.pumpAndSettle();
  router.push(savedMealLocation(_meal.key));
  await tester.pumpAndSettle();
  return container;
}

List<String> _keys(ProviderContainer c) => [for (final m in c.read(savedMealsProvider)) m.key];

void main() {
  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('bố cục ($name): header, ảnh ghép, món, nguyên liệu theo đúng thứ tự', (
      tester,
    ) async {
      await _pump(tester, theme: theme);

      expect(find.text(DiscoverStrings.savedMealTitle), findsOneWidget);
      expect(find.text('2 món · ~35 phút · Bếp từ, Nồi cơm điện'), findsOneWidget);
      expect(find.byTooltip(DiscoverStrings.unsaveMeal), findsOneWidget);
      expect(find.byType(MealMosaic), findsOneWidget);
      expect(find.text(DiscoverStrings.mealStatusMissing(2)), findsOneWidget);
      expect(
        find.text(DiscoverStrings.mealServingsTools(1, 'Bếp từ, Nồi cơm điện')),
        findsOneWidget,
      );

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      final order = [
        top(DiscoverStrings.mealDishesTitle(2)),
        top(DiscoverStrings.mealIngredients),
        top(DiscoverStrings.missingTitle(2)),
        top(DiscoverStrings.haveTitle),
      ];
      expect(order, orderedEquals([...order]..sort()));
      expect(find.text('Hành lá · 2 nắm'), findsOneWidget);
      expect(find.text('Cả 2 món'), findsOneWidget);
      expect(find.text('Trứng gà · 2 quả'), findsOneWidget);
      expect(find.text('Dầu ăn'), findsOneWidget);
      expect(find.text(DiscoverStrings.basicSpices), findsOneWidget);
      expect(find.text(DiscoverStrings.savedMealAddToPlan), findsOneWidget);
      expect(find.text(DiscoverStrings.startCooking), findsOneWidget);
      expect(find.byType(ShoppingFab<Object>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('màn 360dp, chữ 1.3: không tràn', (tester) async {
    await _pump(tester, size: const Size(360, 640), textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text(DiscoverStrings.startCooking), findsOneWidget);
  });

  testWidgets('bấm món mở Chi tiết món', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Canh cà chua').first);
    await tester.pumpAndSettle();
    expect(find.text('recipe/canh'), findsOneWidget);
  });

  testWidgets('Đổi món: sheet lọc sẵn theo loại, món đã có bị disable, chọn xong có Hoàn tác', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, DiscoverStrings.swap).first);
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.pickSwapTitle('Trứng chiên hành')), findsOneWidget);
    // Lọc sẵn Món mặn: không có canh, rau.
    expect(find.text('Rau muống xào tỏi'), findsNothing);
    expect(
      find.text('${DiscoverStrings.dishRoleMeta('Món mặn', 15)} · ${DiscoverStrings.pickInMeal}'),
      findsOneWidget,
    );
    await tester.tap(find.text('Trứng chiên hành').last);
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.pickSwapTitle('Trứng chiên hành')), findsOneWidget);

    await tester.tap(find.text('Đậu phụ sốt cà chua').last);
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.pickSwapTitle('Trứng chiên hành')), findsNothing);
    expect(_keys(container), ['dau,canh']);
    expect(
      find.text(DiscoverStrings.dishSwapped('Trứng chiên hành', 'Đậu phụ sốt cà chua')),
      findsOneWidget,
    );

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh']);
  });

  testWidgets('Thêm món: tìm, lọc theo loại, nhóm Món bạn đã lưu, thêm xong có Hoàn tác', (
    tester,
  ) async {
    final container = await _pump(tester);
    await container.read(savedIdsProvider.notifier).save('rau');
    await tester.pumpAndSettle();

    await tester.tap(find.text(DiscoverStrings.mealAddDish));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.pickAddTitle), findsOneWidget);
    expect(find.text(DiscoverStrings.pickGroupSaved), findsOneWidget);
    expect(find.text(DiscoverStrings.pickGroupAll), findsOneWidget);
    expect(find.text('Rau muống xào tỏi'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà chua'), findsOneWidget);

    await tester.tap(find.text(DishRole.soup.label));
    await tester.pumpAndSettle();
    expect(find.text('Đậu phụ sốt cà chua'), findsNothing);
    expect(find.text(DiscoverStrings.pickNone), findsNothing);

    await tester.tap(find.text(DiscoverStrings.pickAll));
    await tester.enterText(find.byType(TextField), 'DAU phu');
    await tester.pumpAndSettle();
    expect(find.text('Rau muống xào tỏi'), findsNothing);
    expect(find.text(DiscoverStrings.pickGroupSaved), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.pickNone), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dau');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đậu phụ sốt cà chua').last);
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh,dau']);
    expect(find.text(DiscoverStrings.dishAdded('Đậu phụ sốt cà chua')), findsOneWidget);
    expect(find.text(DiscoverStrings.mealDishesTitle(3)), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh']);
    expect(find.text(DiscoverStrings.mealDishesTitle(2)), findsOneWidget);
  });

  testWidgets('đóng sheet thì không đổi gì', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text(DiscoverStrings.mealAddDish));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(DiscoverStrings.pickClose));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.pickAddTitle), findsNothing);
    expect(_keys(container), ['trung,canh']);
  });

  testWidgets('Bỏ món rồi Hoàn tác; còn một món thì không có nút bỏ', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.byTooltip(DiscoverStrings.removeLabel('Canh cà chua')));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung']);
    expect(find.text(DiscoverStrings.dishRemoved('Canh cà chua')), findsOneWidget);
    expect(find.byTooltip(DiscoverStrings.removeLabel('Trứng chiên hành')), findsNothing);

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh']);
    expect(find.byTooltip(DiscoverStrings.removeLabel('Trứng chiên hành')), findsOneWidget);
  });

  testWidgets('thêm đồ thiếu vào đi chợ: tag, nút, badge FAB, snackbar Xem', (tester) async {
    final container = await _pump(tester);
    await container.read(shoppingItemsProvider.notifier).addIngredient('tomato');
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.tagInShopping), findsOneWidget);
    expect(find.descendant(of: _fabBadge, matching: find.text('1')), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.addMissing(1)));
    await tester.pumpAndSettle();
    expect(
      container.read(shoppingItemsProvider).map((i) => i.ingredientId),
      ['tomato', 'scallion'],
    );
    expect(find.text(DiscoverStrings.addedToShopping(1, 1)), findsOneWidget);

    // Snackbar nằm cạnh nút Đi chợ (cùng đáy, bên trái nút), không bị đẩy lên trên nút.
    final snack = tester.getRect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
    );
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(snack.right, lessThanOrEqualTo(fab.left));
    expect(snack.bottom, moreOrLessEquals(fab.bottom, epsilon: 1));
    expect(find.text(DiscoverStrings.tagInShopping), findsNWidgets(2));
    expect(find.descendant(of: _fabBadge, matching: find.text('2')), findsOneWidget);
    final done = tester.widget<AppButton>(
      find.widgetWithText(AppButton, DiscoverStrings.allMissingInShopping),
    );
    expect(done.onPressed, isNull);

    await tester.tap(find.text(DiscoverStrings.seeShopping));
    await tester.pumpAndSettle();
    expect(find.text('at shopping'), findsOneWidget);
  });

  testWidgets('FAB Đi chợ mở màn Đi chợ', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip(ShoppingFab.tooltip));
    await tester.pumpAndSettle();
    expect(find.text('at shopping'), findsOneWidget);
  });

  testWidgets('bookmark: bỏ lưu thì ở lại màn, Hoàn tác và Lưu bữa lưu lại', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.byTooltip(DiscoverStrings.unsaveMeal));
    await tester.pumpAndSettle();
    expect(container.read(savedMealsProvider), isEmpty);
    expect(find.text(DiscoverStrings.mealDishesTitle(2)), findsOneWidget);
    expect(find.text(DiscoverStrings.savedMealNotFound), findsNothing);
    expect(
      find.text(DiscoverStrings.savedUnsaved('Trứng chiên hành + Canh cà chua')),
      findsOneWidget,
    );

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh']);

    await tester.tap(find.byTooltip(DiscoverStrings.unsaveMeal));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(DiscoverStrings.saveMeal));
    await tester.pumpAndSettle();
    expect(_keys(container), ['trung,canh']);
    expect(find.byTooltip(DiscoverStrings.unsaveMeal), findsOneWidget);
  });

  testWidgets('Thêm vào thực đơn mở sheet chọn ngày', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(DiscoverStrings.savedMealAddToPlan));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Bắt đầu nấu mở Chuẩn bị nấu cả bữa với các món đang có', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(DiscoverStrings.startCooking));
    await tester.pumpAndSettle();
    expect(find.text('at /meal-cook?dishes=trung%2Ccanh&servings=1'), findsOneWidget);
  });

  testWidgets('bữa không còn: EmptyState, nút về Đã lưu', (tester) async {
    await _pump(tester, saved: false);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(DiscoverStrings.savedMealNotFound), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedMealBack));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
  });
}
