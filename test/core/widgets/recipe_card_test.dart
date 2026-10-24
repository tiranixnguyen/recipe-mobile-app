import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    );

    group('theme $name', () {
      testWidgets('tên, meta inkMuted, badge và nút lưu, bấm mở món', (tester) async {
        var taps = 0;
        await pump(
          tester,
          RecipeCard(
            title: 'Trứng chiên hành',
            minutes: 15,
            servings: 1,
            tool: 'Bếp từ',
            badge: const AvailabilityBadge(missing: ['hành lá']),
            action: IconButton(onPressed: () {}, icon: const Icon(AppIcons.bookmark)),
            onTap: () => taps++,
          ),
        );

        final title = tester.widget<Text>(find.text('Trứng chiên hành'));
        expect(title.maxLines, 2);
        expect(title.style!.color, colors.ink);
        final meta = tester.widget<Text>(find.text('15 phút · 1 người · Bếp từ'));
        expect(meta.style!.color, colors.inkMuted);
        expect(meta.style!.fontSize, 13);
        expect(find.text('Thiếu: hành lá'), findsOneWidget);
        expect(find.byIcon(AppIcons.bookmark), findsOneWidget);

        final card = tester.widget<Material>(
          find.descendant(of: find.byType(RecipeCard), matching: find.byType(Material)).first,
        );
        expect(card.color, colors.surfaceRaised);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.side.color, colors.line);
        expect(shape.borderRadius, AppRadius.mdAll);

        // Ảnh 16:10 theo bề ngang thẻ; viền vẽ đè lên mép ảnh.
        expect(tester.getSize(find.byType(RecipeCover)), const Size(320, 200));

        await tester.tap(find.text('Trứng chiên hành'));
        expect(taps, 1);
      });

      testWidgets('không badge, không nút lưu: chỉ có ảnh, tên, meta', (tester) async {
        await pump(tester, const RecipeCard(title: 'Mì trứng', minutes: 5));

        expect(find.byType(AvailabilityBadge), findsNothing);
        expect(find.byType(IconButton), findsNothing);
        expect(find.text('5 phút'), findsOneWidget);
      });

      testWidgets('chưa có ảnh hoặc ảnh hỏng thì hiện hình bát trên chiliSoft', (tester) async {
        await pump(
          tester,
          const RecipeCard(
            title: 'Mì trứng',
            minutes: 5,
            imageAsset: 'assets/images/recipes/khong-co.jpg',
          ),
        );
        // Đợi asset bundle báo lỗi rồi vẽ lại bằng errorBuilder.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();

        expect(find.byIcon(AppIcons.bowl), findsOneWidget);
        final box = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(RecipeCover), matching: find.byType(ColoredBox)),
        );
        expect(box.color, colors.chiliSoft);
      });
    });
  }
}
