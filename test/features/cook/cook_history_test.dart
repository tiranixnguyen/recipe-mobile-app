import 'package:flutter/material.dart';
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

  test('ghi lần nấu kèm đánh giá, dựng lại vẫn còn', () async {
    final history = container.read(cookHistoryProvider.notifier);
    final first = DateTime(2026, 10, 23, 19);
    final second = DateTime(2026, 10, 24, 12);
    await history.record('trung-chien-hanh', rating: CookRating.good, at: first);
    await history.record('mi-xao', at: second);

    final expected = [
      CookRecord(recipeId: 'trung-chien-hanh', cookedAt: first, rating: CookRating.good),
      CookRecord(recipeId: 'mi-xao', cookedAt: second),
    ];
    expect(container.read(cookHistoryProvider), expected);
    expect(store().readString('cook.history'), isNotNull);

    container.invalidate(cookHistoryProvider);
    expect(container.read(cookHistoryProvider), expected);
  });

  test('bản ghi hỏng bị bỏ qua, JSON hỏng thì rỗng', () async {
    await store().writeString(
      'cook.history',
      '[{"recipeId": "a", "cookedAt": "2026-10-24T12:00:00.000", "rating": "wow"}, {"x": 1}]',
    );
    container.invalidate(cookHistoryProvider);
    expect(container.read(cookHistoryProvider), [
      CookRecord(recipeId: 'a', cookedAt: DateTime(2026, 10, 24, 12)),
    ]);

    await store().writeString('cook.history', '{');
    container.invalidate(cookHistoryProvider);
    expect(container.read(cookHistoryProvider), isEmpty);
  });

  test('xoá dữ liệu đưa về rỗng', () async {
    await container.read(cookHistoryProvider.notifier).record('a');
    await container.read(clearLocalDataProvider)();
    expect(container.read(cookHistoryProvider), isEmpty);
  });

  test('nhãn đánh giá theo màn Nấu xong', () {
    expect(CookRating.values.map((r) => r.label), ['Ngon', 'Tạm', 'Chê']);
  });

  testWidgets('ResumeCookingBanner stub không hiện gì', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: ResumeCookingBanner()),
      ),
    );
    expect(tester.getSize(find.byType(ResumeCookingBanner)), Size.zero);
  });
}
