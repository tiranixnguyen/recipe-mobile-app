import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/meal_slot.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: SizedBox(width: 358, child: child)),
        ),
      ),
    );

    group('theme $name', () {
      testWidgets('trống: cao 72, viền đứt, "Thêm món", bấm được', (tester) async {
        var taps = 0;
        await pump(tester, MealSlot.empty(onTap: () => taps++));

        expect(tester.getSize(find.byType(MealSlot)).height, 72);
        expect(find.text('Thêm món'), findsOneWidget);
        expect(find.byIcon(AppIcons.plus), findsOneWidget);
        expect(
          find.descendant(of: find.byType(MealSlot), matching: find.byType(CustomPaint)),
          findsWidgets,
        );
        expect(tester.widget<Text>(find.text('Thêm món')).style!.color, colors.ink);

        await tester.tap(find.text('Thêm món'));
        expect(taps, 1);
      });

      testWidgets('có món: tên, meta inkMuted, nền surfaceRaised viền line', (tester) async {
        var taps = 0;
        await pump(
          tester,
          MealSlot(title: 'Trứng chiên hành', meta: '15 phút · Bếp từ', onTap: () => taps++),
        );

        expect(
          tester.widget<Text>(find.text('Trứng chiên hành')).style!.fontWeight,
          FontWeight.w600,
        );
        expect(tester.widget<Text>(find.text('15 phút · Bếp từ')).style!.color, colors.inkMuted);
        expect(find.text('Thêm món'), findsNothing);
        final material = tester.widget<Material>(
          find.descendant(of: find.byType(MealSlot), matching: find.byType(Material)).first,
        );
        expect(material.color, colors.surfaceRaised);
        expect((material.shape! as RoundedRectangleBorder).side.color, colors.line);
        // Chưa có ảnh: hình bát.
        expect(find.byIcon(AppIcons.bowl), findsOneWidget);

        await tester.tap(find.text('Trứng chiên hành'));
        expect(taps, 1);
      });
    });
  }
}
