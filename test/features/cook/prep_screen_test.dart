import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import '../system/fake_notification_plugin.dart';
import 'fakes.dart';
import 'fixtures.dart';

/// Mở Chuẩn bị nấu trên màn `/recipe/trung` giả (để có chỗ quay lại).
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool permitted = true,
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('at /')),
      GoRoute(path: shoppingLocation, builder: (_, _) => const Text('at shopping')),
      GoRoute(
        path: notifPermissionLocation,
        builder: (context, _) => TextButton(
          onPressed: () => context.pop(false),
          child: const Text('at notif'),
        ),
      ),
      ...cookRoutes,
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
      notificationPluginProvider.overrideWithValue(FakeNotificationPlugin(permitted: permitted)),
      wakelockProvider.overrideWithValue(FakeWakelock()),
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
  router.push(cookPrepLocation('trung'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('hiện tiêu đề, khẩu phần, thông tin món, checklist, đồ thiếu', (tester) async {
    await _pump(tester);

    expect(find.text(CookStrings.prepTitle), findsOneWidget);
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text('1 người'), findsOneWidget);
    expect(find.text('15 phút · 4 bước'), findsOneWidget);
    expect(find.text('Bếp từ'), findsOneWidget);
    expect(find.text('Trứng gà · 2 quả'), findsOneWidget);
    expect(find.text('Dầu ăn, tiêu'), findsOneWidget);
    expect(find.text('Đã lấy 0/2'), findsOneWidget);
    expect(find.widgetWithText(AvailabilityBadge, 'Thiếu: hành lá, ớt'), findsOneWidget);
    expect(find.text('Không có cũng được, hoặc thay bằng chút ớt bột.'), findsOneWidget);
  });

  testWidgets('đổi khẩu phần thì lượng đổi; tick thì đếm và gạch ngang', (tester) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('Thêm một người'));
    await tester.pump();
    expect(find.text('2 người'), findsOneWidget);
    expect(find.text('Trứng gà · 4 quả'), findsOneWidget);

    await tester.tap(find.text('Trứng gà · 4 quả'));
    await tester.pump();
    expect(find.text('Đã lấy 1/2'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Trứng gà · 4 quả'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Thêm vào đi chợ: thêm món rồi mở Đi chợ', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.text(CookStrings.addToShopping));
    await tester.pumpAndSettle();
    expect(container.read(shoppingProvider).single.recipeId, 'trung');
    expect(find.text('at shopping'), findsOneWidget);
  });

  testWidgets('đã lấy đủ đồ: Bắt đầu nấu mở phiên rồi sang Từng bước, thay màn Chuẩn bị', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.text('Trứng gà · 2 quả'));
    await tester.tap(find.text('Dầu ăn, tiêu'));
    await tester.pump();
    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.gatherConfirmTitle), findsNothing);
    expect(container.read(cookSessionProvider)?.currentDish.recipeId, 'trung');
    expect(find.text('Bước 1/4'), findsOneWidget);

    await tester.tap(find.byTooltip(CookStrings.exitCooking));
    await tester.pumpAndSettle();
    expect(find.text('at /'), findsOneWidget);
  });

  testWidgets('chưa có quyền thông báo: hỏi quyền trước rồi mới nấu', (tester) async {
    final container = await _pump(tester, permitted: false);

    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CookStrings.confirmStartCooking));
    await tester.pumpAndSettle();
    expect(find.text('at notif'), findsOneWidget);
    expect(container.read(cookSessionProvider), isNull);

    await tester.tap(find.text('at notif'));
    await tester.pumpAndSettle();
    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(container.read(cookSessionProvider), isNotNull);
  });

  testWidgets('chưa lấy đủ đồ: hỏi lại; Lấy tiếp thì ở lại, Vẫn bắt đầu nấu thì vào nấu', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.text('Trứng gà · 2 quả'));
    await tester.pump();
    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.gatherConfirmTitle), findsOneWidget);
    expect(find.text(CookStrings.gatherConfirmBody(1, 2)), findsOneWidget);

    await tester.tap(find.text(CookStrings.gatherConfirmBack));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.gatherConfirmTitle), findsNothing);
    expect(find.text('Đã lấy 1/2'), findsOneWidget);
    expect(container.read(cookSessionProvider), isNull);

    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CookStrings.confirmStartCooking));
    await tester.pumpAndSettle();
    expect(container.read(cookSessionProvider)?.currentDish.recipeId, 'trung');
    expect(find.text('Bước 1/4'), findsOneWidget);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, theme $name: màn và sheet hỏi lại không tràn', (tester) async {
      await _pump(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(CookStrings.startCooking));
      await tester.pumpAndSettle();
      expect(find.text(CookStrings.confirmStartCooking), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
