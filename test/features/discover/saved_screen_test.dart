import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

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
  ingredients: [RecipeIngredient(id: 'egg', amount: 2, unit: 'quả')],
  steps: [],
);

Future<void> _pump(
  WidgetTester tester, {
  List<String> saved = const [],
  Future<List<Recipe>> Function()? recipes,
}) async {
  final store = InMemoryLocalStore();
  await store.writeList('discover.saved', saved);
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      for (final path in ['/', '/recipe/:id'])
        GoRoute(path: path, builder: (_, state) => Text('at ${state.uri}')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => store),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
          ],
        ),
        recipesProvider.overrideWith((ref) => (recipes ?? () async => const [_recipe])()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('trống: EmptyState, nút mở Khám phá', (tester) async {
    await _pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
    await tester.tap(find.text(DiscoverStrings.savedEmptyAction));
    await tester.pumpAndSettle();
    expect(find.text('at /'), findsOneWidget);
  });

  testWidgets('có món: thẻ kèm badge và nút lưu; bỏ lưu thì về trống', (tester) async {
    await _pump(tester, saved: ['trung-chien']);

    expect(find.widgetWithText(RecipeCard, 'Trứng chiên hành'), findsOneWidget);
    expect(find.widgetWithText(AvailabilityBadge, 'Thiếu: trứng'), findsOneWidget);

    await tester.tap(find.byType(SaveButton));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeCard), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('bấm món mở Chi tiết', (tester) async {
    await _pump(tester, saved: ['trung-chien']);

    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('at /recipe/trung-chien'), findsOneWidget);
  });

  testWidgets('dữ liệu lỗi thì hiện câu lỗi', (tester) async {
    await _pump(
      tester,
      saved: ['trung-chien'],
      recipes: () => Future.error(const FormatException('hỏng')),
    );

    expect(find.text(DiscoverStrings.loadError), findsOneWidget);
    expect(find.byType(RecipeCard), findsNothing);
  });
}
