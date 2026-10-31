import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import '../../core/fake_analytics.dart';

const _egg = Recipe(
  id: 'trung-chien',
  name: 'Trứng chiên hành',
  description: 'Trứng rán vàng ươm',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.breakfast, Meal.lunch, Meal.dinner],
  ingredients: [RecipeIngredient(id: 'egg', amount: 2, unit: 'quả')],
  steps: [RecipeStep(text: 'Đập trứng')],
);

const _tofu = Recipe(
  id: 'dau-phu-sot',
  name: 'Đậu phụ sốt cà',
  description: 'Đậu phụ sốt cà chua',
  imageAsset: '',
  minutes: 20,
  servings: 2,
  tools: [Tool.stove],
  diets: [],
  meals: [Meal.lunch, Meal.dinner],
  ingredients: [RecipeIngredient(id: 'tofu', amount: 2, unit: 'bìa')],
  steps: [RecipeStep(text: 'Rán đậu')],
);

void main() {
  late ProviderContainer container;
  late InMemoryLocalStore store;
  late FakeAnalytics analytics;

  setUp(() {
    store = InMemoryLocalStore();
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(analytics),
        recipesProvider.overrideWith((ref) async => [_egg, _tofu]),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
            Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
          ],
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  testWidgets('Đồng bộ lưu món từ Detail sang Saved và ngược lại', (tester) async {
    final router = GoRouter(
      initialLocation: recipeLocation('trung-chien'),
      routes: [
        ...cookRoutes,
        GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Ban đầu chưa lưu
    expect(container.read(savedIdsProvider), isEmpty);
    final bookmarkBtn = find.byType(SaveButton);
    expect(bookmarkBtn, findsOneWidget);

    // Bấm lưu ở màn Detail
    await tester.tap(bookmarkBtn);
    await tester.pumpAndSettle();

    expect(container.read(savedIdsProvider), contains('trung-chien'));
    expect(store.readList('discover.saved'), contains('trung-chien'));

    // Chuyển sang màn Saved
    router.go('/saved');
    await tester.pumpAndSettle();

    // Món đã xuất hiện trong danh sách Đã lưu
    expect(find.text('Trứng chiên hành'), findsOneWidget);

    // Bỏ lưu bằng API hoặc xóa
    await container.read(savedIdsProvider.notifier).unsave('trung-chien');
    await tester.pumpAndSettle();

    // Món biến mất khỏi Saved, hiện EmptyState
    expect(find.text('Trứng chiên hành'), findsNothing);
    expect(find.text('Chưa lưu món nào'), findsOneWidget);

    // Quay lại Detail -> Bookmark tự cập nhật về chưa lưu
    router.go(recipeLocation('trung-chien'));
    await tester.pumpAndSettle();
    expect(container.read(savedIdsProvider).contains('trung-chien'), isFalse);
  });

  testWidgets('Đồng bộ độ sẵn đồ giữa Pantry và SavedScreen', (tester) async {
    await container.read(savedIdsProvider.notifier).save('trung-chien');

    final router = GoRouter(
      initialLocation: '/saved',
      routes: [
        GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tủ đồ ban đầu trống -> Thiếu: trứng
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.byType(AvailabilityBadge), findsOneWidget);
    expect(find.text('Thiếu: trứng'), findsOneWidget);

    // Thêm trứng vào tủ đồ
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await tester.pumpAndSettle();

    // Badge tự động cập nhật sang Đủ đồ
    expect(find.text('Đủ đồ'), findsOneWidget);
  });

  testWidgets('Đồng bộ lưu bữa từ TodayScreen sang SavedScreen kèm analytics', (tester) async {
    final router = GoRouter(
      initialLocation: todayLocation,
      routes: [
        ...discoverRoutes,
        GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Nút Lưu lại tại TodayScreen
    final saveBtn = find.byKey(const Key('today-save-btn'));
    expect(saveBtn, findsOneWidget);

    // Bấm lưu bữa tại Today (2 món: main và alternative)
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(container.read(savedMealsProvider), isNotEmpty);
    expect(analytics.events.contains('save_meal'), isTrue);

    // Chuyển sang SavedScreen
    router.go('/saved');
    await tester.pumpAndSettle();

    // Tab Bữa ăn có 1 bữa
    expect(find.text(DiscoverStrings.savedTabMeals(1)), findsOneWidget);
    await tester.tap(find.text(DiscoverStrings.savedTabMeals(1)));
    await tester.pumpAndSettle();

    // Tên món xuất hiện trong thẻ bữa
    expect(find.textContaining('Trứng chiên hành'), findsOneWidget);
  });
}
