import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';

const _historyKey = 'cook.history';

/// Đánh giá sau khi nấu xong.
enum CookRating {
  good('good', 'Ngon'),
  ok('ok', 'Tạm'),
  bad('bad', 'Chê');

  const CookRating(this.id, this.label);

  final String id;
  final String label;

  static CookRating? tryParse(String? value) {
    for (final rating in values) {
      if (rating.id == value) return rating;
    }
    return null;
  }
}

/// Một món trong lần nấu.
@immutable
class CookSessionDish {
  const CookSessionDish({required this.recipeId, this.rating, this.note = ''});

  final String recipeId;
  final CookRating? rating;

  /// Ghi chú cá nhân, tối đa 300 ký tự.
  final String note;

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    if (rating != null) 'rating': rating!.id,
    'note': note,
  };

  static CookSessionDish? tryParse(Object? json) {
    if (json case {'recipeId': String recipeId}) {
      final rating = json['rating'];
      final note = json['note'];
      return CookSessionDish(
        recipeId: recipeId,
        rating: rating is String ? CookRating.tryParse(rating) : null,
        note: note is String ? note : '',
      );
    }
    return null;
  }

  CookSessionDish copyWith({CookRating? Function()? rating, String? note}) => CookSessionDish(
    recipeId: recipeId,
    rating: rating != null ? rating() : this.rating,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is CookSessionDish &&
      other.recipeId == recipeId &&
      other.rating == rating &&
      other.note == note;

  @override
  int get hashCode => Object.hash(recipeId, rating, note);
}

/// Một lần nấu (một món hoặc cả bữa), lưu vào lịch sử.
@immutable
class CookHistoryEntry {
  const CookHistoryEntry({
    required this.id,
    required this.cookedAt,
    this.meal,
    required this.isMeal,
    required this.servings,
    this.minutes,
    required this.dishes,
    this.mealNote = '',
  });

  final String id;
  final DateTime cookedAt;

  /// Bữa khi nấu cả bữa; null khi nấu một món.
  final Meal? meal;
  final bool isMeal;
  final int servings;
  final int? minutes;
  final List<CookSessionDish> dishes;
  final String mealNote;

  /// Đánh giá món đầu tiên — dùng cho app_review.dart (backward compat với CookRecord cũ).
  CookRating? get rating => dishes.firstOrNull?.rating;

  /// recipeId món đầu tiên — backward compat.
  String get recipeId => dishes.first.recipeId;

  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    'cookedAt': cookedAt.toIso8601String(),
    if (meal != null) 'meal': meal!.id,
    'isMeal': isMeal,
    'servings': servings,
    if (minutes != null) 'minutes': minutes,
    'dishes': [for (final d in dishes) d.toJson()],
    'mealNote': mealNote,
  };

  static CookHistoryEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    // Format cũ v1: CookRecord có recipeId ở root, không có version.
    if (!json.containsKey('version')) {
      if (json case {'recipeId': String recipeId, 'cookedAt': String cookedAt}) {
        final at = DateTime.tryParse(cookedAt);
        if (at == null) return null;
        final ratingVal = json['rating'];
        return CookHistoryEntry(
          id: '${recipeId}_$cookedAt',
          cookedAt: at,
          isMeal: false,
          servings: 1,
          dishes: List.unmodifiable([
            CookSessionDish(
              recipeId: recipeId,
              rating: ratingVal is String ? CookRating.tryParse(ratingVal) : null,
            ),
          ]),
        );
      }
      return null;
    }
    // Format v2.
    if (json case {
      'version': 2,
      'id': String id,
      'cookedAt': String cookedAt,
      'isMeal': bool isMeal,
      'servings': int servings,
      'dishes': List<dynamic> dishList,
    }) {
      final at = DateTime.tryParse(cookedAt);
      if (at == null) return null;
      final dishes = dishList.map(CookSessionDish.tryParse).nonNulls.toList();
      if (dishes.isEmpty) return null;
      final mealStr = json['meal'];
      final mealNote = json['mealNote'];
      return CookHistoryEntry(
        id: id,
        cookedAt: at,
        meal: mealStr is String ? Meal.tryParse(mealStr) : null,
        isMeal: isMeal,
        servings: servings,
        minutes: json['minutes'] is int ? json['minutes'] as int : null,
        dishes: List.unmodifiable(dishes),
        mealNote: mealNote is String ? mealNote : '',
      );
    }
    return null;
  }

  CookHistoryEntry copyWith({
    List<CookSessionDish>? dishes,
    String? mealNote,
  }) => CookHistoryEntry(
    id: id,
    cookedAt: cookedAt,
    meal: meal,
    isMeal: isMeal,
    servings: servings,
    minutes: minutes,
    dishes: dishes ?? this.dishes,
    mealNote: mealNote ?? this.mealNote,
  );

  @override
  bool operator ==(Object other) =>
      other is CookHistoryEntry &&
      other.id == id &&
      other.cookedAt == cookedAt &&
      other.isMeal == isMeal;

  @override
  int get hashCode => Object.hash(id, cookedAt, isMeal);

  @override
  String toString() => 'CookHistoryEntry($id, $cookedAt, dishes: ${dishes.length})';
}

/// Alias backward compat: app_review.dart dùng CookRecord, giờ trỏ tới CookHistoryEntry.
typedef CookRecord = CookHistoryEntry;

/// Lịch sử nấu, cũ trước mới sau.
class CookHistoryController extends Notifier<List<CookHistoryEntry>> {
  @override
  List<CookHistoryEntry> build() {
    final raw = ref.watch(localStoreProvider).readString(_historyKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return List.unmodifiable(list.map(CookHistoryEntry.tryParse).nonNulls);
    } on Object {
      return const [];
    }
  }

  Future<void> _save() async {
    await ref
        .read(localStoreProvider)
        .writeString(_historyKey, jsonEncode([for (final e in state) e.toJson()]));
  }

  /// Ghi một lần nấu mới vào cuối danh sách.
  Future<void> recordEntry(CookHistoryEntry entry) async {
    state = List.unmodifiable([...state, entry]);
    await _save();
  }

  /// Backward compat: ghi một món đơn.
  Future<void> record(String recipeId, {CookRating? rating, DateTime? at}) async {
    final now = at ?? ref.read(cookClockProvider)();
    await recordEntry(
      CookHistoryEntry(
        id: '${recipeId}_${now.millisecondsSinceEpoch}',
        cookedAt: now,
        isMeal: false,
        servings: 1,
        dishes: List.unmodifiable([CookSessionDish(recipeId: recipeId, rating: rating)]),
      ),
    );
  }

  Future<void> updateDishRating(String entryId, int dishIdx, CookRating? rating) async {
    state = List.unmodifiable([
      for (final e in state)
        if (e.id == entryId && dishIdx < e.dishes.length)
          e.copyWith(
            dishes: List.unmodifiable([
              for (final (i, d) in e.dishes.indexed)
                if (i == dishIdx) d.copyWith(rating: () => rating) else d,
            ]),
          )
        else
          e,
    ]);
    await _save();
  }

  Future<void> updateDishNote(String entryId, int dishIdx, String note) async {
    final trimmed = note.length > 300 ? note.substring(0, 300) : note;
    state = List.unmodifiable([
      for (final e in state)
        if (e.id == entryId && dishIdx < e.dishes.length)
          e.copyWith(
            dishes: List.unmodifiable([
              for (final (i, d) in e.dishes.indexed)
                if (i == dishIdx) d.copyWith(note: trimmed) else d,
            ]),
          )
        else
          e,
    ]);
    await _save();
  }

  Future<void> updateMealNote(String entryId, String note) async {
    final trimmed = note.length > 300 ? note.substring(0, 300) : note;
    state = List.unmodifiable([
      for (final e in state)
        if (e.id == entryId) e.copyWith(mealNote: trimmed) else e,
    ]);
    await _save();
  }

  /// Xoá lần nấu [entryId]; trả về entry đã xoá để hoàn tác, null nếu không tìm thấy.
  Future<CookHistoryEntry?> delete(String entryId) async {
    final entry = state.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return null;
    state = List.unmodifiable(state.where((e) => e.id != entryId));
    await _save();
    return entry;
  }

  /// Khôi phục entry đã xoá; chèn đúng vị trí theo [cookedAt].
  Future<void> restore(CookHistoryEntry entry) async {
    final list = [...state, entry]..sort((a, b) => a.cookedAt.compareTo(b.cookedAt));
    state = List.unmodifiable(list);
    await _save();
  }
}

final cookHistoryProvider = NotifierProvider<CookHistoryController, List<CookHistoryEntry>>(
  CookHistoryController.new,
);
