import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history_entry/history_entry_screen.dart';

import 'fixtures.dart';

void main() {
  testWidgets('HistoryEntryScreen hiển thị món, sửa đánh giá, ghi chú và bấm Nấu lại', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
      ],
    );

    final entry = CookHistoryEntry(
      id: 'entry-1',
      cookedAt: DateTime(2026, 10, 25, 12),
      dishes: const [
        HistoryDish(
          recipeId: 'trung',
          servings: 2,
          rating: CookRating.good,
          note: 'Lần đầu nấu',
        ),
      ],
      minutes: 20,
      note: 'Rất vừa miệng',
    );

    await container.read(cookHistoryEntriesProvider.notifier).add(entry);

    String? pushedRoute;
    final router = GoRouter(
      initialLocation: historyEntryLocation('entry-1'),
      routes: [
        GoRoute(
          path: historyLocation,
          builder: (_, _) => const Scaffold(body: Text('at history')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => HistoryEntryScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) => Scaffold(body: Text('recipe ${state.pathParameters['id']}')),
          routes: [
            GoRoute(
              path: 'prep',
              builder: (_, state) {
                pushedRoute = 'prep:${state.pathParameters['id']}';
                return Scaffold(body: Text('prep ${state.pathParameters['id']}'));
              },
            ),
          ],
        ),
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

    expect(find.text('Trứng chiên hành'), findsWidgets);
    expect(find.text('Nấu lại món này'), findsOneWidget);
    expect(find.text('Thêm vào thực đơn'), findsOneWidget);

    // Chấm lại thành Tạm
    await tester.tap(find.text('Tạm'));
    await tester.pumpAndSettle();

    final updated = container.read(cookHistoryEntriesProvider).single;
    expect(updated.dishes.first.rating, CookRating.ok);

    // Bấm Nấu lại món này
    await tester.tap(find.text('Nấu lại món này'));
    await tester.pumpAndSettle();

    expect(pushedRoute, 'prep:trung');
  });

  testWidgets('HistoryEntryScreen xoá và hoàn tác', (tester) async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
      ],
    );

    final entry = CookHistoryEntry(
      id: 'entry-del',
      cookedAt: DateTime(2026, 10, 25, 12),
      dishes: const [
        HistoryDish(recipeId: 'trung', servings: 2),
      ],
    );
    await container.read(cookHistoryEntriesProvider.notifier).add(entry);

    final router = GoRouter(
      initialLocation: historyEntryLocation('entry-del'),
      routes: [
        GoRoute(
          path: historyLocation,
          builder: (_, _) => const Scaffold(body: Text('at history')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => HistoryEntryScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
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

    // Mở popup menu và bấm Xoá
    await tester.tap(find.byTooltip('Tuỳ chọn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xoá khỏi lịch sử'));
    await tester.pumpAndSettle();

    expect(find.text('at history'), findsOneWidget);
    expect(container.read(cookHistoryEntriesProvider), isEmpty);

    // Bấm Hoàn tác trên SnackBar
    expect(find.text('Hoàn tác'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();

    expect(container.read(cookHistoryEntriesProvider), hasLength(1));
    expect(container.read(cookHistoryEntriesProvider).first.id, 'entry-del');
  });
}
