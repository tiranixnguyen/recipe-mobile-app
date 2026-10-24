import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';

void main() {
  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

    group('theme $name', () {
      testWidgets('cao 48, placeholder mặc định, gõ và tìm', (tester) async {
        final changes = <String>[];
        final submits = <String>[];
        await pump(tester, SearchField(onChanged: changes.add, onSubmitted: submits.add));

        expect(find.text('Tìm món, nguyên liệu…'), findsOneWidget);
        expect(tester.getSize(find.byType(TextField)).height, 48);

        await tester.enterText(find.byType(TextField), 'trứng');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        expect(changes, ['trứng']);
        expect(submits, ['trứng']);
      });

      testWidgets('focus có viền chili 2px', (tester) async {
        await pump(tester, const SearchField());
        await tester.tap(find.byType(TextField));
        await tester.pump();

        final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
        expect(decorator.isFocused, isTrue);
        final border = theme.inputDecorationTheme.focusedBorder!;
        expect(border.borderSide.color, colors.chili);
        expect(border.borderSide.width, 2);
      });

      testWidgets('readOnly + onTap để mở màn Tìm kiếm', (tester) async {
        var taps = 0;
        await pump(tester, SearchField(readOnly: true, onTap: () => taps++));

        await tester.tap(find.byType(TextField));
        expect(taps, 1);
        expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      });
    });
  }
}
