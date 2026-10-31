import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  testWidgets('PantryUpdateScreen món đơn: bỏ tick thì xoá khỏi tủ và hoàn thành', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
        ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
        appReviewProvider.overrideWithValue(FakeAppReview()),
      ],
    );
    for (final id in ['egg', 'scallion']) {
      await container.read(pantryItemsProvider.notifier).addToPantry(id);
    }
    await container.read(cookSessionProvider.notifier).startRecipe('trung', 2);

    final router = GoRouter(
      initialLocation: pantryUpdateLocation('trung'),
      routes: [
        GoRoute(path: '/plan', builder: (_, _) => const Text('at plan')),
        ...cookRoutes,
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyên liệu chưa dùng tới'), findsOneWidget);
    expect(find.text('Tick thứ vẫn còn trong tủ. Bỏ tick thì app xoá khỏi tủ.'), findsOneWidget);

    // Bỏ tick một nguyên liệu
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Hành lá'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sẽ xoá khỏi tủ: hành lá'), findsOneWidget);

    await tester.tap(find.text('Cập nhật tủ và xong'));
    await tester.pumpAndSettle();

    expect(container.read(pantryItemsProvider), {'egg'});
    expect(container.read(cookHistoryProvider), hasLength(1));
    expect(find.text('at plan'), findsOneWidget);
  });
}
