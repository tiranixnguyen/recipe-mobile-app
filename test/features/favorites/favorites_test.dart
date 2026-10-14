import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/favorites/data/favorites_controller.dart';
import 'package:recipe_mobile_app/features/favorites/presentation/favorite_button.dart';
import 'package:recipe_mobile_app/features/favorites/presentation/favorites_screen.dart';
import 'package:recipe_mobile_app/features/favorites/strings.dart';

void main() {
  test('toggle lưu vào LocalStore và đọc lại được khi mở app lần sau', () async {
    final store = InMemoryLocalStore();
    final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(favoritesProvider.notifier).toggle('tra-dao');
    expect(container.read(favoritesProvider), {'tra-dao'});

    final reopened = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(favoritesProvider), {'tra-dao'});

    await reopened.read(favoritesProvider.notifier).toggle('tra-dao');
    expect(store.readList('favorites.ids'), isEmpty);
  });

  testWidgets('bấm tim thì món xuất hiện trong màn Yêu thích', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Column(
            children: [
              FavoriteButton(drinkId: 'ca-phe-muoi'),
              Expanded(child: FavoritesScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FavoritesStrings.empty), findsOneWidget);

    await tester.tap(find.byTooltip(FavoritesStrings.add));
    await tester.pumpAndSettle();

    expect(find.text('Cà phê muối'), findsOneWidget);
  });
}
