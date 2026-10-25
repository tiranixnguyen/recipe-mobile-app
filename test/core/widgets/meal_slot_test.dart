import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/meal_slot.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';

const _dishes = [
  MealSlotDish(title: 'Đậu phụ sốt cà chua', meta: '20 phút · Bếp từ'),
  MealSlotDish(title: 'Trứng chiên hành', meta: '15 phút · Bếp từ'),
];

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

    Finder dashed() => find.descendant(
      of: find.byType(MealSlot),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && '${w.foregroundPainter.runtimeType}' == '_DashedBorderPainter',
      ),
    );

    group('theme $name', () {
      testWidgets('trống: nhãn bữa, ô viền đứt cao 58 "Thêm món", không có link', (tester) async {
        var adds = 0;
        await pump(tester, MealSlot(label: 'Sáng', dishes: const [], onAdd: () => adds++));

        final label = tester.widget<Text>(find.text('Sáng'));
        expect(label.style!.color, colors.inkMuted);
        expect(label.style!.fontWeight, FontWeight.w600);
        expect(find.text('Thêm món'), findsOneWidget);
        expect(find.text('+ Thêm món'), findsNothing);
        expect(find.byIcon(AppIcons.plus), findsOneWidget);
        expect(dashed(), findsOneWidget);
        expect(tester.getSize(dashed()).height, 58);
        expect(tester.widget<Text>(find.text('Thêm món')).style!.color, colors.ink);

        await tester.tap(find.text('Thêm món'));
        expect(adds, 1);
      });

      testWidgets('nhiều món: "Tối · 2 món", mỗi món một hàng ảnh 44, link Thêm món', (
        tester,
      ) async {
        var adds = 0;
        final taps = <int>[];
        await pump(
          tester,
          MealSlot(label: 'Tối', dishes: _dishes, onAdd: () => adds++, onDishTap: taps.add),
        );

        expect(find.text('Tối · 2 món'), findsOneWidget);
        expect(find.byType(RecipeRow), findsNWidgets(2));
        expect(dashed(), findsNothing);
        expect(tester.widget<RecipeRow>(find.byType(RecipeRow).first).thumbSize, 44);
        expect(tester.widget<Text>(find.text('20 phút · Bếp từ')).style!.color, colors.inkMuted);
        expect(
          tester.widget<Text>(find.text('Trứng chiên hành')).style!.fontWeight,
          FontWeight.w600,
        );

        final link = find.text('+ Thêm món');
        expect(tester.widget<Text>(link).style!.color, colors.chiliDeep);
        final target = find.ancestor(of: link, matching: find.byType(InkWell)).first;
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(target).width, greaterThanOrEqualTo(48));

        await tester.tap(link);
        await tester.tap(find.text('Trứng chiên hành'));
        await tester.tap(find.text('Đậu phụ sốt cà chua'));
        expect(adds, 1);
        expect(taps, [1, 0]);
      });

      testWidgets('một món: nhãn không đếm', (tester) async {
        await pump(tester, MealSlot(label: 'Trưa', dishes: [_dishes.first], onAdd: () {}));
        expect(find.text('Trưa'), findsOneWidget);
        expect(find.text('+ Thêm món'), findsOneWidget);
      });

      testWidgets('compact: "Tên đầu +N", nền surfaceRaised viền line, cao 56', (tester) async {
        var taps = 0;
        await pump(
          tester,
          MealSlot.compact(
            titles: const ['Đậu phụ sốt cà chua', 'Trứng chiên hành'],
            onTap: () => taps++,
          ),
        );

        expect(find.text('Đậu phụ sốt cà chua'), findsOneWidget);
        expect(find.text(' +1'), findsOneWidget);
        expect(tester.getSize(find.byType(MealSlot)).height, 56);
        final material = tester.widget<Material>(
          find.descendant(of: find.byType(MealSlot), matching: find.byType(Material)).first,
        );
        expect(material.color, colors.surfaceRaised);
        expect((material.shape! as RoundedRectangleBorder).side.color, colors.line);

        await tester.tap(find.byType(MealSlot));
        expect(taps, 1);
      });

      testWidgets('compact: một món thì chỉ tên; trống thì ô viền đứt "+"', (tester) async {
        await pump(tester, MealSlot.compact(titles: const ['Mì xào rau cải'], onTap: () {}));
        expect(find.text('Mì xào rau cải'), findsOneWidget);

        var taps = 0;
        await pump(tester, MealSlot.compact(titles: const [], onTap: () => taps++));
        expect(find.text('+'), findsOneWidget);
        expect(tester.widget<Text>(find.text('+')).style!.color, colors.inkMuted);
        expect(dashed(), findsOneWidget);
        expect(tester.getSize(find.byType(MealSlot)).height, 56);
        await tester.tap(find.text('+'));
        expect(taps, 1);
      });
    });
  }
}
