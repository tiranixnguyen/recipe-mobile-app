import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
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

    Material material(WidgetTester tester) => tester.widget<Material>(
      find.descendant(of: find.byType(AppChip), matching: find.byType(Material)),
    );

    group('theme $name', () {
      testWidgets('chưa chọn: nền surfaceRaised viền outline, có icon, cao 36', (tester) async {
        var taps = 0;
        await pump(
          tester,
          AppChip(
            label: 'Dưới 15 phút',
            icon: AppIcons.clock,
            selected: false,
            onTap: () => taps++,
          ),
        );

        expect(material(tester).color, colors.surfaceRaised);
        expect((material(tester).shape! as StadiumBorder).side.color, colors.outline);
        expect(find.byIcon(AppIcons.clock), findsOneWidget);
        expect(tester.getSize(find.byType(AppChip)).height, 36);
        expect(tester.widget<Text>(find.text('Dưới 15 phút')).style!.color, colors.ink);

        await tester.tap(find.text('Dưới 15 phút'));
        expect(taps, 1);
      });

      testWidgets('đã chọn: nền chiliSoft, chữ và viền chiliDeep, icon thành dấu tích', (
        tester,
      ) async {
        await pump(
          tester,
          AppChip(label: 'Dưới 15 phút', icon: AppIcons.clock, selected: true, onTap: () {}),
        );

        expect(material(tester).color, colors.chiliSoft);
        expect((material(tester).shape! as StadiumBorder).side.color, colors.chiliDeep);
        expect(tester.widget<Text>(find.text('Dưới 15 phút')).style!.color, colors.chiliDeep);
        expect(find.byIcon(AppIcons.clock), findsNothing);
        expect(find.byIcon(AppIcons.check), findsOneWidget);
        expect(tester.getSemantics(find.byType(AppChip)).flagsCollection.isSelected, isNotNull);
      });
    });
  }
}
