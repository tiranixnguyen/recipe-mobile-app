import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';

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

    group('theme $name', () {
      testWidgets('icon trên vòng chiliSoft, tiêu đề, câu inkMuted, một nút phụ', (tester) async {
        var taps = 0;
        await pump(
          tester,
          EmptyState(
            icon: AppIcons.bookmark,
            title: 'Chưa lưu món nào',
            message: 'Bấm biểu tượng lưu trên món bạn thích.',
            actionLabel: 'Xem gợi ý',
            onAction: () => taps++,
          ),
        );

        final circle = tester.widget<Container>(find.byType(Container).first);
        expect((circle.decoration! as BoxDecoration).color, colors.chiliSoft);
        expect(find.byIcon(AppIcons.bookmark), findsOneWidget);
        expect(tester.widget<Text>(find.text('Chưa lưu món nào')).style!.fontSize, 20);
        expect(
          tester.widget<Text>(find.text('Bấm biểu tượng lưu trên món bạn thích.')).style!.color,
          colors.inkMuted,
        );
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).variant,
          AppButtonVariant.secondary,
        );

        await tester.tap(find.text('Xem gợi ý'));
        expect(taps, 1);
      });

      testWidgets('không truyền nút thì không có nút', (tester) async {
        await pump(tester, const EmptyState(title: 'Tủ đồ còn trống'));

        expect(find.byType(AppButton), findsNothing);
        expect(find.byIcon(AppIcons.bowl), findsOneWidget);
      });
    });
  }
}
