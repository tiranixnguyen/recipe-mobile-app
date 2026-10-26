import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _sessionKey = 'cook.session';

/// Giờ hiện tại của feature Nấu; test override để cố định.
final cookClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Khẩu phần chọn được khi nấu (`ServingStepper` 1–6).
const minCookServings = 1;
const maxCookServings = 6;

/// Một món trong phiên nấu, nấu cho [servings] người.
typedef CookDish = ({String recipeId, int servings});

/// Bữa trong thực đơn đang nấu (Nấu cả bữa).
typedef PlannedSlot = ({DateTime day, Meal meal});

/// Phiên nấu đang dở: một món, hoặc nhiều món khi nấu cả bữa. Lưu để "Nấu tiếp" từ Khám phá và để
/// các màn chế độ nấu không phải truyền state qua route.
@immutable
class CookSession {
  CookSession({
    required List<CookDish> dishes,
    this.current = 0,
    List<int>? positions,
    Set<int> finished = const {},
    this.planned,
    required this.startedAt,
    Map<int, DateTime> timerEnds = const {},
  }) : dishes = List.unmodifiable(dishes),
       positions = List.unmodifiable(positions ?? List.filled(dishes.length, 0)),
       finished = Set.unmodifiable(finished),
       timerEnds = Map.unmodifiable(timerEnds);

  /// Món theo thứ tự nấu.
  final List<CookDish> dishes;

  /// Chỉ số món đang nấu trong [dishes].
  final int current;

  /// Bước đang ở của từng món, cùng thứ tự [dishes].
  final List<int> positions;

  /// Chỉ số món đã nấu xong.
  final Set<int> finished;

  /// Bữa trong thực đơn khi nấu cả bữa; null khi nấu một món từ Chi tiết.
  final PlannedSlot? planned;
  final DateTime startedAt;

  /// Mốc hết giờ của đồng hồ đang chạy, theo key `cookTimerKey(món, bước)`: mở lại màn nấu thì đồng
  /// hồ chạy tiếp.
  final Map<int, DateTime> timerEnds;

  /// Nấu cả bữa (mở từ Thực đơn) thay vì một món.
  bool get isMeal => planned != null || dishes.length > 1;

  CookDish get currentDish => dishes[current];

  /// Mọi món đã xong: phiên chỉ còn chờ màn Hoàn thành, không hiện "Nấu tiếp".
  bool get isDone => finished.length >= dishes.length;

  CookSession copyWith({
    int? current,
    List<int>? positions,
    Set<int>? finished,
    Map<int, DateTime>? timerEnds,
  }) => CookSession(
    dishes: dishes,
    current: current ?? this.current,
    positions: positions ?? this.positions,
    finished: finished ?? this.finished,
    planned: planned,
    startedAt: startedAt,
    timerEnds: timerEnds ?? this.timerEnds,
  );

  Map<String, dynamic> toJson() => {
    'dishes': [
      for (final d in dishes) {'recipeId': d.recipeId, 'servings': d.servings},
    ],
    'current': current,
    'positions': positions,
    'finished': finished.toList(),
    if (planned case final p?)
      'planned': {'day': p.day.toIso8601String().substring(0, 10), 'meal': p.meal.id},
    'startedAt': startedAt.toIso8601String(),
    if (timerEnds.isNotEmpty)
      'timerEnds': {for (final e in timerEnds.entries) '${e.key}': e.value.toIso8601String()},
  };

  /// Trả null khi dữ liệu hỏng (thiếu trường, sai kiểu, chỉ số ngoài khoảng).
  static CookSession? tryParse(Object? json) {
    if (json case {
      'dishes': List<dynamic> rawDishes,
      'current': int current,
      'positions': List<dynamic> rawPositions,
      'finished': List<dynamic> rawFinished,
      'startedAt': String rawStartedAt,
    }) {
      final dishes = <CookDish>[
        for (final d in rawDishes)
          if (d case {'recipeId': String recipeId, 'servings': int servings} when servings > 0)
            (recipeId: recipeId, servings: servings),
      ];
      final positions = rawPositions.whereType<int>().toList();
      final finished = rawFinished.whereType<int>().toSet();
      final startedAt = DateTime.tryParse(rawStartedAt);
      if (dishes.isEmpty ||
          dishes.length != rawDishes.length ||
          positions.length != dishes.length ||
          positions.any((p) => p < 0) ||
          current < 0 ||
          current >= dishes.length ||
          finished.any((i) => i < 0 || i >= dishes.length) ||
          startedAt == null) {
        return null;
      }
      PlannedSlot? planned;
      if (json['planned'] case {'day': String day, 'meal': String meal}) {
        final date = DateTime.tryParse(day);
        final parsedMeal = Meal.tryParse(meal);
        if (date == null || parsedMeal == null) return null;
        planned = (day: date, meal: parsedMeal);
      }
      // Đồng hồ hỏng thì bỏ riêng đồng hồ đó.
      final timerEnds = <int, DateTime>{
        if (json['timerEnds'] case final Map<String, dynamic> raw)
          for (final MapEntry(:key, :value) in raw.entries)
            if ((int.tryParse(key), value is String ? DateTime.tryParse(value) : null) case (
              final int k,
              final DateTime at,
            ))
              k: at,
      };
      return CookSession(
        dishes: dishes,
        current: current,
        positions: positions,
        finished: finished,
        planned: planned,
        startedAt: startedAt,
        timerEnds: timerEnds,
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CookSession &&
      listEquals(other.dishes, dishes) &&
      other.current == current &&
      listEquals(other.positions, positions) &&
      setEquals(other.finished, finished) &&
      other.planned == planned &&
      other.startedAt == startedAt &&
      mapEquals(other.timerEnds, timerEnds);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(dishes),
    current,
    Object.hashAll(positions),
    Object.hashAllUnordered(finished),
    planned,
    startedAt,
    Object.hashAllUnordered(timerEnds.entries.map((e) => Object.hash(e.key, e.value))),
  );

  @override
  String toString() => 'CookSession($dishes, current: $current, $positions, done: $finished)';
}

/// Phiên nấu đang dở; null khi không nấu gì. Bắt đầu phiên mới thì thay phiên cũ.
class CookSessionController extends Notifier<CookSession?> {
  /// Phiên bắt đầu quá lâu thì coi như đã bỏ, không mời "Nấu tiếp" nữa.
  static const staleAfter = Duration(hours: 12);

  @override
  CookSession? build() {
    final raw = ref.watch(localStoreProvider).readString(_sessionKey);
    if (raw == null) return null;
    try {
      final session = CookSession.tryParse(jsonDecode(raw));
      if (session == null) return null;
      final age = ref.read(cookClockProvider)().difference(session.startedAt);
      return age > staleAfter ? null : session;
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return null;
    }
  }

  /// Bắt đầu nấu một món [recipeId] cho [servings] người.
  Future<void> startRecipe(String recipeId, int servings) => _save(
    CookSession(
      dishes: [(recipeId: recipeId, servings: servings)],
      startedAt: ref.read(cookClockProvider)(),
    ),
  );

  /// Bắt đầu nấu cả bữa [planned]: [dishes] theo thứ tự nấu.
  Future<void> startMeal(List<CookDish> dishes, PlannedSlot planned) => _save(
    CookSession(
      dishes: dishes,
      planned: (
        day: DateTime(planned.day.year, planned.day.month, planned.day.day),
        meal: planned.meal,
      ),
      startedAt: ref.read(cookClockProvider)(),
    ),
  );

  /// Sang bước [step] của món thứ [dish] (cũng là món đang nấu).
  Future<void> goTo(int dish, int step) async {
    final session = state;
    if (session == null || dish < 0 || dish >= session.dishes.length || step < 0) return;
    await _save(
      session.copyWith(current: dish, positions: [...session.positions]..[dish] = step),
    );
  }

  /// Đánh dấu món thứ [dish] đã nấu xong.
  Future<void> finishDish(int dish) async {
    final session = state;
    if (session == null || dish < 0 || dish >= session.dishes.length) return;
    await _save(session.copyWith(finished: {...session.finished, dish}));
  }

  /// Lưu mốc hết giờ của đồng hồ [key]; [endAt] null khi đồng hồ dừng hoặc đã hết giờ.
  Future<void> setTimerEnd(int key, DateTime? endAt) async {
    final session = state;
    if (session == null || session.timerEnds[key] == endAt) return;
    final timerEnds = {...session.timerEnds};
    endAt == null ? timerEnds.remove(key) : timerEnds[key] = endAt;
    await _save(session.copyWith(timerEnds: timerEnds));
  }

  Future<void> clear() async {
    state = null;
    await ref.read(localStoreProvider).remove(_sessionKey);
  }

  Future<void> _save(CookSession session) async {
    state = session;
    await ref.read(localStoreProvider).writeString(_sessionKey, jsonEncode(session.toJson()));
  }
}

/// Đọc: `ref.watch(cookSessionProvider)`. Chỉ dùng trong feature Nấu; Khám phá dùng
/// `ResumeCookingBanner`.
final cookSessionProvider = NotifierProvider<CookSessionController, CookSession?>(
  CookSessionController.new,
);
