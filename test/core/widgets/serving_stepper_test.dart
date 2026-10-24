import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/serving_stepper.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      Future<List<int>> pump(WidgetTester tester, int value, {String unit = 'người'}) async {
        final changes = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: ServingStepper(value: value, unit: unit, onChanged: changes.add),
              ),
            ),
          ),
        );
        return changes;
      }

      Finder button(IconData icon) =>
          find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton));

      testWidgets('hiện "2 người" đậm, bấm − và + gọi onChanged', (tester) async {
        final changes = await pump(tester, 2);

        final text = tester.widget<Text>(find.text('2 người'));
        expect(text.style!.fontWeight, FontWeight.w700);
        expect(text.style!.color, colors.ink);
        expect(tester.getSize(button(AppIcons.plus)), const Size.square(44));

        await tester.tap(button(AppIcons.minus));
        await tester.tap(button(AppIcons.plus));
        expect(changes, [1, 3]);
      });

      testWidgets('chạm min: nút − mờ và không bấm được', (tester) async {
        final changes = await pump(tester, 1);

        await tester.tap(button(AppIcons.minus));
        expect(changes, isEmpty);
        expect(tester.widget<IconButton>(button(AppIcons.minus)).onPressed, isNull);
        expect(
          tester
              .widget<Opacity>(
                find.ancestor(of: button(AppIcons.minus), matching: find.byType(Opacity)),
              )
              .opacity,
          AppButton.disabledOpacity,
        );
      });

      testWidgets('chạm max: nút + không bấm được; đổi unit', (tester) async {
        final changes = await pump(tester, 6, unit: 'suất');

        expect(find.text('6 suất'), findsOneWidget);
        await tester.tap(button(AppIcons.plus));
        expect(changes, isEmpty);
      });
    });
  }
}
