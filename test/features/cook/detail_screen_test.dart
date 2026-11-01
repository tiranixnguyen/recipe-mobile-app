import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

import 'fixtures.dart';

/// Mở Chi tiết của [id] trên một màn `/` (để có chỗ quay lại).
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String id = 'trung',
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('at /')),
      GoRoute(path: '/plan', builder: (_, state) => Text('at ${state.uri}')),
      GoRoute(path: '/shopping', builder: (_, _) => const Text('at shopping')),
      ...cookRoutes,
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [detailRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => detailIngredientsFixture),
    ],
  );
  addTearDown(container.dispose);
  await container.read(pantryItemsProvider.notifier).addToPantry('egg');
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
  router.push(recipeLocation(id));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('hiện ảnh, badge, meta, mô tả, nguyên liệu kèm trạng thái, các bước', (tester) async {
    await _pump(tester);

    expect(find.widgetWithText(AvailabilityBadge, 'Thiếu: hành lá'), findsOneWidget);
    expect(find.text('15 phút'), findsOneWidget);
    expect(find.text('1 người'), findsOneWidget);
    expect(find.text('Bếp từ'), findsOneWidget);
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text(detailRecipeFixture.description), findsOneWidget);

    expect(find.text('Trứng gà · 2 quả'), findsOneWidget);
    expect(find.text(CookStrings.inPantry), findsOneWidget);
    expect(find.text('Hành lá · 1 nắm'), findsOneWidget);
    expect(find.text(CookStrings.missing), findsOneWidget);
    expect(find.text('Dầu ăn, tiêu'), findsOneWidget);
    expect(find.text(CookStrings.basicSpices), findsOneWidget);

    expect(find.text('Cách làm · 3 bước'), findsOneWidget);
    expect(find.text('Làm nóng dầu · 1 phút', findRichText: true), findsOneWidget);
    expect(find.text('Đánh trứng với hành', findRichText: true), findsOneWidget);
  });

  testWidgets('thêm đồ thiếu vào đi chợ: nút thành Đã thêm, FAB có badge, snackbar Xem', (
    tester,
  ) async {
    final container = await _pump(tester);
    expect(find.byKey(const ValueKey('shopping-fab-badge')), findsNothing);

    await tester.tap(find.text(CookStrings.addMissing(1)));
    await tester.pumpAndSettle();

    expect(container.read(shoppingItemsProvider).map((i) => i.ingredientId), ['scallion']);
    expect(find.text(CookStrings.addedMissing), findsOneWidget);
    expect(find.text(CookStrings.inShopping), findsOneWidget);
    expect(find.text(CookStrings.addedToShopping(1)), findsOneWidget);

    // Snackbar nằm cạnh nút Đi chợ (cùng đáy, bên trái nút), không bị đẩy lên trên nút.
    final snack = tester.getRect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
    );
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(snack.right, lessThanOrEqualTo(fab.left));
    expect(snack.bottom, moreOrLessEquals(fab.bottom, epsilon: 1));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shopping-fab-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, CookStrings.addedMissing),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.text(CookStrings.seeShopping));
    await tester.pumpAndSettle();
    expect(find.text('at shopping'), findsOneWidget);
  });

  testWidgets('FAB Đi chợ mở màn Đi chợ', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip(ShoppingFab.tooltip));
    await tester.pumpAndSettle();
    expect(find.text('at shopping'), findsOneWidget);
  });

  testWidgets('Lưu bật rồi tắt; Quay lại về màn trước', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byTooltip('Lưu món'));
    await tester.pump();
    expect(container.read(savedIdsProvider), contains('trung'));
    await tester.tap(find.byTooltip('Bỏ lưu món'));
    await tester.pump();
    expect(container.read(savedIdsProvider), isNot(contains('trung')));

    await tester.tap(find.byTooltip(CookStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('at /'), findsOneWidget);
  });

  testWidgets('Thêm vào thực đơn mở sheet; thêm xong món vào thực đơn, sang Thực đơn', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.text(CookStrings.addToPlan));
    await tester.pumpAndSettle();
    expect(find.text('Trứng chiên hành · 15 phút · Bếp từ'), findsOneWidget);
    // Không cố định ngày (giờ thật): sheet mặc định hôm nay, chọn Trưa.
    await tester.tap(find.text(Meal.lunch.label));
    await tester.pump();
    await tester.tap(find.textContaining('Thêm vào Trưa'));
    await tester.pumpAndSettle();

    final added = container.read(plannedMealsProvider).single;
    expect(
      (added.recipeId, added.meal, added.day),
      ('trung', Meal.lunch, dateOnly(DateTime.now())),
    );
    expect(
      find.text('at ${planLocation(date: DateTime.now(), meal: Meal.lunch)}'),
      findsOneWidget,
    );
  });

  testWidgets('Bắt đầu nấu mở Chuẩn bị nấu', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.prepTitle), findsOneWidget);
    expect(cookPrepLocation('trung'), '/recipe/trung/prep');
  });

  testWidgets('id không có: báo không tìm thấy, Về Khám phá', (tester) async {
    await _pump(tester, id: 'khong-co');

    expect(find.widgetWithText(EmptyState, CookStrings.notFoundTitle), findsOneWidget);
    await tester.tap(find.text(CookStrings.notFoundAction));
    await tester.pumpAndSettle();
    expect(find.text('at /'), findsOneWidget);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, theme $name: không tràn', (tester) async {
      await _pump(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.startCooking), findsOneWidget);
    });
  }
}
