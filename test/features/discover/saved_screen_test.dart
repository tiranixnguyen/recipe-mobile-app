import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

final _now = DateTime(2026, 11, 2, 12);

/// Ribbon "Mới thêm" (Banner vẽ chữ bằng painter nên không tìm được bằng `find.text`).
final _justAdded = find.byWidgetPredicate(
  (w) => w is Banner && w.message == DiscoverStrings.savedJustAdded,
);

const _egg = Recipe(
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
const _tofu = Recipe(
  id: 'dau-phu-sot',
  name: 'Đậu phụ sốt cà',
  description: '',
  imageAsset: '',
  minutes: 20,
  servings: 2,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<String> savedIds = const [],
  List<SavedMeal> savedMeals = const [],
  Future<List<Recipe>> Function()? recipes,
  ThemeData? theme,
  String location = '/saved',
}) async {
  final store = InMemoryLocalStore();
  await store.writeList('discover.saved', savedIds);
  // Món trong [savedIds] lưu lúc 11:00 hôm nay; bữa lưu lúc 12:00.
  await store.writeString(
    'discover.savedAt',
    jsonEncode({
      for (final id in savedIds) id: _now.subtract(const Duration(hours: 1)).toIso8601String(),
    }),
  );

  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => store),
      ingredientsProvider.overrideWith(
        (ref) async => const [
          Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
        ],
      ),
      recipesProvider.overrideWith((ref) => (recipes ?? () async => const [_egg, _tofu])()),
      savedClockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);

  // Seed saved meals
  for (final meal in savedMeals) {
    await container.read(savedMealsProvider.notifier).saveMeal(meal);
  }

  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...savedTabRoutes,
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => Text('recipe/${state.pathParameters['id']}'),
      ),
      GoRoute(path: '/', builder: (_, _) => const Text('khám phá')),
      GoRoute(path: '/search', builder: (_, _) => const Text('khám phá')),
      GoRoute(path: todayPrefsLocation, builder: (_, _) => const Text('gợi ý cho mình')),
      GoRoute(path: '/today', builder: (_, _) => const Text('gợi ý cho mình')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('trống: EmptyState, nút Khám phá món', (tester) async {
    await _pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text(DiscoverStrings.savedEmptyRecipesAction));
    await tester.pumpAndSettle();
    expect(find.text('khám phá'), findsOneWidget);
  });

  testWidgets('món và bữa chung một danh sách, nhóm theo thời gian, không còn tab', (tester) async {
    await _pump(
      tester,
      savedIds: ['trung-chien'],
      savedMeals: [
        SavedMeal(
          recipeIds: const ['dau-phu-sot', 'trung-chien'],
          servings: 2,
          tags: const [RecipeTag.cheap],
        ).withSavedAt(_now.subtract(const Duration(days: 1))),
      ],
    );

    expect(find.byType(TabBar), findsNothing);
    expect(find.text(DiscoverStrings.savedCount(2)), findsOneWidget);
    expect(find.text(DiscoverStrings.savedGroupToday), findsOneWidget);
    expect(find.text(DiscoverStrings.savedGroupYesterday), findsOneWidget);
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà + Trứng chiên hành'), findsOneWidget);
    expect(find.text(DiscoverStrings.savedMealMeta(2, 2)), findsOneWidget);
    expect(find.text(RecipeTag.cheap.label), findsOneWidget);
    expect(find.byType(MealMosaic), findsOneWidget);
    expect(find.byType(SaveButton), findsNothing);
    // Món ở trên (Hôm nay), bữa ở dưới (Hôm qua).
    expect(
      tester.getTopLeft(find.text('Trứng chiên hành')).dy,
      lessThan(tester.getTopLeft(find.text('Đậu phụ sốt cà + Trứng chiên hành')).dy),
    );
  });

  testWidgets('bấm thẻ món mở Chi tiết món', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);
    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('recipe/trung-chien'), findsOneWidget);
  });

  testWidgets('bấm thẻ bữa mở Chi tiết bữa', (tester) async {
    await _pump(
      tester,
      savedMeals: [
        const SavedMeal(recipeIds: ['trung-chien', 'dau-phu-sot'], servings: 2),
      ],
    );
    await tester.tap(find.text('Trứng chiên hành + Đậu phụ sốt cà'));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.savedMealDishes), findsOneWidget);
    expect(find.text(DiscoverStrings.savedMealAddToPlan), findsOneWidget);
  });

  testWidgets('mở qua savedLocation(highlightMeal) thì bữa đó có ribbon Mới thêm', (tester) async {
    const meal = SavedMeal(recipeIds: ['trung-chien'], servings: 1);
    expect(savedLocation(), '/saved');
    expect(savedLocation(highlightMeal: meal.key), '/saved?new=trung-chien');

    await _pump(
      tester,
      location: savedLocation(highlightMeal: meal.key),
      savedIds: ['trung-chien'],
      savedMeals: const [meal],
    );
    expect(_justAdded, findsOneWidget);
  });

  testWidgets('không mở qua link thì không có ribbon', (tester) async {
    await _pump(
      tester,
      savedMeals: const [
        SavedMeal(recipeIds: ['trung-chien'], servings: 1),
      ],
    );
    expect(_justAdded, findsNothing);
  });

  testWidgets('tìm khớp cả món và bữa, bỏ dấu', (tester) async {
    await _pump(
      tester,
      savedIds: ['trung-chien', 'dau-phu-sot'],
      savedMeals: const [
        SavedMeal(recipeIds: ['dau-phu-sot', 'trung-chien'], servings: 1),
      ],
    );

    await tester.enterText(find.byType(TextField), 'trung');
    await tester.pump();
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà + Trứng chiên hành'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà'), findsNothing);
  });

  testWidgets('tìm không ra: hiện câu không thấy', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);

    await tester.enterText(find.byType(TextField), 'xyzabc');
    await tester.pump();
    expect(find.text(DiscoverStrings.savedNoMatch('xyzabc')), findsOneWidget);
    expect(find.text('Trứng chiên hành'), findsNothing);
  });

  testWidgets('mẹo kéo thả hiện khi có ít nhất một mục', (tester) async {
    final container = await _pump(tester, savedIds: ['trung-chien']);
    expect(container.read(tipsSeenProvider).contains(savedDragTip), isFalse);
    expect(find.textContaining('kéo vào thùng rác', findRichText: true), findsOneWidget);
  });

  testWidgets('kéo bữa vào thùng rác: bỏ lưu, ẩn mẹo, Hoàn tác lưu lại', (tester) async {
    final container = await _pump(
      tester,
      savedMeals: const [
        SavedMeal(recipeIds: ['trung-chien', 'dau-phu-sot'], servings: 2),
      ],
    );
    const name = 'Trứng chiên hành + Đậu phụ sốt cà';

    final gesture = await tester.startGesture(tester.getCenter(find.text(name)));
    await tester.pump(HoldDraggable.delay + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(find.text(DiscoverStrings.savedTrashHint), findsOneWidget);
    await gesture.moveTo(tester.getCenter(find.text(DiscoverStrings.savedTrashHint)));
    await tester.pump();
    expect(find.text(DiscoverStrings.savedTrashDanger), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(container.read(savedMealsProvider), isEmpty);
    expect(container.read(tipsSeenProvider).contains(savedDragTip), isTrue);
    expect(find.text(DiscoverStrings.savedUnsaved(name)), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(container.read(savedMealsProvider), hasLength(1));
    expect(find.text(name), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Bỏ lưu qua action trợ năng
  // ---------------------------------------------------------------------------

  testWidgets('action "Bỏ lưu" bỏ món khỏi danh sách + snackbar Hoàn tác', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await _pump(tester, savedIds: ['trung-chien']);

    final node = tester.getSemantics(find.text('Trứng chiên hành'));
    final actionId = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: DiscoverStrings.savedUnsaveAction),
    );
    node.owner!.performAction(node.id, SemanticsAction.customAction, actionId);
    await tester.pumpAndSettle();

    expect(container.read(savedIdsProvider), isEmpty);
    expect(find.text(DiscoverStrings.savedUnsaved('Trứng chiên hành')), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedUndo));
    await tester.pumpAndSettle();
    expect(container.read(savedIdsProvider), isNotEmpty);
    handle.dispose();
  });

  testWidgets('Delete key bỏ lưu món', (tester) async {
    final container = await _pump(tester, savedIds: ['trung-chien']);

    Focus.of(tester.element(find.text('Trứng chiên hành'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(container.read(savedIdsProvider), isEmpty);
    expect(find.text(DiscoverStrings.savedUnsaved('Trứng chiên hành')), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Trạng thái lỗi
  // ---------------------------------------------------------------------------

  testWidgets('dữ liệu lỗi thì hiện câu lỗi', (tester) async {
    await _pump(
      tester,
      savedIds: ['trung-chien'],
      recipes: () => Future.error(const FormatException('hỏng')),
    );
    expect(find.text(DiscoverStrings.loadError), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Theme tối
  // ---------------------------------------------------------------------------

  testWidgets('chạy được ở theme tối', (tester) async {
    await _pump(tester, savedIds: ['trung-chien'], theme: AppTheme.dark);
    expect(tester.takeException(), isNull);
  });
}
