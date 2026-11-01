import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/history.dart';

const _historyKey = 'cook.history';

/// Đánh giá sau khi nấu xong.
enum CookRating {
  good('good', 'Ngon'),
  ok('ok', 'Tạm'),
  bad('bad', 'Chê');

  const CookRating(this.id, this.label);

  final String id;
  final String label;

  static CookRating? tryParse(Object? value) {
    for (final rating in values) {
      if (rating.id == value) return rating;
    }
    return null;
  }
}

/// Một món trong một lần nấu.
@immutable
class CookedDish {
  CookedDish({required this.recipeId, this.servings = 1, this.rating, String note = ''})
    : note = trimCookNote(note);

  final String recipeId;
  final int servings;

  /// Null khi bỏ qua bước chấm.
  final CookRating? rating;

  /// Ghi chú riêng cho món, tối đa [maxCookNote] ký tự.
  final String note;

  /// [rating] null bỏ qua; truyền hàm trả null để xoá đánh giá (bấm lại nút đang chọn).
  CookedDish copyWith({CookRating? Function()? rating, String? note}) => CookedDish(
    recipeId: recipeId,
    servings: servings,
    rating: rating != null ? rating() : this.rating,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'recipeId': recipeId,
    'servings': servings,
    if (rating case final r?) 'rating': r.id,
    if (note.isNotEmpty) 'note': note,
  };

  static CookedDish? tryParse(Object? json) {
    if (json case {'recipeId': String recipeId} when recipeId.isNotEmpty) {
      return CookedDish(
        recipeId: recipeId,
        servings: switch (json['servings']) {
          final int s when s > 0 => s,
          _ => 1,
        },
        rating: CookRating.tryParse(json['rating']),
        note: switch (json['note']) {
          final String note => note,
          _ => '',
        },
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CookedDish &&
      other.recipeId == recipeId &&
      other.servings == servings &&
      other.rating == rating &&
      other.note == note;

  @override
  int get hashCode => Object.hash(recipeId, servings, rating, note);

  @override
  String toString() => 'CookedDish($recipeId, ${rating?.id}, note: ${note.length})';
}

/// Một lần nấu đã xong: một món (từ Chi tiết) hoặc cả bữa (từ Thực đơn).
@immutable
class CookHistoryEntry {
  CookHistoryEntry({
    required this.id,
    required this.cookedAt,
    required this.meal,
    required this.isMeal,
    required List<CookedDish> dishes,
    this.minutes = 0,
    String mealNote = '',
  }) : assert(dishes.isNotEmpty),
       dishes = List.unmodifiable(dishes),
       mealNote = trimCookNote(mealNote);

  final String id;
  final DateTime cookedAt;

  /// Bữa trong Thực đơn khi nấu cả bữa; nấu một món thì là bữa theo giờ nấu xong.
  final Meal meal;

  /// Nấu cả bữa ("Nấu lại bữa này") thay vì một món.
  final bool isMeal;
  final List<CookedDish> dishes;

  /// Tổng thời gian ước tính của các món; 0 khi không rõ (dữ liệu cũ).
  final int minutes;

  /// Ghi chú cho cả lần nấu ("Ghi chú cho bữa", một món thì là "Ghi chú").
  final String mealNote;

  int get servings => dishes.first.servings;

  /// Món đầu — tiện cho lần nấu một món; cả bữa thì duyệt [dishes].
  String get recipeId => dishes.first.recipeId;
  CookRating? get rating => dishes.first.rating;

  bool get hasNote => mealNote.isNotEmpty || dishes.any((d) => d.note.isNotEmpty);

  CookHistoryEntry copyWith({List<CookedDish>? dishes, String? mealNote}) => CookHistoryEntry(
    id: id,
    cookedAt: cookedAt,
    meal: meal,
    isMeal: isMeal,
    dishes: dishes ?? this.dishes,
    minutes: minutes,
    mealNote: mealNote ?? this.mealNote,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'cookedAt': cookedAt.toIso8601String(),
    'meal': meal.id,
    'isMeal': isMeal,
    'dishes': [for (final d in dishes) d.toJson()],
    if (minutes > 0) 'minutes': minutes,
    if (mealNote.isNotEmpty) 'mealNote': mealNote,
  };

  /// Đọc một mục của `cook.history`; null khi hỏng. Mục kiểu cũ (`{recipeId, cookedAt, rating}`,
  /// mỗi món một mục) thành một lần nấu một món, id [legacyId].
  static CookHistoryEntry? tryParse(Object? json, {required String legacyId}) {
    if (json case {'recipeId': String recipeId, 'cookedAt': String rawAt}
        when !json.containsKey('dishes')) {
      final at = DateTime.tryParse(rawAt);
      final dish = CookedDish.tryParse({'recipeId': recipeId, 'rating': json['rating']});
      if (at == null || dish == null) return null;
      return CookHistoryEntry(
        id: legacyId,
        cookedAt: at,
        meal: mealAt(at),
        isMeal: false,
        dishes: [dish],
      );
    }
    if (json case {'id': String id, 'cookedAt': String rawAt, 'dishes': List<dynamic> rawDishes}
        when id.isNotEmpty) {
      final at = DateTime.tryParse(rawAt);
      final dishes = rawDishes.map(CookedDish.tryParse).nonNulls.toList();
      if (at == null || dishes.isEmpty || dishes.length != rawDishes.length) return null;
      return CookHistoryEntry(
        id: id,
        cookedAt: at,
        meal: switch (json['meal']) {
          final String m => Meal.tryParse(m) ?? mealAt(at),
          _ => mealAt(at),
        },
        isMeal: json['isMeal'] == true,
        dishes: dishes,
        minutes: switch (json['minutes']) {
          final int m when m > 0 => m,
          _ => 0,
        },
        mealNote: switch (json['mealNote']) {
          final String note => note,
          _ => '',
        },
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CookHistoryEntry &&
      other.id == id &&
      other.cookedAt == cookedAt &&
      other.meal == meal &&
      other.isMeal == isMeal &&
      listEquals(other.dishes, dishes) &&
      other.minutes == minutes &&
      other.mealNote == mealNote;

  @override
  int get hashCode =>
      Object.hash(id, cookedAt, meal, isMeal, Object.hashAll(dishes), minutes, mealNote);

  @override
  String toString() => 'CookHistoryEntry($id, $cookedAt, ${meal.id}, $dishes)';
}

/// Lịch sử nấu (LocalStore `cook.history`), cũ trước mới sau.
class CookHistoryController extends Notifier<List<CookHistoryEntry>> {
  @override
  List<CookHistoryEntry> build() {
    final raw = ref.watch(localStoreProvider).readString(_historyKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      // Mục hỏng thì bỏ riêng mục đó; lần ghi sau sẽ không còn nó.
      return List.unmodifiable([
        for (final (i, item) in list.indexed)
          ?CookHistoryEntry.tryParse(item, legacyId: 'legacy-$i'),
      ]);
    } on Object {
      return const [];
    }
  }

  /// Ghi lần nấu mới (một món hoặc cả bữa); id đã có thì bỏ qua.
  Future<void> recordEntry(CookHistoryEntry entry) async {
    if (state.any((e) => e.id == entry.id)) return;
    await _save([...state, entry]);
  }

  /// Ghi nhanh một món đơn, không ghi chú; [recordEntry] cho lần nấu đầy đủ (PantryUpdate).
  Future<void> record(String recipeId, {CookRating? rating, DateTime? at}) {
    final now = at ?? ref.read(cookClockProvider)();
    return recordEntry(
      CookHistoryEntry(
        id: uniqueHistoryId(recipeId, now, state.map((e) => e.id)),
        cookedAt: now,
        meal: mealAt(now),
        isMeal: false,
        dishes: [CookedDish(recipeId: recipeId, rating: rating)],
      ),
    );
  }

  /// Sửa đánh giá món thứ [index] của lần nấu [entryId]; null xoá đánh giá.
  Future<void> updateDishRating(String entryId, int index, CookRating? rating) => _update(entryId, (
    e,
  ) {
    if (index < 0 || index >= e.dishes.length) return e;
    return e.copyWith(
      dishes: [
        for (final (i, d) in e.dishes.indexed) i == index ? d.copyWith(rating: () => rating) : d,
      ],
    );
  });

  /// Sửa ghi chú món thứ [index] của lần nấu [entryId].
  Future<void> updateDishNote(String entryId, int index, String note) => _update(entryId, (e) {
    if (index < 0 || index >= e.dishes.length) return e;
    return e.copyWith(
      dishes: [
        for (final (i, d) in e.dishes.indexed) i == index ? d.copyWith(note: note) : d,
      ],
    );
  });

  Future<void> updateMealNote(String entryId, String note) =>
      _update(entryId, (e) => e.copyWith(mealNote: note));

  /// Xoá lần nấu [entryId]; trả về mục đã xoá để Hoàn tác, null khi không có.
  Future<CookHistoryEntry?> delete(String entryId) async {
    final entry = state.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return null;
    await _save([
      for (final e in state)
        if (e.id != entryId) e,
    ]);
    return entry;
  }

  /// Hoàn tác [delete]: chèn lại đúng chỗ theo giờ nấu.
  Future<void> restore(CookHistoryEntry entry) async {
    if (state.any((e) => e.id == entry.id)) return;
    await _save([...state, entry]..sort((a, b) => a.cookedAt.compareTo(b.cookedAt)));
  }

  Future<void> _update(String entryId, CookHistoryEntry Function(CookHistoryEntry) change) async {
    var changed = false;
    final next = [
      for (final e in state)
        if (e.id == entryId)
          () {
            final updated = change(e);
            changed = updated != e;
            return updated;
          }()
        else
          e,
    ];
    if (changed) await _save(next);
  }

  Future<void> _save(List<CookHistoryEntry> entries) async {
    state = List.unmodifiable(entries);
    await ref
        .read(localStoreProvider)
        .writeString(_historyKey, jsonEncode([for (final e in state) e.toJson()]));
  }
}

/// Đọc: `ref.watch(cookHistoryProvider)`; mỗi mục một lần nấu, duyệt `entry.dishes` để có từng
/// món kèm đánh giá.
final cookHistoryProvider = NotifierProvider<CookHistoryController, List<CookHistoryEntry>>(
  CookHistoryController.new,
);
