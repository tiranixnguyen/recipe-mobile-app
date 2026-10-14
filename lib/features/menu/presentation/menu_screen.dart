import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/drink_repository.dart';
import '../../../core/widgets/drink_card.dart';
import '../../detail/detail.dart';
import '../../favorites/favorites.dart';
import '../strings.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drinks = ref.watch(drinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(MenuStrings.title)),
      body: drinks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(MenuStrings.error),
              TextButton(
                onPressed: () => ref.invalidate(drinksProvider),
                child: const Text(MenuStrings.retry),
              ),
            ],
          ),
        ),
        data: (drinks) => drinks.isEmpty
            ? const Center(child: Text(MenuStrings.empty))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: drinks.length,
                itemBuilder: (context, index) {
                  final drink = drinks[index];
                  return DrinkCard(
                    drink: drink,
                    trailing: FavoriteButton(drinkId: drink.id),
                    onTap: () => context.push(drinkLocation(drink.id)),
                  );
                },
              ),
      ),
    );
  }
}
