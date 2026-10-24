import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_screen.dart';
import 'package:recipe_mobile_app/features/pantry/strings.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
];

const _recipe = Recipe(
  id: 'trung-chien',
  name: 'Trứng chiên hành',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [
    RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
    RecipeIngredient(id: 'salt', amount: 1, unit: 'nhúm'),
  ],
  steps: [],
);

Future<void> _pump(WidgetTester tester, {Future<List<Recipe>> Function()? recipes}) async {
  final router = GoRouter(
    initialLocation: '/pantry',
    routes: [
      GoRoute(path: '/pantry', builder: (_, _) => const PantryScreen()),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => Text('món ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        recipesProvider.overrideWith((ref) => (recipes ?? () async => const [_recipe])()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

AppChip _chip(WidgetTester tester, String label) =>
    tester.widget<AppChip>(find.widgetWithText(AppChip, label));

void main() {
  testWidgets('chip theo nhóm, không có gia vị cơ bản; tủ trống thì gợi ý bật thêm', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Đạm'), findsOneWidget);
    expect(find.text('Rau củ'), findsOneWidget);
    expect(find.text('Muối'), findsNothing);
    expect(find.text(PantryStrings.noReady), findsOneWidget);
    expect(find.text('Thiếu: trứng, hành lá'), findsOneWidget);
  });

  testWidgets('bấm chip thì bật/tắt, món đủ đồ hiện ngay và mở được', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Trứng'));
    await tester.pump();
    expect(_chip(tester, 'Trứng').selected, isTrue);
    expect(find.text('Thiếu: hành lá'), findsOneWidget);

    await tester.tap(find.text('Hành lá'));
    await tester.pump();
    expect(find.text(PantryStrings.noReady), findsNothing);
    expect(find.text('15 phút · Bếp từ'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('món trung-chien'), findsOneWidget);
  });

  testWidgets('bấm lại chip đang bật thì tắt', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Trứng'));
    await tester.pump();
    await tester.tap(find.text('Trứng'));
    await tester.pump();
    expect(_chip(tester, 'Trứng').selected, isFalse);
  });

  testWidgets('dữ liệu lỗi thì hiện câu lỗi', (tester) async {
    await _pump(tester, recipes: () => Future.error(const FormatException('hỏng')));

    expect(find.text(PantryStrings.loadError), findsOneWidget);
    expect(find.byType(AppChip), findsNothing);
  });
}
