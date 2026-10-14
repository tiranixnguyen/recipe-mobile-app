import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drink.dart';

abstract interface class DrinkRepository {
  Future<List<Drink>> list();
  Future<Drink?> getById(String id);
}

/// Dữ liệu hard-code để các feature code song song mà không cần backend.
class FakeDrinkRepository implements DrinkRepository {
  static const _drinks = [
    Drink(
      id: 'tra-sua-truyen-thong',
      name: 'Trà sữa truyền thống',
      description: 'Trà đen, sữa béo, trân châu đen.',
      emoji: '🧋',
      basePrice: 20000,
    ),
    Drink(
      id: 'tra-dao',
      name: 'Trà đào cam sả',
      description: 'Trà xanh, đào miếng, cam, sả.',
      emoji: '🍑',
      basePrice: 25000,
    ),
    Drink(
      id: 'ca-phe-muoi',
      name: 'Cà phê muối',
      description: 'Cà phê phin, kem muối.',
      emoji: '☕',
      basePrice: 22000,
    ),
    Drink(
      id: 'matcha-latte',
      name: 'Matcha latte',
      description: 'Matcha Nhật, sữa tươi.',
      emoji: '🍵',
      basePrice: 30000,
    ),
    Drink(
      id: 'sua-chua-da',
      name: 'Sữa chua đá',
      description: 'Sữa chua nhà làm, đá bào.',
      emoji: '🥛',
      basePrice: 15000,
    ),
  ];

  @override
  Future<List<Drink>> list() async => _drinks;

  @override
  Future<Drink?> getById(String id) async {
    for (final drink in _drinks) {
      if (drink.id == id) return drink;
    }
    return null;
  }
}

final drinkRepositoryProvider = Provider<DrinkRepository>((ref) => FakeDrinkRepository());

final drinksProvider = FutureProvider<List<Drink>>(
  (ref) => ref.watch(drinkRepositoryProvider).list(),
);

final drinkByIdProvider = FutureProvider.family<Drink?, String>(
  (ref, id) => ref.watch(drinkRepositoryProvider).getById(id),
);
