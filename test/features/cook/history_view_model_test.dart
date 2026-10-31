import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history/history_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history_entry/history_entry_view_model.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const []),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('lọc và tìm bỏ dấu theo ghi chú', () async {
    final history = container.read(cookHistoryProvider.notifier);
    await history.recordEntry(
      CookHistoryEntry(
        id: 'one',
        cookedAt: DateTime(2026, 10, 23),
        meal: Meal.lunch,
        isMeal: false,
        dishes: [CookedDish(recipeId: 'trung', rating: CookRating.good, note: 'Bớt muối')],
      ),
    );
    await history.recordEntry(
      CookHistoryEntry(
        id: 'two',
        cookedAt: DateTime(2026, 10, 24),
        meal: Meal.lunch,
        isMeal: false,
        dishes: [CookedDish(recipeId: 'mi', servings: 2)],
      ),
    );
    final vm = container.read(historyViewModelProvider(null).notifier);
    expect(container.read(historyViewModelProvider(null)).visible, hasLength(2));

    vm.search('bot muoi');
    expect(container.read(historyViewModelProvider(null)).visible.map((e) => e.id), ['one']);

    vm.search('');
    vm.setFilter(HistoryFilter.good);
    expect(container.read(historyViewModelProvider(null)).visible.map((e) => e.id), ['one']);

    vm.setFilter(HistoryFilter.note);
    expect(container.read(historyViewModelProvider(null)).visible.map((e) => e.id), ['one']);
  });

  test('HistoryEntryViewModel sửa điểm, ghi chú, xoá rồi hoàn tác', () async {
    await container
        .read(cookHistoryProvider.notifier)
        .recordEntry(
          CookHistoryEntry(
            id: 'meal',
            cookedAt: DateTime(2026, 10, 23),
            meal: Meal.lunch,
            isMeal: false,
            dishes: [CookedDish(recipeId: 'trung', servings: 2)],
          ),
        );
    final vm = container.read(historyEntryViewModelProvider('meal').notifier);
    await vm.setDishRating(0, CookRating.good);
    await vm.setDishNote(0, 'Ít muối');
    await vm.setMealNote('Nấu nhanh');
    expect(
      container.read(historyEntryViewModelProvider('meal')).entry!.dishes.single.note,
      'Ít muối',
    );
    expect(
      container.read(historyEntryViewModelProvider('meal')).entry!.dishes.single.rating,
      CookRating.good,
    );

    final removed = await vm.delete();
    expect(container.read(cookHistoryProvider), isEmpty);

    await vm.restore(removed!);
    expect(container.read(cookHistoryProvider).single.mealNote, 'Nấu nhanh');
  });
}
