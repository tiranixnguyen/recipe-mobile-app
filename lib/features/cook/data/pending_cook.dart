import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';

/// Dữ liệu tạm từ màn Xong → PantryUpdate (in-memory, không persist).
@immutable
class PendingCookData {
  const PendingCookData({
    required this.dishes,
    required this.isMeal,
    required this.meal,
    this.minutes = 0,
    this.mealNote = '',
    this.planned,
    required this.usedItems,
  });

  final List<CookedDish> dishes;
  final bool isMeal;
  final Meal meal;
  final int minutes;
  final String mealNote;

  /// Bữa trong thực đơn khi nấu cả bữa (để đánh dấu đã nấu sau PantryUpdate).
  final PlannedSlot? planned;

  /// Đồ trong tủ vừa dùng, để PantryUpdate hiển thị.
  final List<UsedItem> usedItems;
}

/// Provider in-memory: giữ qua route changes, cleared thủ công sau PantryUpdate.
class PendingCookNotifier extends Notifier<PendingCookData?> {
  @override
  PendingCookData? build() => null;

  void set(PendingCookData? data) {
    state = data;
  }
}

final pendingCookProvider = NotifierProvider<PendingCookNotifier, PendingCookData?>(
  PendingCookNotifier.new,
);
