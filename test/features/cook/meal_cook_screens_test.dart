import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fakes.dart';
import 'fixtures.dart';

/// Thứ Ba.
final _day = DateTime(2026, 10, 27);

/// Món tên dài cho bữa nhiều món (prototype tweak "tên dài, nhiều món").
final _longRecipes = [
  for (final (i, name) in const [
    'Đậu phụ non sốt cà chua nấm hương kiểu nhà làm',
    'Trứng chiên hành lá với thịt băm và mộc nhĩ',
    'Canh cà chua trứng nấu đậu phụ non và rau mùi',
    'Cơm rang dưa cải thịt bò kiểu sinh viên ký túc xá',
    'Canh bí đỏ nấu tôm khô với rau ngót',
  ].indexed)
    Recipe.fromJson({
      ...(i.isEven ? cookRecipeFixture : soupRecipeFixture).toJson(),
      'id': 'dai-$i',
      'name': name,
      'minutes': 30 - i,
    }),
];

/// Mở `/` (Khám phá giả có thanh Nấu tiếp) rồi push Nấu cả bữa tối thứ Ba gồm [planned].
Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
  List<Recipe> recipes = const [cookRecipeFixture, soupRecipeFixture],
  List<String> planned = const ['trung', 'canh'],
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
      recipesProvider.overrideWith((ref) async => recipes),
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
  for (final id in planned) {
    await plan.addToPlan(id, _day, Meal.dinner);
  }
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

/// Bấm nút bắt đầu [start] khi "Lấy đồ ra" chưa tick đủ: qua sheet hỏi lại bằng nút [confirm].
Future<void> _startAnyway(WidgetTester tester, String start, String confirm) async {
  await _tap(tester, find.text(start));
  expect(find.text(CookStrings.gatherConfirmTitle), findsOneWidget);
  await _tap(tester, find.text(confirm));
}

/// Nút [label] trong sheet hỏi lại (nút cùng chữ ở chân màn nằm dưới sheet).
Finder _inSheet(String label) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(label));

/// Bấm "Xong sơ chế" khi chưa tick đủ: qua sheet "Chưa sơ chế xong" bằng nút đồng ý.
Future<void> _finishPrepAnyway(WidgetTester tester) async {
  await _tap(tester, find.text(CookStrings.finishPrep));
  expect(find.text(CookStrings.prepConfirmTitle), findsOneWidget);
  await _tap(tester, _inSheet(CookStrings.finishPrep));
}

/// Ô tick ba trạng thái của việc cha (Hành lá).
Finder _parentBox(bool? value) => find.byWidgetPredicate(
  (w) => w is Checkbox && w.tristate && w.value == value,
);

void main() {
  testWidgets('Chuẩn bị: meta sơ chế/nấu, Lấy đồ ra hai tầng, kéo hoặc phím mũi tên đổi thứ tự', (
    tester,
  ) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async => announced.add('$message'),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        null,
      ),
    );
    final (container, _) = await _pump(tester);

    expect(find.text('Nấu bữa tối'), findsOneWidget);
    expect(find.text('Thứ Ba · 2 món · sơ chế ~8 phút, nấu ~27 phút'), findsOneWidget);
    expect(find.text(CookStrings.startPrep), findsOneWidget);
    // Tầng trên: tên và tổng lượng; tầng dưới: tag tên đầy đủ từng món, không còn tag "2 món".
    expect(find.text('Trứng gà'), findsOneWidget);
    expect(find.text('2,5 quả'), findsOneWidget);
    expect(find.text('1 quả'), findsOneWidget);
    expect(find.text('2 món'), findsNothing);
    expect(find.widgetWithText(MealGatherRow, 'Trứng chiên hành'), findsOneWidget);
    expect(find.widgetWithText(MealGatherRow, 'Canh cà chua trứng'), findsNWidgets(2));
    expect(find.text(CookStrings.useSuggestedOrder), findsNothing);

    // Tick thì tên gạch ngang.
    await _tap(tester, find.text('Trứng gà'));
    final egg = tester.widget<Text>(find.text('Trứng gà'));
    expect(egg.style?.decoration, TextDecoration.lineThrough);

    final handle = find.byTooltip(CookStrings.reorderLabel('Trứng chiên hành', 2));
    final drag = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await drag.moveBy(const Offset(0, -80));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.byTooltip(CookStrings.reorderLabel('Trứng chiên hành', 1)), findsOneWidget);
    expect(announced.join(), contains('Trứng chiên hành lên vị trí 1'));

    await _tap(tester, find.text(CookStrings.useSuggestedOrder));
    expect(find.byTooltip(CookStrings.reorderLabel('Canh cà chua trứng', 1)), findsOneWidget);

    // Phím mũi tên trên tay cầm.
    final grips = find.byIcon(Symbols.drag_indicator_rounded);
    Focus.of(tester.element(grips.last)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.byTooltip(CookStrings.reorderLabel('Trứng chiên hành', 1)), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.byTooltip(CookStrings.reorderLabel('Trứng chiên hành', 1)), findsOneWidget);
    expect(container.read(cookSessionProvider), isNull);
  });

  testWidgets('chưa lấy đủ đồ: hỏi lại, Lấy tiếp thì ở lại; lấy đủ thì vào thẳng Sơ chế', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);

    await _tap(tester, find.text(CookStrings.startPrep));
    final total = find.byType(MealGatherRow).evaluate().length;
    expect(find.text(CookStrings.gatherConfirmBody(0, total)), findsOneWidget);
    expect(find.text(CookStrings.confirmStartPrep), findsOneWidget);
    await _tap(tester, find.text(CookStrings.gatherConfirmBack));
    expect(find.text(CookStrings.gatherConfirmTitle), findsNothing);
    expect(container.read(cookSessionProvider), isNull);

    for (var i = 0; i < total; i++) {
      await _tap(tester, find.byType(MealGatherRow).at(i));
    }
    expect(find.text(CookStrings.gathered(total, total)), findsOneWidget);
    await _tap(tester, find.text(CookStrings.startPrep));
    expect(find.text(CookStrings.gatherConfirmTitle), findsNothing);
    expect(find.text('Bữa tối · sơ chế'), findsOneWidget);
  });

  testWidgets('chặng Sơ chế: ba kiểu việc, ô tick lửng, Xong sơ chế, Bước trước về Sơ chế', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);

    expect(find.text('Bữa tối · sơ chế'), findsOneWidget);
    expect(find.text('SƠ CHẾ CẢ BỮA · ~8 PHÚT'), findsOneWidget);
    expect(find.textContaining(CookStrings.prepTip.trim()), findsOneWidget);
    expect(find.text('0/4 việc'), findsOneWidget);
    // Một món: tag món, không phần lượng.
    expect(find.text('Bổ múi cau'), findsOneWidget);
    // Nhiều món cùng cách: một việc, cặp [Món] [~lượng].
    expect(find.text('Đập ra bát rồi đánh tan'), findsOneWidget);
    expect(find.text('~0,5 quả'), findsOneWidget);
    expect(find.text('~2 quả'), findsOneWidget);
    // Khác cách: việc cha có tổng lượng, việc con.
    expect(find.text('1,5 nắm'), findsOneWidget);
    expect(find.text('Cắt khúc'), findsOneWidget);
    expect(find.text('Thái nhỏ'), findsOneWidget);
    expect(_parentBox(false), findsOneWidget);

    await _tap(tester, find.text('Cắt khúc'));
    expect(_parentBox(null), findsOneWidget);
    expect(find.text('1/4 việc'), findsOneWidget);
    await _tap(tester, find.text('Thái nhỏ'));
    expect(_parentBox(true), findsOneWidget);
    final cut = tester.widget<Text>(find.text('Cắt khúc'));
    expect(cut.style?.decoration, TextDecoration.lineThrough);
    await _tap(tester, find.text('Hành lá'));
    expect(_parentBox(false), findsOneWidget);
    await _tap(tester, find.text('Hành lá'));
    expect(find.text('2/4 việc'), findsOneWidget);

    // Chưa tick đủ: hỏi lại, Làm tiếp thì ở lại; đồng ý thì tick hết rồi vào món 1.
    await _tap(tester, find.text(CookStrings.finishPrep));
    expect(find.text(CookStrings.prepConfirmTitle), findsOneWidget);
    expect(find.text(CookStrings.prepConfirmBody(2, 4)), findsOneWidget);
    await _tap(tester, find.text(CookStrings.keepPrepping));
    expect(find.text(CookStrings.prepConfirmTitle), findsNothing);
    expect(find.text('Bữa tối · sơ chế'), findsOneWidget);
    expect(find.text('2/4 việc'), findsOneWidget);
    await _finishPrepAnyway(tester);
    expect(find.text('Bữa tối · món 1/2'), findsOneWidget);
    expect(find.text('CANH CÀ CHUA TRỨNG · BƯỚC 1/3'), findsOneWidget);
    expect(find.text('Xào cà chua'), findsOneWidget);
    expect(container.read(cookSessionProvider)!.prepDone, hasLength(4));
    // Tab Sơ chế báo xong thay cho "4/4 việc".
    expect(find.text(CookStrings.finish), findsOneWidget);

    await _tap(tester, find.text(CookStrings.previousStep));
    expect(find.text('SƠ CHẾ CẢ BỮA · ~8 PHÚT'), findsOneWidget);
    expect(_parentBox(true), findsOneWidget);
    await _tap(tester, find.text('1. Canh cà chua trứng'));
    expect(find.text('Xào cà chua'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.prepTab));
    expect(find.text('Bữa tối · sơ chế'), findsOneWidget);
    expect(container.read(cookSessionProvider)!.inPrep, isTrue);
  });

  testWidgets('nấu cả bữa: Xong món 1, thoát rồi Nấu tiếp, Xong cả bữa, chấm, xong', (
    tester,
  ) async {
    final (container, router) = await _pump(tester);

    await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
    await _finishPrepAnyway(tester);
    expect(find.text('1. Canh cà chua trứng'), findsOneWidget);
    expect(find.text('Bước 1/3'), findsOneWidget);
    expect(find.text('3 bước'), findsOneWidget);

    await _tap(tester, find.text(CookStrings.nextStep));
    await _tap(tester, find.text('Hẹn 5 phút', skipOffstage: false));
    await _tap(tester, find.text(CookStrings.nextStep));
    await _tap(tester, find.text(CookStrings.finishDish(1)));
    expect(find.text('TRỨNG CHIÊN HÀNH · BƯỚC 1/3'), findsOneWidget);
    expect(find.text('Làm nóng dầu'), findsOneWidget);
    // Tab Sơ chế và món 1 đều "Xong".
    expect(find.text(CookStrings.finish), findsNWidgets(2));
    // Đồng hồ món canh vẫn chạy khi sang món trứng.
    expect(find.text('Canh cà chua trứng · Bước 2'), findsOneWidget);

    await _tap(tester, find.text(CookStrings.ingredients));
    expect(find.text('Nguyên liệu · Trứng chiên hành · 1 người'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.close));

    await _tap(tester, find.byTooltip(CookStrings.exitCooking));
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('Trứng chiên hành · bước 1/3'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.resumeAction));
    expect(find.text('Bữa tối · món 2/2'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await _tap(tester, find.text(CookStrings.nextStep));
    }
    // Mọi món khác đã xong: không hỏi lại.
    await _tap(tester, find.text(CookStrings.finishMeal));
    expect(find.text(CookStrings.mealConfirmTitle), findsNothing);
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

  testWidgets('sơ chế đã tick đủ: Xong sơ chế vào thẳng món 1, không hỏi lại', (tester) async {
    await _pump(tester);
    await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
    for (final task in ['Bổ múi cau', 'Đập ra bát rồi đánh tan', 'Hành lá']) {
      await _tap(tester, find.text(task));
    }
    expect(find.text(CookStrings.finish), findsOneWidget);
    await _tap(tester, find.text(CookStrings.finishPrep));
    expect(find.text(CookStrings.prepConfirmTitle), findsNothing);
    expect(find.text('Bữa tối · món 1/2'), findsOneWidget);
  });

  testWidgets(
    'Xong cả bữa khi món 1 chưa xong: hỏi lại, Nấu tiếp thì ở lại, đồng ý thì sang Hoàn thành',
    (
      tester,
    ) async {
      final (container, _) = await _pump(tester);
      await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
      await _finishPrepAnyway(tester);
      await _tap(tester, find.text('2. Trứng chiên hành'));
      for (var i = 0; i < 2; i++) {
        await _tap(tester, find.text(CookStrings.nextStep));
      }
      await _tap(tester, find.text(CookStrings.finishMeal));
      expect(find.text(CookStrings.mealConfirmTitle), findsOneWidget);
      expect(find.text(CookStrings.mealConfirmBody(['Canh cà chua trứng'])), findsOneWidget);
      await _tap(tester, find.text(CookStrings.keepCooking));
      expect(find.text(CookStrings.mealConfirmTitle), findsNothing);
      expect(find.text('Bữa tối · món 2/2'), findsOneWidget);
      expect(container.read(cookSessionProvider)!.finished, isEmpty);

      await _tap(tester, find.text(CookStrings.finishMeal));
      await _tap(tester, find.text(CookStrings.confirmFinishMeal));
      expect(find.text('Xong bữa tối! Ăn ngon nhé'), findsOneWidget);
      expect(find.byTooltip('Ngon · Canh cà chua trứng'), findsOneWidget);
    },
  );

  testWidgets('thoát ở chặng Sơ chế: Nấu tiếp mở lại đúng chặng, giữ việc đã tick', (tester) async {
    final (_, router) = await _pump(tester);
    await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
    await _tap(tester, find.text('Bổ múi cau'));
    await _tap(tester, find.byTooltip(CookStrings.exitCooking));
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('Bữa tối · sơ chế'), findsOneWidget);
    await _tap(tester, find.text(CookStrings.resumeAction));
    expect(find.text('SƠ CHẾ CẢ BỮA · ~8 PHÚT'), findsOneWidget);
    expect(find.text('1/4 việc'), findsOneWidget);
  });

  testWidgets('bữa không có gì để sơ chế: nút Bắt đầu: món đầu, không có tab Sơ chế', (
    tester,
  ) async {
    Recipe noPrep(Recipe r) => Recipe.fromJson({
      ...r.toJson(),
      'prepMinutes': null,
      'steps': [
        for (final s in r.steps) {'text': s.text, 'timerSeconds': ?s.timerSeconds},
      ],
    });
    await _pump(
      tester,
      recipes: [noPrep(cookRecipeFixture), noPrep(soupRecipeFixture)],
    );
    expect(find.text('Thứ Ba · 2 món · khoảng 35 phút · Bếp từ'), findsOneWidget);
    await _startAnyway(
      tester,
      'Bắt đầu: Canh cà chua trứng',
      CookStrings.confirmStartCooking,
    );
    expect(find.text(CookStrings.prepTab), findsNothing);
    expect(find.text('CANH CÀ CHUA TRỨNG · BƯỚC 1/4'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, CookStrings.previousStep)).onPressed,
      isNull,
    );
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
    testWidgets('360dp, chữ 1.3, theme $name: bốn chặng không tràn', (tester) async {
      await _pump(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      expect(tester.takeException(), isNull);
      await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
      await _tap(tester, find.text('Cắt khúc'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.finishPrep));
      expect(tester.takeException(), isNull);
      await _tap(tester, _inSheet(CookStrings.finishPrep));
      await _tap(tester, find.text(CookStrings.nextStep));
      await _tap(tester, find.text('Hẹn 5 phút', skipOffstage: false));
      expect(tester.takeException(), isNull);
      // Nhảy sang món 2, nấu hết: Xong cả bữa hỏi lại vì món 1 chưa xong.
      await _tap(tester, find.text('2. Trứng chiên hành'));
      for (var i = 0; i < 2; i++) {
        await _tap(tester, find.text(CookStrings.nextStep));
      }
      await _tap(tester, find.text(CookStrings.finishMeal));
      expect(find.text(CookStrings.mealConfirmTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.confirmFinishMeal));
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.finishAndUpdate), findsOneWidget);
    });

    testWidgets('tên món dài, 5 món, 360dp, chữ 1.3, theme $name: không tràn', (tester) async {
      await _pump(
        tester,
        theme: theme,
        size: const Size(360, 640),
        textScale: 1.3,
        recipes: _longRecipes,
        planned: [for (final r in _longRecipes) r.id],
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_longRecipes.first.name), findsWidgets);
      await _startAnyway(tester, CookStrings.startPrep, CookStrings.confirmStartPrep);
      expect(tester.takeException(), isNull);
      // Tag món tên đầy đủ, tự xuống dòng; cặp [Món] [~lượng] khi nhiều món cùng cách làm.
      expect(find.text(_longRecipes[1].name), findsWidgets);
      await _finishPrepAnyway(tester);
      expect(tester.takeException(), isNull);
      // Nhãn hẹn giờ "<tên dài> · Bước 1" cắt "…", không đẩy nút Dừng.
      await _tap(tester, find.text('Hẹn 1 phút'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.nextStep));
      await _tap(tester, find.text(CookStrings.nextStep));
      expect(find.text(CookStrings.finishDish(1)), findsOneWidget);
      await _tap(tester, find.text(CookStrings.finishDish(1)));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.ingredients));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text(CookStrings.close));
      // Tab món cuối (ngoài màn) bấm được nhờ dải cuộn ngang.
      await _tap(tester, find.textContaining('5. '));
      expect(find.text('Bữa tối · món 5/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
