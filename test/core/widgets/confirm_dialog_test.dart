import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/confirm_dialog.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      Future<BuildContext> pump(WidgetTester tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  ctx = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        return ctx;
      }

      Future<bool?> show(WidgetTester tester, String tap) async {
        final ctx = await pump(tester);
        bool? result;
        showConfirmDialog(
          ctx,
          title: 'Xoá toàn bộ dữ liệu?',
          message: 'Không có tài khoản nên không khôi phục được.',
          confirmLabel: 'Xoá hết',
        ).then((value) => result = value);
        await tester.pumpAndSettle();
        await tester.tap(find.text(tap));
        await tester.pumpAndSettle();
        return result;
      }

      testWidgets('Huỷ bên trái, nút nguy hiểm nền danger bên phải', (tester) async {
        final ctx = await pump(tester);
        showConfirmDialog(
          ctx,
          title: 'Xoá toàn bộ dữ liệu?',
          message: 'Không có tài khoản nên không khôi phục được.',
          confirmLabel: 'Xoá hết',
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Dialog>(find.byType(Dialog)).backgroundColor, colors.surface);
        final buttons = tester.widgetList<AppButton>(find.byType(AppButton)).toList();
        expect(buttons.map((b) => b.variant), [
          AppButtonVariant.secondary,
          AppButtonVariant.danger,
        ]);
        expect(
          tester.getCenter(find.text('Huỷ')).dx,
          lessThan(tester.getCenter(find.text('Xoá hết')).dx),
        );
        expect(
          tester
              .widget<Text>(find.text('Không có tài khoản nên không khôi phục được.'))
              .style!
              .color,
          colors.inkMuted,
        );
      });

      testWidgets('bấm nút nguy hiểm trả true', (tester) async {
        expect(await show(tester, 'Xoá hết'), isTrue);
        expect(find.byType(Dialog), findsNothing);
      });

      testWidgets('bấm Huỷ trả false', (tester) async {
        expect(await show(tester, 'Huỷ'), isFalse);
      });

      testWidgets('bấm ra ngoài trả false', (tester) async {
        final ctx = await pump(tester);
        bool? result;
        showConfirmDialog(
          ctx,
          title: 'Xoá toàn bộ dữ liệu?',
          message: 'Không khôi phục được.',
          confirmLabel: 'Xoá hết',
        ).then((value) => result = value);
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expect(result, isFalse);
      });
    });
  }

  testWidgets('360dp, chữ 1.3 không tràn', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    showConfirmDialog(
      ctx,
      title: 'Xoá toàn bộ dữ liệu?',
      message: 'Không có tài khoản nên không khôi phục được.',
      confirmLabel: 'Xoá hết',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
