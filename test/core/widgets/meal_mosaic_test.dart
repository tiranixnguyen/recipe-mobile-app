import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';

void main() {
  const names = [
    'Đậu phụ sốt cà chua',
    'Canh cà chua trứng',
    'Trứng chiên hành',
    'Rau cải luộc',
    'Cơm rang dưa cải',
    'Mì xào rau cải',
  ];
  List<MosaicDish> dishes(int n) => [for (final name in names.take(n)) MosaicDish(name)];

  Finder tiles() => find.descendant(of: find.byType(MealMosaic), matching: find.byType(Padding));

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      Future<void> pump(WidgetTester tester, int n, {double width = 328, double height = 168}) =>
          tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: MealMosaic(dishes: dishes(n), radius: AppRadius.mdAll),
                  ),
                ),
              ),
            ),
          );

      testWidgets('1 món đầy khung, nền surfaceRaised', (tester) async {
        await pump(tester, 1);
        expect(tiles(), findsOneWidget);
        expect(tester.getSize(tiles()), const Size(328, 168));
        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(of: find.byType(MealMosaic), matching: find.byType(ColoredBox))
                    .first,
              )
              .color,
          colors.surfaceRaised,
        );
      });

      testWidgets('2 món chia đôi dọc', (tester) async {
        await pump(tester, 2);
        expect(tiles(), findsNWidgets(2));
        expect(tester.getSize(tiles().first), const Size(164, 168));
      });

      testWidgets('3 món: trái 60%, phải hai ô chồng', (tester) async {
        await pump(tester, 3, width: 200);
        expect(tiles(), findsNWidgets(3));
        expect(tester.getSize(tiles().at(0)), const Size(120, 168));
        expect(tester.getSize(tiles().at(1)), const Size(80, 84));
        expect(tester.getSize(tiles().at(2)), const Size(80, 84));
      });

      testWidgets('4 món lưới 2×2, không có "+N"', (tester) async {
        await pump(tester, 4);
        expect(tiles(), findsNWidgets(4));
        expect(find.textContaining('+'), findsNothing);
      });

      testWidgets('6 món: 4 ô, ô cuối "+3 món" đọc tên 3 món còn lại', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, 6);
        expect(tiles(), findsNWidgets(4));
        expect(find.text('+3 món'), findsOneWidget);
        expect(find.bySemanticsLabel('Đậu phụ sốt cà chua'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Rau cải luộc, Cơm rang dưa cải, Mì xào rau cải'),
          findsOneWidget,
        );
        semantics.dispose();
      });
    });
  }

  testWidgets('ô nhỏ 48×48 chỉ ghi "+N", không tràn', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(child: MealMosaic(dishes: dishes(6), size: 48)),
        ),
      ),
    );
    expect(find.text('+3'), findsOneWidget);
    expect(tester.getSize(find.byType(MealMosaic)), const Size(48, 48));
    expect(tester.takeException(), isNull);
  });
}
