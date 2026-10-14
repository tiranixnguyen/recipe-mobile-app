import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/drink_repository.dart';
import '../../../core/widgets/drink_card.dart';
import '../../detail/detail.dart';
import '../data/favorites_controller.dart';
import '../strings.dart';
import 'favorite_button.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    // Món đã bị xoá khỏi menu thì tự ẩn.
    final drinks = ref.watch(drinksProvider).value?.where((d) => ids.contains(d.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(FavoritesStrings.title)),
      body: switch (drinks) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const Center(child: Text(FavoritesStrings.empty, textAlign: TextAlign.center)),
        _ => ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final drink in drinks)
              DrinkCard(
                drink: drink,
                trailing: FavoriteButton(drinkId: drink.id),
                onTap: () => context.push(drinkLocation(drink.id)),
              ),
          ],
        ),
      },
    );
  }
}
