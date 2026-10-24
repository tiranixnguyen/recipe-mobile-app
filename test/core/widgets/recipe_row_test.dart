import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';

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
      testWidgets('tên 600, meta inkMuted, nền surfaceRaised viền line, bấm được', (tester) async {
        var taps = 0;
        await pump(
          tester,
          RecipeRow(title: 'Trứng chiên hành', meta: '15 phút · Bếp từ', onTap: () => taps++),
        );

        expect(
          tester.widget<Text>(find.text('Trứng chiên hành')).style!.fontWeight,
          FontWeight.w600,
        );
        expect(tester.widget<Text>(find.text('15 phút · Bếp từ')).style!.color, colors.inkMuted);
        final material = tester.widget<Material>(
          find.descendant(of: find.byType(RecipeRow), matching: find.byType(Material)).first,
        );
        expect(material.color, colors.surfaceRaised);
        expect((material.shape! as RoundedRectangleBorder).side.color, colors.line);
        expect(find.byIcon(AppIcons.bowl), findsOneWidget);

        await tester.tap(find.byType(RecipeRow));
        expect(taps, 1);
      });

      testWidgets('meta nhấn mạnh tô chiliDeep đậm; ảnh theo thumbSize', (tester) async {
        await pump(
          tester,
          const RecipeRow(
            title: 'Mì xào',
            meta: 'Thiếu: rau cải',
            emphasizeMeta: true,
            thumbSize: 48,
          ),
        );

        final meta = tester.widget<Text>(find.text('Thiếu: rau cải')).style!;
        expect(meta.color, colors.chiliDeep);
        expect(meta.fontWeight, FontWeight.w600);
        expect(
          tester.getSize(
            find.descendant(of: find.byType(RecipeRow), matching: find.byType(ClipRRect)),
          ),
          const Size.square(48),
        );
      });
    });
  }
}
