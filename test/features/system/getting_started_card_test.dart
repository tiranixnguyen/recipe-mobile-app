import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(InMemoryLocalStore())],
    );
    await container.read(onboardingDoneProvider.notifier).complete();
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                GettingStartedCard(),
                StartHint(StartHintSpot.pantryAdd),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('hiện 4 dòng, tiến độ 0/4 và nút của bước kế tiếp', (tester) async {
    await pump(tester);

    expect(find.text(SystemStrings.startTitle), findsOneWidget);
    expect(find.text(SystemStrings.startProgress(0, 4)), findsOneWidget);
    for (final title in [
      SystemStrings.startPantry,
      SystemStrings.startShopping,
      SystemStrings.startPlan,
      SystemStrings.startCook,
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text(SystemStrings.startPantryAction), findsOneWidget);
    expect(find.text(SystemStrings.startPlanAction), findsNothing);
    expect(find.text(SystemStrings.hintPantryAdd), findsOneWidget);
  });

  testWidgets('tick một bước thì tiến độ 1/4 và gợi ý pantryAdd biến mất', (tester) async {
    await pump(tester);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await tester.pump();

    expect(find.text(SystemStrings.startProgress(1, 4)), findsOneWidget);
    expect(find.text(SystemStrings.hintPantryAdd), findsNothing);
  });

  testWidgets('bấm Ẩn thì thẻ biến mất', (tester) async {
    await pump(tester);

    await tester.tap(find.text(SystemStrings.startHide));
    await tester.pump();

    expect(find.text(SystemStrings.startTitle), findsNothing);
  });

  testWidgets('xong cả bốn bước thì hiện trạng thái mừng, Đóng thì ẩn', (tester) async {
    await pump(tester);
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await container.read(shoppingItemsProvider.notifier).addIngredient('hanh');
    await container
        .read(plannedMealsProvider.notifier)
        .addToPlan('trung', DateTime.now(), Meal.dinner);
    await container.read(cookHistoryProvider.notifier).record('trung', rating: CookRating.good);
    await tester.pump();

    expect(find.text(SystemStrings.startDoneTitle), findsOneWidget);
    expect(find.text(SystemStrings.startDoneBody), findsOneWidget);

    await tester.tap(find.text(SystemStrings.startClose));
    await tester.pump();

    expect(find.text(SystemStrings.startDoneTitle), findsNothing);
  });
}
