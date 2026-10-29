import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fakes.dart';
import 'fixtures.dart';

class _Env {
  final wakelock = FakeWakelock();
  final notifications = FakeNotificationService();
  var now = DateTime(2026, 10, 26, 18);
  late ProviderContainer container;
}

/// Mở Khám phá giả có `ResumeCookingBanner`; [step] thì mở sẵn phiên ở bước đó rồi vào Từng bước,
/// [notes] thì ở trang Lưu ý.
Future<_Env> _pump(
  WidgetTester tester, {
  int? step = 0,
  bool notes = false,
  Recipe recipe = cookRecipeFixture,
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  final env = _Env();
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: ListView(children: const [ResumeCookingBanner()])),
      ),
      ...cookRoutes,
    ],
  );
  addTearDown(router.dispose);
  env.container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => [recipe]),
      ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
      cookClockProvider.overrideWithValue(() => env.now),
      wakelockProvider.overrideWithValue(env.wakelock),
      notificationServiceProvider.overrideWithValue(env.notifications),
      appInForegroundProvider.overrideWithValue(() => true),
      cookRandomProvider.overrideWithValue(FakeRandom()),
    ],
  );
  addTearDown(env.container.dispose);
  if (step != null) {
    final sessions = env.container.read(cookSessionProvider.notifier);
    await sessions.startRecipe('trung', 2);
    await sessions.goTo(0, step);
    if (notes) await sessions.showNotes();
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: env.container,
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
  if (step != null) {
    router.push(cookStepLocation('trung'));
    await tester.pumpAndSettle();
  }
  return env;
}

void main() {
  testWidgets('hiện bước, tiến độ, chữ lớn; qua bước tới Xong rồi sang Hoàn thành', (tester) async {
    final env = await _pump(tester);

    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(find.text(CookStrings.keepScreenOn), findsOneWidget);
    expect(find.text('BƯỚC 1'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Đánh trứng với hành'));
    expect((text.style?.fontSize, text.style?.height), (24, 34 / 24));
    expect(env.wakelock.enabled, isTrue);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(CookStrings.nextStep));
      await tester.pumpAndSettle();
    }
    expect(find.text('Bước 4/4'), findsOneWidget);
    // Bước cuối chưa có Xong: Bước tiếp sang trang Lưu ý.
    expect(find.text(CookStrings.finish), findsNothing);

    await tester.tap(find.text(CookStrings.previousStep));
    await tester.pumpAndSettle();
    expect(find.text('Chiên mặt dưới'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(CookStrings.nextStep));
      await tester.pumpAndSettle();
    }

    expect(find.text(CookStrings.notesTitle), findsOneWidget);
    expect(find.text(CookStrings.notesLabel), findsOneWidget);
    expect(find.text('Ăn nóng với cơm.'), findsOneWidget);
    expect(find.text('Chấm thêm nước mắm nếu thích.'), findsOneWidget);
    expect(find.text(CookStrings.cheers[0]), findsOneWidget);
    expect(find.text(CookStrings.nextStep), findsNothing);

    await tester.tap(find.text(CookStrings.previousStep));
    await tester.pumpAndSettle();
    expect(find.text('Lật trứng, xúc ra đĩa'), findsOneWidget);
    expect(find.text(CookStrings.cheers[0]), findsNothing);
    await tester.tap(find.text(CookStrings.nextStep));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CookStrings.finish));
    await tester.pumpAndSettle();
    expect(env.container.read(cookSessionProvider)!.isDone, isTrue);
    expect(find.text(CookStrings.doneTitle), findsOneWidget);
    expect(env.wakelock.enabled, isFalse);
  });

  testWidgets('hẹn giờ: chạy tiếp khi sang bước khác, hết giờ thì báo Xong', (tester) async {
    final env = await _pump(tester, step: 1);

    await tester.tap(find.text('Hẹn 1 phút'));
    await tester.pump();
    expect(find.text('01:00'), findsOneWidget);
    expect(env.notifications.timers.keys, [cookTimerKey(0, 1)]);

    await tester.tap(find.text(CookStrings.nextStep));
    await tester.pump();
    // Bước 3 có đồng hồ riêng; đồng hồ bước 2 đang chạy vẫn hiện.
    expect(find.text('Hẹn 3 phút'), findsOneWidget);
    expect(find.text('Bước 2'), findsOneWidget);

    env.now = env.now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Xong!'), findsOneWidget);
    expect(env.notifications.timers, isEmpty);

    await tester.tap(find.text('Tắt'));
    await tester.pump();
    expect(find.text('Bước 2'), findsNothing);
    expect(find.byType(StepTimer, skipOffstage: false), findsNWidgets(2));
  });

  testWidgets('thoát khi đồng hồ đang chạy, Nấu tiếp thì đồng hồ chạy tiếp', (tester) async {
    final env = await _pump(tester, step: 1);
    await tester.tap(find.text('Hẹn 1 phút'));
    await tester.pump();
    await tester.tap(find.byTooltip(CookStrings.exitCooking));
    await tester.pumpAndSettle();

    env.now = env.now.add(const Duration(seconds: 20));
    await tester.tap(find.text(CookStrings.resumeAction));
    await tester.pumpAndSettle();
    expect(find.text('00:40'), findsOneWidget);
    expect(find.text('Dừng'), findsOneWidget);
  });

  testWidgets('sheet Nguyên liệu theo khẩu phần, gia vị Vừa đủ', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(CookStrings.ingredients));
    await tester.pumpAndSettle();
    expect(find.text('Nguyên liệu · 2 người'), findsOneWidget);
    expect(find.text('4 quả'), findsOneWidget);
    expect(find.text('Dầu ăn, tiêu'), findsOneWidget);
    expect(find.text(CookStrings.enough), findsOneWidget);

    await tester.tap(find.text(CookStrings.close));
    await tester.pumpAndSettle();
    expect(find.text('Nguyên liệu · 2 người'), findsNothing);
  });

  testWidgets('thoát giữ phiên; Nấu tiếp ở Khám phá mở lại đúng bước', (tester) async {
    await _pump(tester, step: 1);

    await tester.tap(find.byTooltip(CookStrings.exitCooking));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.resumeTitle), findsOneWidget);
    expect(find.text('Trứng chiên hành · bước 2/4'), findsOneWidget);

    await tester.tap(find.text(CookStrings.resumeAction));
    await tester.pumpAndSettle();
    expect(find.text('Bước 2/4'), findsOneWidget);
  });

  testWidgets('món không có lưu ý: hiện Món ăn không có lưu ý nào.', (tester) async {
    await _pump(
      tester,
      step: 3,
      notes: true,
      recipe: Recipe.fromJson({...cookRecipeFixture.toJson(), 'notes': <String>[]}),
    );
    expect(find.text(CookStrings.noNotes), findsOneWidget);
    expect(find.text(CookStrings.cheers[0]), findsOneWidget);
    expect(find.text(CookStrings.finish), findsOneWidget);
  });

  testWidgets('thoát ở trang Lưu ý: thanh Nấu tiếp ghi lưu ý, mở lại đúng trang', (tester) async {
    await _pump(tester, step: 3, notes: true);
    await tester.tap(find.byTooltip(CookStrings.exitCooking));
    await tester.pumpAndSettle();
    expect(find.text('Trứng chiên hành · lưu ý'), findsOneWidget);

    await tester.tap(find.text(CookStrings.resumeAction));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.notesTitle), findsOneWidget);
  });

  testWidgets('không nấu dở thì không có thanh Nấu tiếp', (tester) async {
    await _pump(tester, step: null);
    expect(find.text(CookStrings.resumeTitle), findsNothing);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, theme $name: không tràn', (tester) async {
      await _pump(tester, step: 2, theme: theme, size: const Size(360, 640), textScale: 1.3);
      await tester.tap(find.text('Hẹn 3 phút'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.nextStep), findsOneWidget);

      // Trang Lưu ý: đồng hồ đang chạy vẫn hiện, câu chúc và nút Xong không tràn.
      await tester.tap(find.text(CookStrings.nextStep));
      await tester.pump();
      await tester.tap(find.text(CookStrings.nextStep));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.notesTitle), findsOneWidget);
      expect(find.text(CookStrings.cheers[0]), findsOneWidget);
      expect(find.text(CookStrings.finish), findsOneWidget);
    });
  }
}
