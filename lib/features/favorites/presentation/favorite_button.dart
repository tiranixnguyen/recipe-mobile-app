import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorites_controller.dart';
import '../strings.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.drinkId});

  final String drinkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.select((ids) => ids.contains(drinkId)));

    return IconButton(
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite ? Colors.red : null,
      tooltip: isFavorite ? FavoritesStrings.remove : FavoritesStrings.add,
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(drinkId),
    );
  }
}
