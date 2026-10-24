import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/day_strip.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      testWidgets('7 ô T2…CN; ô chọn nền chili; hôm nay chiliDeep; chấm ngày có món', (
        tester,
      ) async {
        final picks = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SizedBox(
                width: 358,
                child: DayStrip(
                  selected: 0,
                  today: 1,
                  daysWithMeals: const {0, 2},
                  onSelected: picks.add,
                ),
              ),
            ),
          ),
        );

        for (final short in DayStrip.shortNames) {
          expect(find.text(short), findsOneWidget);
        }

        Material cell(String short) => tester.widget<Material>(
          find.ancestor(of: find.text(short), matching: find.byType(Material)).first,
        );
        Color? textColor(String short) => tester.widget<Text>(find.text(short)).style!.color;

        expect(cell('T2').color, colors.chili);
        expect(textColor('T2'), Colors.white);
        expect(cell('T3').color, colors.surfaceRaised);
        expect(textColor('T3'), colors.chiliDeep);
        expect(textColor('T4'), colors.ink);
        expect(
          tester
              .getSize(find.ancestor(of: find.text('T2'), matching: find.byType(SizedBox)).first)
              .height,
          56,
        );

        final dots = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => (d.decoration as BoxDecoration).color)
            .where((c) => c != Colors.transparent)
            .toList();
        expect(dots, [Colors.white, colors.herb]);

        expect(find.bySemanticsLabel('Thứ Ba, Hôm nay'), findsOneWidget);

        await tester.tap(find.text('CN'));
        expect(picks, [6]);
      });
    });
  }
}
