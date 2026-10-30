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
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

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
}) async {
  final store = InMemoryLocalStore();
  await store.writeList('discover.saved', savedIds);

  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => store),
      ingredientsProvider.overrideWith(
        (ref) async => const [
          Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
        ],
      ),
      recipesProvider.overrideWith((ref) => (recipes ?? () async => const [_egg, _tofu])()),
    ],
  );
  addTearDown(container.dispose);

  // Seed saved meals
  for (final meal in savedMeals) {
    await container.read(savedMealsProvider.notifier).saveMeal(meal);
  }

  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
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
  // ---------------------------------------------------------------------------
  // Trống
  // ---------------------------------------------------------------------------

  testWidgets('tab Món trống: EmptyState, nút Khám phá', (tester) async {
    await _pump(tester);

    expect(find.text(DiscoverStrings.savedTabRecipes(0)), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(DiscoverStrings.savedEmptyTitle), findsOneWidget);
    expect(find.text(DiscoverStrings.savedEmptyRecipesAction), findsOneWidget);

    await tester.tap(find.text(DiscoverStrings.savedEmptyRecipesAction));
    await tester.pumpAndSettle();
    expect(find.text('khám phá'), findsOneWidget);
  });

  testWidgets('tab Bữa trống: EmptyState, nút Gợi ý', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);
    await tester.tap(find.text(DiscoverStrings.savedTabMeals(0)));
    await tester.pumpAndSettle();

    expect(find.text(DiscoverStrings.savedEmptyMealsTitle), findsOneWidget);
    await tester.tap(find.text(DiscoverStrings.savedEmptyMealsAction));
    await tester.pumpAndSettle();
    expect(find.text('gợi ý cho mình'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Tab Món
  // ---------------------------------------------------------------------------

  testWidgets('có món: hiện theo lưới 2 cột, search field xuất hiện', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);

    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Không có SaveButton trên thẻ
    expect(find.byType(SaveButton), findsNothing);
  });

  testWidgets('bấm thẻ mở Chi tiết món', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);
    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('recipe/trung-chien'), findsOneWidget);
  });

  testWidgets('đếm tab cập nhật khi có món', (tester) async {
    await _pump(tester, savedIds: ['trung-chien', 'dau-phu-sot']);
    expect(find.text(DiscoverStrings.savedTabRecipes(2)), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Tab Bữa
  // ---------------------------------------------------------------------------

  testWidgets('tab Bữa hiện thẻ ngang với MealMosaic và tag', (tester) async {
    await _pump(
      tester,
      savedMeals: [
        const SavedMeal(recipeIds: ['trung-chien'], servings: 1, tags: [RecipeTag.cheap]),
      ],
    );
    await tester.tap(find.text(DiscoverStrings.savedTabMeals(1)));
    await tester.pumpAndSettle();

    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text(RecipeTag.cheap.label), findsOneWidget);
  });

  testWidgets('bấm thẻ bữa mở Gợi ý', (tester) async {
    await _pump(
      tester,
      savedMeals: [
        const SavedMeal(recipeIds: ['trung-chien'], servings: 1),
      ],
    );
    await tester.tap(find.text(DiscoverStrings.savedTabMeals(1)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trứng chiên hành'));
    await tester.pumpAndSettle();
    expect(find.text('gợi ý cho mình'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Tìm kiếm
  // ---------------------------------------------------------------------------

  testWidgets('tìm lọc món theo tên (bỏ dấu)', (tester) async {
    await _pump(tester, savedIds: ['trung-chien', 'dau-phu-sot']);

    await tester.enterText(find.byType(TextField), 'trung');
    await tester.pump();
    expect(find.text('Trứng chiên hành'), findsOneWidget);
    expect(find.text('Đậu phụ sốt cà'), findsNothing);
  });

  testWidgets('tìm không ra: hiện câu không thấy', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);

    await tester.enterText(find.byType(TextField), 'xyzabc');
    await tester.pump();
    expect(find.textContaining('xyzabc'), findsWidgets);
    expect(find.text('Trứng chiên hành'), findsNothing);
  });

  testWidgets('nút xoá từ khoá', (tester) async {
    await _pump(tester, savedIds: ['trung-chien']);

    await tester.enterText(find.byType(TextField), 'trung');
    await tester.pump();
    await tester.tap(find.byTooltip(DiscoverStrings.clearQuery));
    await tester.pump();
    expect(find.text('Trứng chiên hành'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TipBubble
  // ---------------------------------------------------------------------------

  testWidgets('mẹo kéo thả xuất hiện khi có ít nhất một thứ đã lưu', (tester) async {
    final container = await _pump(tester, savedIds: ['trung-chien']);
    // Mẹo chưa bị ẩn
    expect(container.read(tipsSeenProvider).contains(savedDragTip), isFalse);
    expect(
      find.textContaining('kéo vào thùng rác', findRichText: true),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------------
  // Bỏ lưu qua action trợ năng (thay thế cho drag trong unit test)
  // ---------------------------------------------------------------------------

  testWidgets('action "Bỏ lưu" bỏ món khỏi danh sách + snackbar Hoàn tác', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await _pump(tester, savedIds: ['trung-chien']);

    final node = tester.getSemantics(find.text('Trứng chiên hành'));
    final actionId = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: DiscoverStrings.savedRecipeUnsaveAction),
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
