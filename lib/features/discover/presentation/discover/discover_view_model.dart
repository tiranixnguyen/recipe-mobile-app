import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

@immutable
class DiscoverState {
  const DiscoverState({required this.cookable, required this.quick});

  /// Món đủ đồ trước, rồi món thiếu 1–2 thứ; tối đa [DiscoverViewModel.cookableLimit].
  final List<NearMatch> cookable;

  /// Món nấu trong [DiscoverViewModel.quickMinutes] phút, nhanh nhất trước; tối đa
  /// [DiscoverViewModel.quickLimit].
  final List<Recipe> quick;
}

class DiscoverViewModel extends Notifier<AsyncValue<DiscoverState>> {
  static const cookableLimit = 6;
  static const quickMinutes = 20;
  static const quickLimit = 3;

  bool _viewTracked = false;

  /// Gọi khi màn thực sự xuất hiện; build/rebuild và cập nhật dữ liệu không phải lượt xem mới.
  void recordView() {
    if (_viewTracked) return;
    _viewTracked = true;
    ref.read(analyticsProvider).track('view_discover');
  }

  void endView() => _viewTracked = false;

  @override
  AsyncValue<DiscoverState> build() {
    final recipes = ref.watch(recipesProvider);
    final matches = ref.watch(pantryMatchesProvider);
    return switch ((recipes, matches)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final matches)) => AsyncData(
        DiscoverState(
          cookable: [
            for (final recipe in matches.ready)
              (recipe: recipe, availability: const Availability()),
            ...matches.near,
          ].take(cookableLimit).toList(growable: false),
          quick: _quick(recipes),
        ),
      ),
      _ => const AsyncLoading(),
    };
  }

  static List<Recipe> _quick(List<Recipe> recipes) {
    final quick = recipes.where((r) => r.minutes <= quickMinutes).toList();
    // List.sort không ổn định, nên so thêm vị trí ban đầu để cùng phút thì giữ thứ tự dữ liệu.
    final order = {for (final (i, r) in quick.indexed) r.id: i};
    quick.sort((a, b) {
      final byMinutes = a.minutes.compareTo(b.minutes);
      return byMinutes != 0 ? byMinutes : order[a.id]!.compareTo(order[b.id]!);
    });
    return quick.take(quickLimit).toList(growable: false);
  }
}

final discoverViewModelProvider =
    NotifierProvider.autoDispose<DiscoverViewModel, AsyncValue<DiscoverState>>(
      DiscoverViewModel.new,
    );
