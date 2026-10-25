import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/feedback/feedback_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/notif_permission/notif_permission_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/policy/policy_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_screen.dart';
import 'package:recipe_mobile_app/features/system/routes.dart';
import 'package:recipe_mobile_app/features/system/system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_plugin.dart';

/// Màn điện thoại 390×844 như prototype, để Cài đặt hiện gần hết các hàng.
const _phone = Size(390, 844);

/// Màn nhỏ nhất cần hỗ trợ (360dp).
const _small = Size(360, 640);

/// Các màn của feature Hệ thống trên router chỉ có route của feature này (thêm Khám phá giả để
/// Onboarding có chỗ đi tới).
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String initialLocation = settingsLocation,
  bool onboarded = true,
  Size size = _phone,
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.light,
  FakeNotificationPlugin? plugin,
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'system.onboarded': 'true',
    'system.themeMode': themeMode.name,
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ...systemRoutes,
      GoRoute(path: discoverLocation, builder: (_, _) => const Text('Khám phá')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => SharedPrefsLocalStore(prefs)),
        appVersionProvider.overrideWith((ref) async => '0.1.0'),
        notificationPluginProvider.overrideWithValue(plugin ?? FakeNotificationPlugin()),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ref.watch(themeModeProvider),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Consumer).first));
}

Future<ProviderContainer> _pumpSettings(WidgetTester tester, {FakeNotificationPlugin? plugin}) =>
    _pump(tester, plugin: plugin);

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

  testWidgets('Onboarding lần đầu: chọn dụng cụ, chế độ ăn, Xong thì lưu hồ sơ và vào app', (
    tester,
  ) async {
    final container = await _pump(tester, initialLocation: onboardingLocation, onboarded: false);

    await tester.tap(find.text(Tool.rice.label));
    await tester.tap(find.text(Tool.kettle.label));
    await tester.tap(find.text(Diet.values.first.label));
    await tester.pump();
    await tester.tap(find.text('Xong, gợi ý món cho mình'));
    await tester.pumpAndSettle();

    expect(find.text('Khám phá'), findsOneWidget);
    expect(container.read(onboardingDoneProvider), isTrue);
    expect(
      container.read(kitchenProfileProvider),
      KitchenProfile(tools: const {Tool.rice, Tool.kettle}, diets: {Diet.values.first}),
    );
  });

  testWidgets('Cài đặt: chọn Tối thì cả app đổi sang giao diện tối và nhớ lựa chọn', (
    tester,
  ) async {
    final container = await _pumpSettings(tester);
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.light);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('system.themeMode'), 'dark');
  });

  group('màn 360dp, chữ 1.3, sáng và tối: không tràn', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      for (final (name, location) in [
        ('Cài đặt', settingsLocation),
        ('Onboarding', onboardingLocation),
        ('Góp ý', feedbackLocation),
        ('Giới thiệu', aboutLocation),
        ('Chính sách', policyLocation),
        ('Xin quyền thông báo', notifPermissionLocation),
      ]) {
        testWidgets('$name (${themeMode.name})', (tester) async {
          await _pump(
            tester,
            initialLocation: location,
            size: _small,
            textScale: 1.3,
            themeMode: themeMode,
          );
          // Cuộn hết màn để dựng mọi hàng; tràn là FlutterError, test tự fail.
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            await tester.drag(scrollable.first, const Offset(0, -3000));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('Xoá dữ liệu (${themeMode.name})', (tester) async {
        await _pump(tester, size: _small, textScale: 1.3, themeMode: themeMode);
        GoRouter.of(tester.element(find.byType(SettingsScreen))).push(clearDataLocation);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'CONFIRM DELETE');
        await tester.pump();

        expect(find.byType(ClearDataScreen), findsOneWidget);
        expect(_deleteButton(tester).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
