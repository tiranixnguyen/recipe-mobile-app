import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      late BuildContext ctx;

      Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      testWidgets('thành công: nền ink, chữ surface, icon check herbSoft, 4 giây', (tester) async {
        await pump(tester);
        AppSnackbar.show(ctx, 'Đã thêm trứng gà vào đi chợ');
        await tester.pumpAndSettle();

        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(bar.backgroundColor, colors.ink);
        expect(bar.behavior, SnackBarBehavior.floating);
        expect(bar.duration, const Duration(seconds: 4));
        expect(bar.margin, const EdgeInsets.fromLTRB(16, 0, 16, 16));
        expect(
          tester.widget<Text>(find.text('Đã thêm trứng gà vào đi chợ')).style!.color,
          colors.surface,
        );
        expect(tester.widget<Icon>(find.byIcon(AppIcons.check)).color, colors.herbSoft);
        expect(tester.getSize(find.byType(SnackBar)).height, greaterThanOrEqualTo(48));
      });

      testWidgets('cái mới thay cái cũ, chỉ còn một snackbar', (tester) async {
        await pump(tester);
        AppSnackbar.show(ctx, 'Đã bỏ lưu món');
        await tester.pumpAndSettle();
        AppSnackbar.show(ctx, 'Trứng gà đã có trong đi chợ', kind: SnackKind.info);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Đã bỏ lưu món'), findsNothing);
        expect(find.byIcon(AppIcons.info), findsOneWidget);
        expect(AppSnackbar.visible.value, isTrue);
      });

      testWidgets('có nút: 6 giây, nút chiliSoft, bấm thì gọi onTap và ẩn', (tester) async {
        await pump(tester);
        var taps = 0;
        AppSnackbar.show(ctx, 'Đã bỏ lưu món', action: SnackAction('Hoàn tác', () => taps++));
        await tester.pumpAndSettle();

        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).duration,
          const Duration(seconds: 6),
        );
        final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
        expect(style.foregroundColor!.resolve({}), colors.chiliSoft);

        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(find.byType(SnackBar), findsNothing);
        expect(AppSnackbar.visible.value, isFalse);
      });

      testWidgets('lỗi: nền danger, chữ và icon trắng, nút gạch chân', (tester) async {
        await pump(tester);
        AppSnackbar.show(
          ctx,
          'Chưa lưu được thực đơn. Kiểm tra bộ nhớ máy.',
          kind: SnackKind.error,
          action: SnackAction('Thử lại', () {}),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor, colors.danger);
        expect(tester.widget<Icon>(find.byIcon(AppIcons.alert)).color, Colors.white);
        final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
        expect(style.foregroundColor!.resolve({}), Colors.white);
        expect(style.textStyle!.resolve({})!.decoration, TextDecoration.underline);
      });

      testWidgets('tự ẩn sau 4 giây và tắt cờ visible', (tester) async {
        await pump(tester);
        AppSnackbar.show(ctx, 'Đã chép địa chỉ email');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        expect(AppSnackbar.visible.value, isFalse);
      });

      testWidgets('besideFab chừa 88 bên phải cho nút nổi', (tester) async {
        await pump(tester);
        AppSnackbar.show(ctx, 'Đã thêm trứng gà vào đi chợ', besideFab: true);
        await tester.pumpAndSettle();

        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).margin,
          const EdgeInsets.fromLTRB(16, 0, 88, 16),
        );
      });
    });
  }

  testWidgets('chữ dài cắt 2 dòng, nút không tràn ở 360dp, chữ 1.3', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    AppSnackbar.show(
      ctx,
      'Chưa lưu được thực đơn tuần này vì bộ nhớ máy đã đầy, hãy xoá bớt ảnh rồi thử lại sau nhé.',
      kind: SnackKind.error,
      action: SnackAction('Thử lại', () {}),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.textContaining('Chưa lưu được'));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getRect(find.text('Thử lại')).right, lessThanOrEqualTo(360 - 16));
  });
}
