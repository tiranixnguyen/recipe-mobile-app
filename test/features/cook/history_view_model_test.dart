import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/history_entries.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history/history_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history_entry/history_entry_view_model.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => []),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('filter and accent-insensitive search by note', () async {
    final entries = container.read(cookHistoryEntriesProvider.notifier);
    await entries.add(
      CookHistoryEntry(
        id: 'one',
        cookedAt: DateTime(2026, 10, 23),
        dishes: const [
          HistoryDish(recipeId: 'trung', servings: 1, rating: CookRating.good, note: 'Bớt muối'),
        ],
      ),
    );
    await entries.add(
      CookHistoryEntry(
        id: 'two',
        cookedAt: DateTime(2026, 10, 24),
        dishes: const [HistoryDish(recipeId: 'mi', servings: 2)],
      ),
    );
    final vm = container.read(historyViewModelProvider.notifier);
    expect(container.read(historyViewModelProvider).visible, hasLength(2));
    vm.search('bot muoi');
    expect(container.read(historyViewModelProvider).visible.map((e) => e.id), ['one']);
    vm.search('');
    vm.filter('good');
    expect(container.read(historyViewModelProvider).visible.map((e) => e.id), ['one']);
    vm.filter('note');
    expect(container.read(historyViewModelProvider).visible.map((e) => e.id), ['one']);
  });

  test('entry view model updates rating and notes then deletes and undoes', () async {
    await container
        .read(cookHistoryEntriesProvider.notifier)
        .add(
          CookHistoryEntry(
            id: 'meal',
            cookedAt: DateTime(2026, 10, 23),
            dishes: const [HistoryDish(recipeId: 'trung', servings: 2)],
          ),
        );
    final vm = container.read(historyEntryViewModelProvider('meal').notifier);
    await vm.rate(0, CookRating.good);
    await vm.noteDish(0, 'Ít muối');
    await vm.noteMeal('Nấu nhanh');
    expect(
      container.read(historyEntryViewModelProvider('meal')).entry!.dishes.single.note,
      'Ít muối',
    );
    expect(
      container.read(historyEntryViewModelProvider('meal')).entry!.dishes.single.rating,
      CookRating.good,
    );
    final removed = await vm.delete();
    expect(container.read(cookHistoryEntriesProvider), isEmpty);
    await container.read(cookHistoryEntriesProvider.notifier).undo(removed!);
    expect(container.read(cookHistoryEntriesProvider).single.note, 'Nấu nhanh');
  });
}
