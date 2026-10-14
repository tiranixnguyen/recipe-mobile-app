import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';

const _storeKey = 'favorites.ids';

/// Tập id các món đã yêu thích, lưu trên máy.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(localStoreProvider).readList(_storeKey).toSet();

  Future<void> toggle(String drinkId) async {
    final next = {...state};
    if (!next.remove(drinkId)) next.add(drinkId);
    state = next;
    await ref.read(localStoreProvider).writeList(_storeKey, next.toList());
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);
