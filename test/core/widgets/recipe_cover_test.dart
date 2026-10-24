import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, String? asset) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, child: RecipeCover(imageAsset: asset)),
          ),
        ),
      ),
    );

    void expectPlaceholder(WidgetTester tester) {
      expect(find.byIcon(AppIcons.bowl), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(AppIcons.bowl)).color, colors.chili);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(of: find.byType(RecipeCover), matching: find.byType(ColoredBox)),
            )
            .color,
        colors.chiliSoft,
      );
      expect(tester.getSize(find.byType(RecipeCover)), const Size(320, 200));
    }

    group('theme $name', () {
      testWidgets('null: hình bát, 16:10', (tester) async {
        await pump(tester, null);
        expect(find.byType(Image), findsNothing);
        expectPlaceholder(tester);
      });

      testWidgets('đường dẫn rỗng: hình bát', (tester) async {
        await pump(tester, '');
        expect(find.byType(Image), findsNothing);
        expectPlaceholder(tester);
      });

      testWidgets('file không có: hình bát sau khi tải lỗi', (tester) async {
        await pump(tester, 'assets/images/recipes/khong-co.jpg');
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        expectPlaceholder(tester);
      });
    });
  }
}
