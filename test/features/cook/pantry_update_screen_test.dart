import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import 'fakes.dart';

void main() {
  testWidgets('PantryUpdateScreen: bỏ tick thì xoá khỏi tủ, ghi lịch sử và mở Lịch sử', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        appReviewProvider.overrideWithValue(FakeAppReview()),
      ],
    );
    addTearDown(container.dispose);
    for (final id in ['egg', 'scallion']) {
      await container.read(pantryItemsProvider.notifier).addToPantry(id);
    }
    container
        .read(pendingCookProvider.notifier)
        .set(
          PendingCookData(
            dishes: [CookedDish(recipeId: 'trung', servings: 2, rating: CookRating.good)],
            isMeal: false,
            meal: Meal.lunch,
            minutes: 10,
            usedItems: const [
              UsedItem(ingredientId: 'egg', name: 'Trứng gà', note: 'Đã dùng 2 quả'),
              UsedItem(ingredientId: 'scallion', name: 'Hành lá', note: 'Đã dùng 1 nắm'),
            ],
          ),
        );

    String? lastLocation;
    final router = GoRouter(
      initialLocation: pantryUpdateLocation,
      routes: [
        GoRoute(
          path: historyLocation,
          builder: (_, state) {
            lastLocation = state.uri.toString();
            return const Scaffold(body: Text('at history'));
          },
        ),
        ...cookRoutes,
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(CookStrings.pantryUpdateTitle), findsOneWidget);
    expect(find.text(CookStrings.pantryUpdateHint), findsOneWidget);
    expect(find.text(CookStrings.pantryWillRemoveNothing), findsOneWidget);

    // Bỏ tick "Hành lá": vẫn còn trong tủ → sẽ bị xoá.
    await tester.tap(find.text('Hành lá'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hành lá'), findsOneWidget);

    await tester.tap(find.text(CookStrings.pantryUpdateFinish));
    await tester.pumpAndSettle();

    expect(container.read(pantryItemsProvider), {'egg'});
    expect(container.read(cookHistoryProvider), hasLength(1));
    expect(container.read(cookHistoryProvider).single.dishes.single.recipeId, 'trung');
    expect(find.text('at history'), findsOneWidget);
    expect(lastLocation, startsWith('$historyLocation?highlight='));
  });
}
