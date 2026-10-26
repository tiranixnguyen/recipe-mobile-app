import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fakes.dart';
import 'fixtures.dart';

/// Thứ Ba.
final _day = DateTime(2026, 10, 27);

/// Mở `/` (Khám phá giả có thanh Nấu tiếp) rồi push Nấu cả bữa tối thứ Ba.
Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: ListView(children: const [ResumeCookingBanner()])),
      ),
      GoRoute(path: '/plan', builder: (_, _) => const Text('at plan')),
      GoRoute(path: shoppingLocation, builder: (_, _) => const Text('at shopping')),
      ...cookRoutes,
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [cookRecipeFixture, soupRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
      cookClockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 18)),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      appInForegroundProvider.overrideWithValue(() => true),
      appReviewProvider.overrideWithValue(FakeAppReview()),
    ],
  );
  addTearDown(container.dispose);
  final plan = container.read(plannedMealsProvider.notifier);
  await plan.addToPlan('trung', _day, Meal.dinner);
  await plan.addToPlan('canh', _day, Meal.dinner);
  for (final id in ['egg', 'tomato']) {
    await container.read(pantryItemsProvider.notifier).addToPantry(id);
  }
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
  router.push(mealCookLocation(_day, Meal.dinner));
  await tester.pumpAndSettle();
  return (container, router);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Chuẩn bị: thứ tự gợi ý, tag món, đổi thứ tự thì hiện Dùng thứ tự gợi ý', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);

    expect(find.text('Nấu bữa tối'), findsOneWidget);
    expect(find.text('Thứ Ba · 2 món · khoảng 35 phút · Bếp từ'), findsOneWidget);
    expect(find.text('Bắt đầu: Canh cà chua trứng'), findsOneWidget);
    expect(find.text('Trứng gà · 2,5 quả'), findsOneWidget);
    expect(find.text('2 món'), findsOneWidget);
    expect(find.text('Cà chua · 1 quả'), findsOneWidget);
    expect(find.text(CookStrings.useSuggestedOrder), findsNothing);

    final handle = find.byTooltip(CookStrings.reorderLabel('Trứng chiên hành', 2));
    final drag = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await drag.moveBy(const Offset(0, -80));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu: Trứng chiên hành'), findsOneWidget);

    await _tap(tester, find.text(CookStrings.useSuggestedOrder));
    expect(find.text('Bắt đầu: Canh cà chua trứng'), findsOneWidget);
    expect(container.read(cookSessionProvider), isNull);
  });

  testWidgets('nấu cả bữa: tab món, Sang món 2, thoát rồi Nấu tiếp, Xong cả bữa, chấm, xong', (
    tester,
  ) async {
    final (container, router) = await _pump(tester);

    await _tap(tester, find.text('Bắt đầu: Canh cà chua trứng'));
    expect(find.text('Bữa tối · món 1/2'), findsOneWidget);
    expect(find.text('CANH CÀ CHUA TRỨNG · BƯỚC 1/3'), findsOneWidget);
    expect(find.text('1. Canh cà chua trứng'), findsOneWidget);
    expect(find.text('Bước 1/3'), findsOneWidget);
    expect(find.text('4 bước'), findsOneWidget);

    await _tap(tester, find.text(CookStrings.nextStep));
    await _tap(tester, find.text('Hẹn 5 phút', skipOffstage: false));
    await _tap(tester, find.text(CookStrings.nextStep));
    await _tap(tester, find.text('Sang món 2: Trứng chiên hành'));
    expect(find.text('TRỨNG CHIÊN HÀNH · BƯỚC 1/4'), findsOneWidget);
    expect(find.text(CookStrings.finish), findsOneWidget);
    // Đồng hồ món canh vẫn chạy khi sang món trứng.
    expect(find.text('Canh cà chua trứng · Bước 2'), findsOneWidget);

    await _tap(tester, find.text(CookStrings.ingredients));
    expect(find.text('Nguyên liệu · Trứng chiên hành · 1 người'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.close));

    await _tap(tester, find.byTooltip(CookStrings.exitCooking));
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('Trứng chiên hành · bước 1/4'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.resumeAction));
    expect(find.text('Bữa tối · món 2/2'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await _tap(tester, find.text(CookStrings.nextStep));
    }
    await _tap(tester, find.text(CookStrings.finishMeal));
    expect(find.text('Xong bữa tối! Ăn ngon nhé'), findsOneWidget);
    expect(find.text('2 món · 1 người · khoảng 35 phút'), findsOneWidget);
    expect(find.text('Đã dùng 2,5 quả · 2 món'), findsOneWidget);

    await _tap(tester, find.byTooltip('Ngon · Canh cà chua trứng'));
    expect(find.text('Bạn chấm: Ngon'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel(CookStrings.usedUpLabel('Cà chua')));
    await _tap(tester, find.text(CookStrings.finishAndUpdate));

    expect(container.read(pantryItemsProvider), {'egg'});
    expect(container.read(cookHistoryProvider), hasLength(2));
    expect(container.read(plannedMealsProvider).every((p) => p.cooked), isTrue);
    expect(find.text(CookStrings.resumeTitle), findsNothing);
  });

  testWidgets('không có phiên cả bữa: Từng bước mời mở Thực đơn', (tester) async {
    final (_, router) = await _pump(tester);
    router.go(mealCookStepLocation);
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.noMealTitle), findsOneWidget);
    await _tap(tester, find.text(CookStrings.toPlan));
    expect(find.text('at plan'), findsOneWidget);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('360dp, chữ 1.3, theme $name: ba màn không tràn', (tester) async {
      await _pump(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Bắt đầu: Canh cà chua trứng'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.nextStep));
      await _tap(tester, find.text('Hẹn 5 phút', skipOffstage: false));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.nextStep));
      await _tap(tester, find.text('Sang món 2: Trứng chiên hành'));
      for (var i = 0; i < 3; i++) {
        await _tap(tester, find.text(CookStrings.nextStep));
      }
      await _tap(tester, find.text(CookStrings.finishMeal));
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.finishAndUpdate), findsOneWidget);
    });
  }
}
