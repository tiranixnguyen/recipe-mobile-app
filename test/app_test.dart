import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/app/app.dart';
import 'package:recipe_mobile_app/app/splash_screen.dart';
import 'package:recipe_mobile_app/app/theme_preview_screen.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('lần đầu: Splash → Onboarding → Khám phá, chuyển được 4 tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.text('Phòng bạn có gì để nấu?'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Khám phá'), findsOneWidget);

    for (final label in ['Tủ đồ', 'Thực đơn', 'Đã lưu']) {
      await tester.tap(_tab(label));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, label), findsOneWidget);
    }
  });

  testWidgets('Onboarding: chọn dụng cụ, chế độ ăn rồi Xong thì lưu và vào Khám phá', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nồi cơm điện'));
    await tester.tap(find.text('Không ăn cay'));
    await tester.pump();
    await tester.tap(find.text('Xong, gợi ý món cho mình'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Khám phá'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
    expect(
      container.read(kitchenProfileProvider),
      const KitchenProfile(tools: {Tool.rice}, diets: {Diet.nospicy}),
    );
  });

  testWidgets('đã qua Onboarding: Splash vào thẳng Khám phá', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Phòng bạn có gì để nấu?'), findsNothing);
  });

  testWidgets('chưa qua Onboarding: mở thẳng route khác vẫn bị đưa về Onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    GoRouter.of(tester.element(find.byType(SplashScreen))).go('/pantry');
    await tester.pumpAndSettle();

    expect(find.text('Phòng bạn có gì để nấu?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('màn toàn màn hình mở bằng push, back về lại shell', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(NavigationBar))).push(searchLocation());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Khám phá'), findsOneWidget);
  });

  testWidgets('chọn theme Tối thì app dùng theme tối từ token', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(NavigationBar)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.dark.surface);
  });

  testWidgets('trang xem theme mở được trước Onboarding, có cả hai theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    GoRouter.of(tester.element(find.byType(SplashScreen))).go(themePreviewLocation);
    await tester.pumpAndSettle();

    expect(find.byType(ThemePreviewScreen), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
