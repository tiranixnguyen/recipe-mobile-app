import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/app/app.dart';

void main() {
  testWidgets('shell có 2 tab và chuyển được sang Yêu thích', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    // Tìm tab theo nhãn trong NavigationBar — icon có thể trùng với icon trong màn hình.
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Yêu thích')),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Yêu thích'), findsOneWidget);
  });
}
