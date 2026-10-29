import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_screen.dart';
import 'package:recipe_mobile_app/features/pantry/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Future<List<Ingredient>> Function()? ingredients,
  ThemeData? theme,
}) async {
  final router = GoRouter(
    initialLocation: '/pantry',
    routes: [
      GoRoute(path: '/pantry', builder: (_, _) => const PantryScreen()),
      GoRoute(path: shoppingLocation, builder: (_, _) => const Text('màn đi chợ')),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      ingredientsProvider.overrideWith((ref) => (ingredients ?? () async => _ingredients)()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: theme ?? AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Nhấn giữ chip [name], kéo vào nút Đi chợ rồi thả.
Future<void> _dragToFab(WidgetTester tester, String name) async {
  final gesture = await tester.startGesture(tester.getCenter(find.text(name)));
  await tester.pump(HoldDraggable.delay + const Duration(milliseconds: 50));
  await gesture.moveTo(tester.getCenter(find.byType(FloatingActionButton)));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('header đếm, nhóm có tiêu đề và số, không có gia vị cơ bản', (tester) async {
    await _pump(tester);

    expect(find.text(PantryStrings.title), findsOneWidget);
    expect(find.text(PantryStrings.summary(0, 0)), findsOneWidget);
    expect(find.text('Tinh bột'), findsOneWidget);
    expect(find.text('Đạm'), findsOneWidget);
    expect(find.text('Muối'), findsNothing);
    expect(find.text(PantryStrings.groupCount(0, 0)), findsNWidgets(3));
    expect(find.text(PantryStrings.filterHave(0)), findsOneWidget);
    expect(find.textContaining(PantryStrings.dragTip, findRichText: true), findsOneWidget);
  });

  testWidgets('bấm chip thì vào tủ, header và bộ lọc cập nhật', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Trứng gà'));
    await tester.pump();
    expect(find.text(PantryStrings.summary(1, 0)), findsOneWidget);
    expect(find.text(PantryStrings.groupCount(1, 0)), findsOneWidget);
    expect(find.bySemanticsLabel(PantryStrings.chipHave('Trứng gà')), findsOneWidget);

    await tester.tap(find.text(PantryStrings.filterHave(1)));
    await tester.pump();
    expect(find.text('Đậu phụ'), findsNothing);
    expect(find.text('Trứng gà'), findsOneWidget);

    await tester.tap(find.text(PantryStrings.filterNeeded(0)));
    await tester.pump();
    expect(find.text(PantryStrings.emptyFilter), findsOneWidget);
  });

  testWidgets('tìm không dấu, khớp tên nhóm; không thấy thì thêm từ khoá vào đi chợ', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'dau');
    await tester.pump();
    expect(find.text('Đậu phụ'), findsOneWidget);
    expect(find.text('Trứng gà'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tinh bot');
    await tester.pump();
    expect(find.text('Cơm'), findsOneWidget);
    expect(find.text('Đạm'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Gừng');
    await tester.pump();
    expect(find.text(PantryStrings.noMatch('Gừng')), findsOneWidget);
    await tester.tap(find.text(PantryStrings.addQuery('Gừng')));
    await tester.pumpAndSettle();

    expect(container.read(shoppingItemsProvider), [const ShoppingItem.custom('Gừng')]);
    expect(find.text(PantryStrings.added('Gừng')), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(find.text('Trứng gà'), findsOneWidget);
    expect(find.text(PantryStrings.summary(0, 1)), findsOneWidget);
  });

  testWidgets('nút xoá từ khoá', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'dau');
    await tester.pump();
    await tester.tap(find.byTooltip(PantryStrings.clearQuery));
    await tester.pump();
    expect(find.text('Trứng gà'), findsOneWidget);
    expect(find.byTooltip(PantryStrings.clearQuery), findsNothing);
  });

  testWidgets('bấm tiêu đề nhóm thì đóng/mở', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Đạm'));
    await tester.pump();
    expect(find.text('Trứng gà'), findsNothing);
    expect(find.text('Cơm'), findsOneWidget);

    await tester.tap(find.text('Đạm'));
    await tester.pump();
    expect(find.text('Trứng gà'), findsOneWidget);
  });

  testWidgets('kéo chip vào nút Đi chợ: badge tăng, snackbar Hoàn tác, mẹo ẩn hẳn', (tester) async {
    final container = await _pump(tester);

    await _dragToFab(tester, 'Trứng gà');

    expect(container.read(shoppingItemsProvider), [const ShoppingItem.ingredient('egg')]);
    expect(find.text(PantryStrings.added('Trứng gà')), findsOneWidget);
    expect(tester.widget<ShoppingFab<Ingredient>>(find.byType(ShoppingFab<Ingredient>)).count, 1);
    expect(find.bySemanticsLabel(PantryStrings.chipNeeded('Trứng gà')), findsOneWidget);
    expect(container.read(tipsSeenProvider), isNotEmpty);

    await tester.tap(find.text(PantryStrings.undo));
    await tester.pumpAndSettle();
    expect(container.read(shoppingItemsProvider), isEmpty);
  });

  testWidgets('kéo đồ đã có trong đi chợ: info + Xem mở màn đi chợ', (tester) async {
    final container = await _pump(tester);
    await container.read(shoppingItemsProvider.notifier).addIngredient('egg');
    await tester.pump();

    await _dragToFab(tester, 'Trứng gà');
    expect(find.text(PantryStrings.alreadyInShopping('Trứng gà')), findsOneWidget);

    await tester.tap(find.text(PantryStrings.see));
    await tester.pumpAndSettle();
    expect(find.text('màn đi chợ'), findsOneWidget);
  });

  testWidgets('kéo đồ đang có trong tủ: info không nút', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Trứng gà'));
    await tester.pump();

    await _dragToFab(tester, 'Trứng gà');
    expect(find.text(PantryStrings.inPantry('Trứng gà')), findsOneWidget);
    expect(find.text(PantryStrings.undo), findsNothing);
    expect(container.read(shoppingItemsProvider), isEmpty);
  });

  testWidgets('Shift+Enter và action trợ năng cũng thêm vào đi chợ', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await _pump(tester);

    final chip = find.bySemanticsLabel(PantryStrings.chipNone('Trứng gà'));
    final node = tester.getSemantics(chip);
    final action = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: PantryStrings.addToShoppingAction),
    );
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      action,
    );
    await tester.pumpAndSettle();
    expect(container.read(shoppingItemsProvider), [const ShoppingItem.ingredient('egg')]);

    Focus.of(tester.element(find.text('Đậu phụ'))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(container.read(shoppingItemsProvider), hasLength(2));
    handle.dispose();
  });

  testWidgets('chạy được ở theme tối', (tester) async {
    await _pump(tester, theme: AppTheme.dark);
    await tester.tap(find.text('Trứng gà'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dữ liệu lỗi thì hiện câu lỗi, không có nút Đi chợ', (tester) async {
    await _pump(tester, ingredients: () => Future.error(const FormatException('hỏng')));

    expect(find.text(PantryStrings.loadError), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
