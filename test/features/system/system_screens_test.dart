import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/feedback/feedback_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/notif_permission/notif_permission_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/policy/policy_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_screen.dart';
import 'package:recipe_mobile_app/features/system/system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_plugin.dart';

/// Cài đặt và các màn mở từ đó, trên router chỉ có route của feature Hệ thống.
Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  FakeNotificationPlugin? plugin,
}) async {
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
        notificationPluginProvider.overrideWithValue(plugin ?? FakeNotificationPlugin()),
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

  group('xin quyền thông báo', () {
    Future<Future<bool?>> openPermission(WidgetTester tester) async {
      final result = GoRouter.of(
        tester.element(find.byType(SettingsScreen)),
      ).push<bool>(notifPermissionLocation);
      await tester.pumpAndSettle();
      expect(find.byType(NotifPermissionScreen), findsOneWidget);
      return result;
    }

    testWidgets('Cho phép: xin quyền hệ thống, đóng màn với kết quả', (tester) async {
      final plugin = FakeNotificationPlugin(permitted: false);
      await _pumpSettings(tester, plugin: plugin);
      final result = await openPermission(tester);

      await tester.tap(find.text('Cho phép'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
      expect(plugin.permissionRequests, 1);
      expect(find.byType(NotifPermissionScreen), findsNothing);
    });

    testWidgets('Để sau: không xin quyền, ghi lại lúc hỏi', (tester) async {
      final plugin = FakeNotificationPlugin(permitted: false);
      await _pumpSettings(tester, plugin: plugin);
      final result = await openPermission(tester);

      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
      expect(plugin.permissionRequests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('system.notif.askedAt'), isNotNull);
    });
  });

  testWidgets('Cài đặt: bật nhắc bữa mà bị chặn quyền thì để tắt và báo', (tester) async {
    final plugin = FakeNotificationPlugin(permitted: false, grantOnRequest: false);
    final container = await _pumpSettings(tester, plugin: plugin);

    await tester.tap(find.text('Nhắc bữa theo thực đơn'));
    await tester.pumpAndSettle();

    expect(container.read(notificationPrefsProvider).mealReminder, isFalse);
    expect(
      find.text('Thông báo đang bị chặn. Bật lại trong cài đặt của điện thoại.'),
      findsOneWidget,
    );
    expect(find.text('Đổi giờ nhắc'), findsNothing);
  });

  testWidgets('Cài đặt: bật nhắc bữa rồi đổi giờ nhắc', (tester) async {
    final container = await _pumpSettings(tester);

    await tester.tap(find.text('Nhắc bữa theo thực đơn'));
    await tester.pumpAndSettle();
    expect(container.read(notificationPrefsProvider).mealReminder, isTrue);

    await _open(tester, 'Đổi giờ nhắc');
    await tester.tap(find.text('Trước bữa 1 tiếng'));
    await tester.pumpAndSettle();

    expect(
      container.read(notificationPrefsProvider).mealReminderLead,
      const Duration(minutes: 60),
    );
    expect(find.text('Trước bữa 1 tiếng'), findsOneWidget, reason: 'ghi chú dưới công tắc');
  });

  testWidgets('Góp ý: mở từ màn lỗi thì ghi sẵn mã lỗi; nút Gửi mở khi có nội dung', (
    tester,
  ) async {
    await _pumpSettings(tester);
    GoRouter.of(
      tester.element(find.byType(SettingsScreen)),
    ).push(feedbackForErrorLocation('ERR-0042'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackScreen), findsOneWidget);
    expect(find.textContaining('Mã lỗi: ERR-0042'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'Gửi góp ý')).onPressed,
      isNotNull,
    );
  });
}
