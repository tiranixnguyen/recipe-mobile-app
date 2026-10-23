import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/settings_row.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    );

    group('theme $name', () {
      testWidgets('hàng bấm được có chevron và gọi onTap', (tester) async {
        var taps = 0;
        await pump(
          tester,
          SettingsRow(icon: AppIcons.mail, title: 'Góp ý & báo lỗi', onTap: () => taps++),
        );

        expect(find.byIcon(AppIcons.chevron), findsOneWidget);
        await tester.tap(find.text('Góp ý & báo lỗi'));
        expect(taps, 1);
      });

      testWidgets('hàng không bấm được thì không có chevron', (tester) async {
        await pump(tester, const SettingsRow(title: 'Phiên bản', note: '1.0.0'));

        expect(find.byIcon(AppIcons.chevron), findsNothing);
        expect(find.text('1.0.0'), findsOneWidget);
      });

      testWidgets('danger: chữ và icon dangerInk, không chevron', (tester) async {
        await pump(
          tester,
          SettingsRow(
            icon: AppIcons.trash,
            title: 'Xoá dữ liệu trên máy',
            danger: true,
            onTap: () {},
          ),
        );

        expect(find.byIcon(AppIcons.chevron), findsNothing);
        final text = tester.widget<Text>(find.text('Xoá dữ liệu trên máy'));
        expect(text.style!.color, colors.dangerInk);
        expect(text.style!.fontWeight, FontWeight.w600);
        final icon = tester.widget<RichText>(
          find.descendant(of: find.byIcon(AppIcons.trash), matching: find.byType(RichText)),
        );
        expect(icon.text.style!.color, colors.dangerInk);
      });

      testWidgets('toggle: bấm cả hàng gọi onChanged với giá trị ngược', (tester) async {
        final changes = <bool>[];
        await pump(
          tester,
          SettingsRow.toggle(
            icon: AppIcons.timer,
            title: 'Nhắc khi hẹn giờ xong',
            note: 'Rung và báo khi đồng hồ nấu hết giờ',
            value: true,
            onChanged: changes.add,
          ),
        );

        expect(find.byIcon(AppIcons.chevron), findsNothing);
        await tester.tap(find.text('Nhắc khi hẹn giờ xong'));
        await tester.tap(find.byType(AnimatedContainer));
        expect(changes, [false, false]);

        final semantics = tester.getSemantics(find.text('Nhắc khi hẹn giờ xong'));
        expect(semantics.flagsCollection.isToggled, isNotNull);
      });

      testWidgets('group có tiêu đề và đường kẻ giữa các hàng', (tester) async {
        await pump(
          tester,
          SettingsGroup(
            title: 'Hỗ trợ & thông tin',
            children: [
              SettingsRow(title: 'A', onTap: () {}),
              SettingsRow(title: 'B', onTap: () {}),
              SettingsRow(title: 'C', onTap: () {}),
            ],
          ),
        );

        expect(find.text('Hỗ trợ & thông tin'), findsOneWidget);
        final dividers = tester.widgetList<Divider>(find.byType(Divider));
        expect(dividers, hasLength(2));
        expect(dividers.first.color, colors.line);
      });
    });
  }
}
