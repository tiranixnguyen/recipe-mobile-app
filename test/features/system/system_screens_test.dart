import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/policy/policy_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_screen.dart';
import 'package:recipe_mobile_app/features/system/system.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt và các màn mở từ đó, trên router chỉ có route của feature Hệ thống.
Future<ProviderContainer> _pumpSettings(WidgetTester tester) async {
  // Màn điện thoại 390×844 như prototype, để Cài đặt hiện gần hết các hàng.
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'system.onboarded': 'true'});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(initialLocation: settingsLocation, routes: systemRoutes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => SharedPrefsLocalStore(prefs)),
        appVersionProvider.overrideWith((ref) async => '0.1.0'),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
}

Future<void> _open(WidgetTester tester, String row) async {
  await tester.scrollUntilVisible(find.text(row), 200);
  await tester.ensureVisible(find.text(row));
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

AppButton _deleteButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Xoá hết'));

void main() {
  testWidgets('Giới thiệu: phiên bản thật, mở được Chính sách', (tester) async {
    await _pumpSettings(tester);
    await _open(tester, 'Giới thiệu');

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Phiên bản 0.1.0'), findsOneWidget);

    await _open(tester, 'Chính sách quyền riêng tư');
    expect(find.byType(PolicyScreen), findsOneWidget);
    expect(find.textContaining('Firebase của Google'), findsOneWidget);
  });

  testWidgets('Xoá dữ liệu: nút khoá tới khi gõ đúng, xoá xong về Onboarding', (tester) async {
    final container = await _pumpSettings(tester);
    await _open(tester, 'Xoá dữ liệu trên máy');

    expect(find.byType(ClearDataScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget, reason: 'hộp thoại đè lên Cài đặt');
    expect(_deleteButton(tester).onPressed, isNull);
    expect(find.text('Nút Xoá hết đang khoá để tránh bấm nhầm.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'confirm delete');
    await tester.pump();
    expect(_deleteButton(tester).onPressed, isNull);
    expect(find.text('Chưa khớp, gõ đúng chữ in hoa và dấu cách.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'CONFIRM DELETE');
    await tester.pump();
    expect(_deleteButton(tester).onPressed, isNotNull);
    expect(find.text('Đã khớp. Giờ bạn có thể bấm Xoá hết.'), findsOneWidget);

    await tester.tap(find.text('Xoá hết'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(container.read(onboardingDoneProvider), isFalse);
  });

  testWidgets('Xoá dữ liệu: Huỷ thì đóng hộp thoại, không xoá', (tester) async {
    final container = await _pumpSettings(tester);
    await _open(tester, 'Xoá dữ liệu trên máy');

    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();

    expect(find.byType(ClearDataScreen), findsNothing);
    expect(container.read(onboardingDoneProvider), isTrue);
  });
}
