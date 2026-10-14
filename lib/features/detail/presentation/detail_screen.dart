import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/drink_repository.dart';
import '../../../core/format.dart';
import '../../../core/models/drink.dart';
import '../../favorites/favorites.dart';
import '../domain/pricing.dart';
import '../strings.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.drinkId});

  final String drinkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drink = ref.watch(drinkByIdProvider(drinkId));

    return drink.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _notFound(),
      data: (drink) => drink == null ? _notFound() : _DrinkDetail(drink: drink),
    );
  }

  Widget _notFound() => Scaffold(
    appBar: AppBar(),
    body: const Center(child: Text(DetailStrings.notFound)),
  );
}

class _DrinkDetail extends StatefulWidget {
  const _DrinkDetail({required this.drink});

  final Drink drink;

  @override
  State<_DrinkDetail> createState() => _DrinkDetailState();
}

class _DrinkDetailState extends State<_DrinkDetail> {
  var _size = CupSize.m;
  var _toppings = 0;

  @override
  Widget build(BuildContext context) {
    final drink = widget.drink;
    final textTheme = Theme.of(context).textTheme;
    final total = priceFor(basePrice: drink.basePrice, size: _size, toppings: _toppings);

    return Scaffold(
      appBar: AppBar(
        title: Text(drink.name),
        actions: [FavoriteButton(drinkId: drink.id)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Text(drink.emoji, style: const TextStyle(fontSize: 96))),
          const SizedBox(height: 8),
          Text(drink.description, style: textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(DetailStrings.size, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<CupSize>(
            segments: [
              for (final size in CupSize.values)
                ButtonSegment(value: size, label: Text(size.label)),
            ],
            selected: {_size},
            onSelectionChanged: (selected) => setState(() => _size = selected.single),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text(DetailStrings.toppings, style: textTheme.titleMedium)),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Bớt topping',
                onPressed: _toppings == 0 ? null : () => setState(() => _toppings--),
              ),
              Text('$_toppings', style: textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Thêm topping',
                onPressed: () => setState(() => _toppings++),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${DetailStrings.total}: ${formatVnd(total)}',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
