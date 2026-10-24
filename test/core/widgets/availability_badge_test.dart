import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';

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

    BoxDecoration decoration(WidgetTester tester) =>
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;

    group('theme $name', () {
      testWidgets('không thiếu: "Đủ đồ" nền herb chữ trắng', (tester) async {
        await pump(tester, const AvailabilityBadge());

        final text = tester.widget<Text>(find.text('Đủ đồ'));
        expect(text.style!.color, Colors.white);
        expect(text.style!.fontSize, 12);
        expect(text.style!.fontWeight, FontWeight.w600);
        expect(decoration(tester).color, colors.herb);
        expect(decoration(tester).borderRadius, AppRadius.smAll);
      });

      testWidgets('thiếu: liệt kê tên, nền chiliSoft chữ chiliDeep', (tester) async {
        await pump(tester, const AvailabilityBadge(missing: ['rau cải', 'tỏi']));

        final text = tester.widget<Text>(find.text('Thiếu: rau cải, tỏi'));
        expect(text.style!.color, colors.chiliDeep);
        expect(decoration(tester).color, colors.chiliSoft);
      });
    });
  }
}
