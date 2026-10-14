import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/drink_repository.dart';
import 'package:recipe_mobile_app/core/models/drink.dart';
import 'package:recipe_mobile_app/features/menu/presentation/menu_screen.dart';
import 'package:recipe_mobile_app/features/menu/strings.dart';

class _EmptyRepository implements DrinkRepository {
  @override
  Future<List<Drink>> list() async => const [];

  @override
  Future<Drink?> getById(String id) async => null;
}

Widget _wrap({List overrides = const []}) => ProviderScope(
  overrides: [...overrides],
  child: const MaterialApp(home: MenuScreen()),
);

void main() {
  testWidgets('hiển thị các món từ repository', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Trà sữa truyền thống'), findsOneWidget);
    expect(find.text('từ 20.000đ'), findsOneWidget);
  });

  testWidgets('menu rỗng thì báo trống', (tester) async {
    await tester.pumpWidget(
      _wrap(overrides: [drinkRepositoryProvider.overrideWithValue(_EmptyRepository())]),
    );
    await tester.pumpAndSettle();

    expect(find.text(MenuStrings.empty), findsOneWidget);
  });
}
