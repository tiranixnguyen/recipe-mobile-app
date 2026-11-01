import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved_meal/saved_meal_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

import '../../core/fake_analytics.dart';

Recipe _recipe(String id, String name) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);

final _egg = _recipe('trung-chien', 'Trứng chiên hành');
final _soup = _recipe('canh-cai', 'Canh cải');
const _meal = SavedMeal(
  recipeIds: ['trung-chien', 'canh-cai'],
  servings: 2,
  tags: [RecipeTag.cheap],
);

ProviderContainer _container(FakeAnalytics analytics) {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      analyticsProvider.overrideWithValue(analytics),
      recipesProvider.overrideWith((ref) async => [_egg, _soup]),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  FakeAnalytics? analytics,
  bool saved = true,
  ThemeData? theme,
}) async {
  final container = _container(analytics ?? FakeAnalytics());
  if (saved) await container.read(savedMealsProvider.notifier).saveMeal(_meal);
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      ...savedTabRoutes,
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => Text('recipe/${state.pathParameters['id']}'),
      ),
      GoRoute(path: '/search', builder: (_, _) => const Text('tìm kiếm')),
      GoRoute(path: '/plan', builder: (_, state) => Text('at ${state.uri}')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: theme ?? AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push(savedMealLocation(_meal.key));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('SavedMealViewModel', () {
    test('tìm bữa theo khoá; không còn thì null', () async {
      final container = _container(FakeAnalytics());
      await container.read(savedMealsProvider.notifier).saveMeal(_meal);
      final provider = savedMealViewModelProvider(_meal.key);
      container.listen(provider, (_, _) {});
      await container.read(recipesProvider.future);
      final entry = container.read(provider).requireValue!;
      expect(entry.recipes, [_egg, _soup]);
      expect(entry.name, 'Trứng chiên hành + Canh cải');

      final missing = savedMealViewModelProvider('khong-co');
      container.listen(missing, (_, _) {});
      expect(container.read(missing).requireValue, isNull);
    });

    test('Thêm vào thực đơn: ghi add_meal_to_plan khi thêm được', () async {
      final analytics = FakeAnalytics();
      final container = _container(analytics);
      await container.read(savedMealsProvider.notifier).saveMeal(_meal);
      final provider = savedMealViewModelProvider(_meal.key);
      container.listen(provider, (_, _) {});
      await container.read(recipesProvider.future);

      List<Recipe>? shown;
      await container.read(provider.notifier).addToPlan((dishes) async {
        shown = dishes;
        return false;
      });
      expect(shown, [_egg, _soup]);
      expect(analytics.events, isEmpty);

      await container.read(provider.notifier).addToPlan((_) async => true);
      expect(analytics.events, ['add_meal_to_plan']);
      expect(analytics.params.last, {'dishes': 2});
    });

    test('Bỏ lưu rồi Hoàn tác', () async {
      final analytics = FakeAnalytics();
      final container = _container(analytics);
      await container.read(savedMealsProvider.notifier).saveMeal(_meal);
      final provider = savedMealViewModelProvider(_meal.key);
      container.listen(provider, (_, _) {});
      await container.read(recipesProvider.future);

      final outcome = await container.read(provider.notifier).unsave();
      expect(container.read(savedMealsProvider), isEmpty);
      expect(container.read(provider).requireValue, isNull);
      expect(analytics.params.last, {'kind': 'meal', 'undo': false});

      await outcome!.undo();
      expect(container.read(savedMealsProvider), [_meal]);
      expect(analytics.params.last, {'kind': 'meal', 'undo': true});
    });
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('Chi tiết bữa ($name): ảnh ghép, món, tag, bấm món mở Chi tiết món', (
      tester,
    ) async {
      await _pump(tester, theme: theme);
      expect(find.text(DiscoverStrings.savedMealMeta(2, 2)), findsOneWidget);
      expect(find.text(RecipeTag.cheap.label), findsOneWidget);
      expect(find.byType(RecipeRow), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Canh cải'));
      await tester.pumpAndSettle();
      expect(find.text('recipe/canh-cai'), findsOneWidget);
    });
  }

  testWidgets('Thêm vào thực đơn mở sheet chọn ngày', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(DiscoverStrings.savedMealAddToPlan));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Bỏ lưu: về Đã lưu, snackbar Hoàn tác lưu lại', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text(DiscoverStrings.savedMealUnsave));
    await tester.pumpAndSettle();

    expect(container.read(savedMealsProvider), isEmpty);
    expect(find.text(DiscoverStrings.savedMealDishes), findsNothing);
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
    expect(find.text(DiscoverStrings.savedUnsaved('Trứng chiên hành + Canh cải')), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(container.read(savedMealsProvider), [_meal]);
    expect(find.text('Trứng chiên hành + Canh cải'), findsOneWidget);
  });

  testWidgets('bữa không còn: EmptyState, nút về Đã lưu', (tester) async {
    await _pump(tester, saved: false);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(DiscoverStrings.savedMealNotFound), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedMealBack));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
  });
}
