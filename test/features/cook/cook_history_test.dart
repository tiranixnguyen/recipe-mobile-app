import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    );
  });

  tearDown(() => container.dispose());

  LocalStore store() => container.read(localStoreProvider);

  test('mặc định rỗng', () {
    expect(container.read(cookHistoryProvider), isEmpty);
  });

  test('record() compat: ghi v2 entry, load lại vẫn còn', () async {
    final history = container.read(cookHistoryProvider.notifier);
    final first = DateTime(2026, 10, 23, 19);
    final second = DateTime(2026, 10, 24, 12);
    await history.record('trung-chien-hanh', rating: CookRating.good, at: first);
    await history.record('mi-xao', at: second);

    final entries = container.read(cookHistoryProvider);
    expect(entries.length, 2);
    expect(entries[0].recipeId, 'trung-chien-hanh');
    expect(entries[0].rating, CookRating.good);
    expect(entries[1].recipeId, 'mi-xao');
    expect(entries[1].rating, null);

    container.invalidate(cookHistoryProvider);
    expect(container.read(cookHistoryProvider).length, 2);
  });

  test('migration v1: CookRecord format → CookHistoryEntry, rating giữ nguyên', () async {
    await store().writeString(
      'cook.history',
      '[{"recipeId": "a", "cookedAt": "2026-10-24T12:00:00.000", "rating": "good"}]',
    );
    container.invalidate(cookHistoryProvider);
    final entries = container.read(cookHistoryProvider);
    expect(entries.length, 1);
    expect(entries[0].recipeId, 'a');
    expect(entries[0].rating, CookRating.good);
    expect(entries[0].isMeal, false);
    expect(entries[0].servings, 1);
  });

  test('bản ghi hỏng bị bỏ qua, JSON hỏng thì rỗng', () async {
    await store().writeString(
      'cook.history',
      '[{"recipeId": "a", "cookedAt": "2026-10-24T12:00:00.000", "rating": "wow"}, {"x": 1},'
          ' {"recipeId": "b", "cookedAt": 1}]',
    );
    container.invalidate(cookHistoryProvider);
    final entries = container.read(cookHistoryProvider);
    // "a" migrates but "wow" rating is dropped; {"x":1} and bad cookedAt dropped
    expect(entries.length, 1);
    expect(entries[0].recipeId, 'a');
    expect(entries[0].rating, null); // "wow" is invalid

    await store().writeString('cook.history', '{');
    container.invalidate(cookHistoryProvider);
    expect(container.read(cookHistoryProvider), isEmpty);
  });

  test('delete xoá entry, restore khôi phục đúng thứ tự', () async {
    final history = container.read(cookHistoryProvider.notifier);
    final t1 = DateTime(2026, 10, 23);
    final t2 = DateTime(2026, 10, 24);
    final t3 = DateTime(2026, 10, 25);
    await history.record('a', at: t1);
    await history.record('b', at: t2);
    await history.record('c', at: t3);

    final deleted = await history.delete(container.read(cookHistoryProvider)[1].id);
    expect(deleted, isNotNull);
    expect(container.read(cookHistoryProvider).length, 2);
    expect(container.read(cookHistoryProvider).map((e) => e.recipeId), ['a', 'c']);

    await history.restore(deleted!);
    expect(container.read(cookHistoryProvider).length, 3);
    expect(container.read(cookHistoryProvider).map((e) => e.recipeId), ['a', 'b', 'c']);
  });

  test('updateDishNote giới hạn 300 ký tự', () async {
    final history = container.read(cookHistoryProvider.notifier);
    await history.record('a');
    final entryId = container.read(cookHistoryProvider).first.id;
    final longNote = 'x' * 400;
    await history.updateDishNote(entryId, 0, longNote);
    final updated = container.read(cookHistoryProvider).first;
    expect(updated.dishes.first.note.length, 300);
  });

  test('xoá dữ liệu đưa về rỗng', () async {
    await container.read(cookHistoryProvider.notifier).record('a');
    await container.read(clearLocalDataProvider)();
    expect(container.read(cookHistoryProvider), isEmpty);
  });

  test('nhãn đánh giá theo màn Nấu xong', () {
    expect(CookRating.values.map((r) => r.label), ['Ngon', 'Tạm', 'Chê']);
  });
}
