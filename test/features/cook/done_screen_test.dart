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
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import 'fakes.dart';
import 'fixtures.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: cookDoneLocation('trung'),
    routes: [
      GoRoute(path: discoverLocation, builder: (_, _) => const Text('at discover')),
      ...cookRoutes,
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
      appReviewProvider.overrideWithValue(FakeAppReview()),
    ],
  );
  addTearDown(container.dispose);
  for (final id in ['egg', 'scallion']) {
    await container.read(pantryItemsProvider.notifier).addToPantry(id);
  }
  await container.read(cookSessionProvider.notifier).startRecipe('trung', 2);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('tick Hết, chấm Chê, lưu món; xong thì tủ bớt đồ, lịch sử có đánh giá', (
    tester,
  ) async {
    final container = await _pump(tester);

    expect(find.text(CookStrings.doneTitle), findsOneWidget);
    expect(find.text('Trứng chiên hành · 2 người · 4 bước'), findsOneWidget);
    expect(find.text('Đã dùng 4 quả'), findsOneWidget);
    expect(find.text(CookStrings.demotedNote), findsNothing);

    await tester.tap(find.bySemanticsLabel(CookStrings.usedUpLabel('Hành lá')));
    await tester.tap(find.text('Chê'));
    await tester.pump();
    expect(find.text(CookStrings.demotedNote), findsOneWidget);

    await tester.tap(find.text(CookStrings.saveForLater));
    await tester.pump();
    expect(find.text(CookStrings.saved), findsOneWidget);
    expect(container.read(savedIdsProvider), {'trung'});

    await tester.tap(find.text(CookStrings.finishAndUpdate));
    await tester.pumpAndSettle();
    expect(container.read(pantryItemsProvider), {'egg'});
    expect(container.read(cookHistoryProvider).single.rating, CookRating.bad);
    expect(find.text('at discover'), findsOneWidget);
  });

  for (final (name, theme) in [('sáng', AppTheme.light), ('tối', AppTheme.dark)]) {
    testWidgets('màn 360dp, chữ 1.3, theme $name: không tràn', (tester) async {
      await _pump(tester, theme: theme, size: const Size(360, 640), textScale: 1.3);
      await tester.scrollUntilVisible(find.text('Chê'), 100);
      await tester.tap(find.text('Chê'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CookStrings.finishAndUpdate), findsOneWidget);
    });
  }
}
