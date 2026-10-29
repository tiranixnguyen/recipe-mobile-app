import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

    Color background(WidgetTester tester) =>
        (tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration)
            .color!;

    group('theme $name', () {
      testWidgets('info: nền chiliSoft, chữ chiliDeep, nút Sửa', (tester) async {
        var taps = 0;
        await pump(
          tester,
          InlineBanner(
            text: 'Đã nới thời gian lên 45 phút để có đủ gợi ý.',
            action: BannerAction('Sửa', () => taps++),
          ),
        );

        expect(background(tester), colors.chiliSoft);
        expect(
          tester.widget<Text>(find.textContaining('Đã nới')).style!.color,
          colors.chiliDeep,
        );
        expect(find.byIcon(AppIcons.info), findsOneWidget);
        await tester.tap(find.text('Sửa'));
        expect(taps, 1);
      });

      testWidgets('success: nền herbSoft, chữ ink, icon check herbInk', (tester) async {
        await pump(
          tester,
          const InlineBanner(
            kind: BannerKind.success,
            text: 'Sẽ thêm cùng Canh cà chua trứng · bữa này thành 2 món',
          ),
        );

        expect(background(tester), colors.herbSoft);
        expect(tester.widget<Text>(find.textContaining('Sẽ thêm')).style!.color, colors.ink);
        expect(tester.widget<Icon>(find.byIcon(AppIcons.check)).color, colors.herbInk);
        expect(find.byType(TextButton), findsNothing);
      });
    });
  }
}
