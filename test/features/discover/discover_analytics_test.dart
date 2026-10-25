import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class _Events implements Analytics {
  final names = <String>[];
  @override
  void track(String event, [Map<String, Object>? params]) => names.add(event);
}

void main() {
  testWidgets('view_discover ghi lượt mới khi quay lại tab indexedStack', (tester) async {
    final events = _Events();
    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: Row(
              children: [
                TextButton(onPressed: () => shell.goBranch(0), child: const Text('Discover tab')),
                TextButton(onPressed: () => shell.goBranch(1), child: const Text('Other tab')),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => const DiscoverScreen())],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/other',
                  builder: (_, _) => const Scaffold(body: Text('Other')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(events),
          localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
          recipesProvider.overrideWith((ref) async => const <Recipe>[]),
          ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(events.names, ['view_discover']);
    await tester.tap(find.text('Other tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover tab'));
    await tester.pumpAndSettle();
    expect(events.names, ['view_discover', 'view_discover']);
  });

  testWidgets(
    'view_discover: một lần khi vào, không lặp do rebuild/dữ liệu; quay lại tính lượt mới',
    (
      tester,
    ) async {
      final events = _Events();
      final store = InMemoryLocalStore();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DiscoverScreen()),
          GoRoute(
            path: '/other',
            builder: (_, _) => const Scaffold(body: Text('Other')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWithValue(events),
            localStoreProvider.overrideWith((ref) => store),
            recipesProvider.overrideWith((ref) async => const <Recipe>[]),
            ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
          ],
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(events.names, ['view_discover']);

      final element = tester.element(find.byType(DiscoverScreen));
      final container = ProviderScope.containerOf(element);
      await container.read(pantryItemsProvider.notifier).addToPantry('egg');
      container.invalidate(recipesProvider);
      await tester.pumpAndSettle();
      expect(events.names, ['view_discover']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWithValue(events),
            localStoreProvider.overrideWith((ref) => store),
            recipesProvider.overrideWith((ref) async => const <Recipe>[]),
            ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
          ],
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(events.names, ['view_discover']);

      router.push('/other');
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(events.names, ['view_discover', 'view_discover']);
      expect(tester.takeException(), isNull);
    },
  );

  test('recordView không phát do ViewModel tự rebuild khi nguồn dữ liệu đổi', () async {
    final events = _Events();
    final container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(events),
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const <Recipe>[]),
        ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(discoverViewModelProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    container.read(discoverViewModelProvider.notifier).recordView();
    container.read(discoverViewModelProvider.notifier).recordView();
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    container.invalidate(recipesProvider);
    await container.read(recipesProvider.future);
    expect(events.names, ['view_discover']);
  });
}
