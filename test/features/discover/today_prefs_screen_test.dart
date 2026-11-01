import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/app_theme.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today_prefs/today_prefs_screen.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

Widget _wrapScreen({bool dark = false}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: todayPrefsLocation,
        builder: (_, _) => const TodayPrefsScreen(),
      ),
      GoRoute(
        path: todayLocation,
        builder: (_, _) => const Scaffold(body: Text('Today')),
      ),
    ],
    initialLocation: todayPrefsLocation,
  );
  return ProviderScope(
    overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    child: MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('hiện đủ 3 nhóm: Quy mô, Thời gian, Cảm giác', (tester) async {
    await tester.pumpWidget(_wrapScreen());
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.prefsScaleLabel), findsOneWidget);
    expect(find.text(DiscoverStrings.prefsTimeLabel), findsOneWidget);
    // Cuộn xuống để thấy "Cảm giác"
    await tester.scrollUntilVisible(
      find.text(DiscoverStrings.prefsFeel),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(DiscoverStrings.prefsFeel), findsOneWidget);
  });

  testWidgets('badge "Chưa bật" xuất hiện bên cạnh Theo thời tiết', (tester) async {
    await tester.pumpWidget(_wrapScreen());
    await tester.pumpAndSettle();

    // Cuộn xuống để thấy nhóm Cảm giác
    await tester.scrollUntilVisible(
      find.text(DiscoverStrings.prefsFeelWeather),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(DiscoverStrings.prefsFeelWeather), findsOneWidget);
    expect(find.text(DiscoverStrings.prefsFeelWeatherDisabled), findsOneWidget);
  });

  testWidgets('mở Thêm tiêu chí thì hiện chip tag', (tester) async {
    // Dùng màn cao hơn để ít phải cuộn
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapScreen());
    await tester.pumpAndSettle();

    // Ban đầu chưa mở: chip Hệ cuối tháng chưa có
    expect(find.text(DiscoverStrings.prefsTagCheap), findsNothing);

    // Mở more section
    expect(find.text(DiscoverStrings.prefsMore(0)), findsOneWidget);
    await tester.tap(find.text(DiscoverStrings.prefsMore(0)));
    await tester.pumpAndSettle();

    // Giờ chip hiện ra
    expect(find.text(DiscoverStrings.prefsTagCheap), findsOneWidget);

    // Chọn chip
    await tester.tap(find.text(DiscoverStrings.prefsTagCheap));
    await tester.pumpAndSettle();

    // Nhãn đổi thành (1)
    expect(find.text(DiscoverStrings.prefsMore(1)), findsOneWidget);
  });

  testWidgets('nhãn CTA đổi khi đổi quy mô', (tester) async {
    await tester.pumpWidget(_wrapScreen());
    await tester.pumpAndSettle();

    // Mặc định: two → "cơm nhà 2 món"
    expect(find.text(DiscoverStrings.prefsCta('cơm nhà 2 món')), findsOneWidget);

    // Chọn "1 món gọn lẹ"
    await tester.tap(find.text(DiscoverStrings.prefsScaleOne));
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.prefsCta('1 món gọn lẹ')), findsOneWidget);

    // Chọn "mâm cơm"
    await tester.tap(find.text(DiscoverStrings.prefsScaleTray));
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.prefsCta('mâm cơm')), findsOneWidget);
  });

  testWidgets('hiển thị đúng trên theme tối', (tester) async {
    await tester.pumpWidget(_wrapScreen(dark: true));
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.prefsTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(DiscoverStrings.prefsFeelWeatherDisabled),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(DiscoverStrings.prefsFeelWeatherDisabled), findsOneWidget);
  });
}
