import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/detail/presentation/detail_screen.dart';
import 'package:recipe_mobile_app/features/detail/strings.dart';

Widget _wrap(String id) => ProviderScope(
  child: MaterialApp(home: DetailScreen(drinkId: id)),
);

void main() {
  testWidgets('đổi size và thêm topping thì thành tiền cập nhật', (tester) async {
    await tester.pumpWidget(_wrap('tra-sua-truyen-thong'));
    await tester.pumpAndSettle();

    expect(find.text('${DetailStrings.total}: 20.000đ'), findsOneWidget);

    await tester.tap(find.text('L'));
    await tester.tap(find.byTooltip('Thêm topping'));
    await tester.pumpAndSettle();

    expect(find.text('${DetailStrings.total}: 30.000đ'), findsOneWidget);
  });

  testWidgets('id không tồn tại thì báo không tìm thấy', (tester) async {
    await tester.pumpWidget(_wrap('khong-co'));
    await tester.pumpAndSettle();

    expect(find.text(DetailStrings.notFound), findsOneWidget);
  });
}
