import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );

    ButtonStyle style(WidgetTester tester) =>
        tester.widget<TextButton>(find.byType(TextButton)).style!;

    group('theme $name', () {
      for (final (variant, background, foreground) in [
        (AppButtonVariant.primary, colors.chili, Colors.white),
        (AppButtonVariant.secondary, colors.surfaceRaised, colors.ink),
        (AppButtonVariant.ghost, Colors.transparent, colors.chiliDeep),
        (AppButtonVariant.danger, colors.danger, Colors.white),
      ]) {
        testWidgets('${variant.name}: màu đúng token, cao 48, bấm được', (tester) async {
          var taps = 0;
          await pump(
            tester,
            AppButton(label: 'Bắt đầu nấu', variant: variant, onPressed: () => taps++),
          );

          expect(style(tester).backgroundColor!.resolve({}), background);
          expect(style(tester).foregroundColor!.resolve({}), foreground);
          expect(tester.getSize(find.byType(TextButton)).height, 48);
          await tester.tap(find.text('Bắt đầu nấu'));
          expect(taps, 1);
        });
      }

      testWidgets('secondary có viền outline', (tester) async {
        await pump(tester, AppButton.secondary(label: 'Hẹn 3 phút', onPressed: () {}));

        final shape = style(tester).shape!.resolve({}) as RoundedRectangleBorder;
        expect(shape.side.color, colors.outline);
        expect(shape.borderRadius, AppRadius.mdAll);
      });

      testWidgets('lg cao 56, chữ buttonLg, có icon', (tester) async {
        await pump(
          tester,
          AppButton(
            label: 'Bước tiếp',
            icon: AppIcons.chevron,
            size: AppButtonSize.lg,
            onPressed: () {},
          ),
        );

        expect(tester.getSize(find.byType(TextButton)).height, 56);
        expect(style(tester).textStyle!.resolve({})!.fontSize, 17);
        expect(find.byIcon(AppIcons.chevron), findsOneWidget);
      });

      testWidgets('onPressed null: mờ và không bấm được', (tester) async {
        await pump(tester, const AppButton.danger(label: 'Xoá hết', onPressed: null));

        final opacity = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacity.opacity, AppButton.disabledOpacity);
        expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
      });

      testWidgets('block chiếm hết chiều ngang', (tester) async {
        await pump(tester, AppButton(label: 'Xong', block: true, onPressed: () {}));

        expect(tester.getSize(find.byType(TextButton)).width, 800);
      });
    });
  }
}
