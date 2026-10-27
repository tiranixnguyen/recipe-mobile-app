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
    this.inPrep = false,
    Set<String> prepDone = const {},
    this.inNotes = false,
    this.done = false,
  }) : dishes = List.unmodifiable(dishes),
       positions = List.unmodifiable(positions ?? List.filled(dishes.length, 0)),
       finished = Set.unmodifiable(finished),
       timerEnds = Map.unmodifiable(timerEnds),
       prepDone = Set.unmodifiable(prepDone);

  /// Món theo thứ tự nấu.
  final List<CookDish> dishes;

  /// Chỉ số món đang nấu trong [dishes].
  final int current;

  /// Bước đang ở của từng món, cùng thứ tự [dishes]. Nấu cả bữa: chỉ số trong bước đứng bếp
  /// (`cookSteps`), vì bước sơ chế đã gom lên chặng Sơ chế.
  final List<int> positions;

  /// Chỉ số món đã nấu xong.
  final Set<int> finished;

  /// Bữa trong thực đơn khi nấu cả bữa; null khi nấu một món từ Chi tiết.
  final PlannedSlot? planned;
  final DateTime startedAt;

  /// Mốc hết giờ của đồng hồ đang chạy, theo key `cookTimerKey(món, bước)`: mở lại màn nấu thì đồng
  /// hồ chạy tiếp.
  final Map<int, DateTime> timerEnds;

  /// Nấu cả bữa đang ở chặng "Sơ chế cả bữa" (trước món đầu).
  final bool inPrep;

  /// Việc sơ chế đã tick, theo `MealPrepTask.id` của việc lá.
  final Set<String> prepDone;

  /// Đang ở trang "Lưu ý cách dùng" sau bước cuối (một món) hoặc chặng Lưu ý cuối bữa.
  final bool inNotes;

  /// Đã bấm "Xong" / "Xong cả bữa": phiên chỉ còn chờ màn Hoàn thành.
  final bool done;

  /// Nấu cả bữa (mở từ Thực đơn) thay vì một món.
  bool get isMeal => planned != null || dishes.length > 1;

  CookDish get currentDish => dishes[current];

  /// Đã bấm Xong / Xong cả bữa: không hiện "Nấu tiếp". Xong hết món mà chưa bấm (đang ở chặng Lưu
  /// ý, hay quay lại xem một món) thì vẫn mời nấu tiếp.
  bool get isDone => done;

  CookSession copyWith({
    int? current,
    List<int>? positions,
    Set<int>? finished,
    Map<int, DateTime>? timerEnds,
    bool? inPrep,
    Set<String>? prepDone,
    bool? inNotes,
    bool? done,
  }) => CookSession(
    dishes: dishes,
    current: current ?? this.current,
    positions: positions ?? this.positions,
    finished: finished ?? this.finished,
    planned: planned,
    startedAt: startedAt,
    timerEnds: timerEnds ?? this.timerEnds,
    inPrep: inPrep ?? this.inPrep,
    prepDone: prepDone ?? this.prepDone,
    inNotes: inNotes ?? this.inNotes,
    done: done ?? this.done,
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
    if (inPrep) 'inPrep': true,
    if (prepDone.isNotEmpty) 'prepDone': prepDone.toList(),
    if (inNotes) 'inNotes': true,
    'done': done,
  };

  /// Trả null khi dữ liệu hỏng (thiếu trường, sai kiểu, chỉ số ngoài khoảng). `inPrep`, `prepDone`,
  /// `inNotes`, `done` tuỳ chọn: phiên lưu trước khi có chặng Sơ chế, Lưu ý vẫn đọc được; phiên
  /// cũ không có `done` thì xong khi mọi món đã xong, như trước.
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
        inPrep: json['inPrep'] == true,
        prepDone: {
          if (json['prepDone'] case final List<dynamic> raw) ...raw.whereType<String>(),
        },
        inNotes: json['inNotes'] == true,
        done: switch (json['done']) {
          final bool done => done,
          _ => finished.length >= dishes.length,
        },
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
      mapEquals(other.timerEnds, timerEnds) &&
      other.inPrep == inPrep &&
      setEquals(other.prepDone, prepDone) &&
      other.inNotes == inNotes &&
      other.done == done;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(dishes),
    current,
    Object.hashAll(positions),
    Object.hashAllUnordered(finished),
    planned,
    startedAt,
    Object.hashAllUnordered(timerEnds.entries.map((e) => Object.hash(e.key, e.value))),
    inPrep,
    Object.hashAllUnordered(prepDone),
    inNotes,
    done,
  );

  @override
  String toString() =>
      'CookSession($dishes, current: $current, $positions, done: $finished'
      '${inPrep ? ', inPrep' : ''}${inNotes ? ', inNotes' : ''}${done ? ', done' : ''})';
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

  /// Bắt đầu nấu cả bữa [planned]: [dishes] theo thứ tự nấu. [prep]: bữa có việc sơ chế thì bắt
  /// đầu ở chặng Sơ chế.
  Future<void> startMeal(List<CookDish> dishes, PlannedSlot planned, {bool prep = false}) => _save(
    CookSession(
      dishes: dishes,
      planned: (
        day: DateTime(planned.day.year, planned.day.month, planned.day.day),
        meal: planned.meal,
      ),
      startedAt: ref.read(cookClockProvider)(),
      inPrep: prep,
    ),
  );

  /// Sang bước [step] của món thứ [dish] (cũng là món đang nấu); rời chặng Sơ chế, Lưu ý nếu đang
  /// ở đó.
  Future<void> goTo(int dish, int step) async {
    final session = state;
    if (session == null || dish < 0 || dish >= session.dishes.length || step < 0) return;
    await _save(
      session.copyWith(
        current: dish,
        positions: [...session.positions]..[dish] = step,
        inPrep: false,
        inNotes: false,
      ),
    );
  }

  /// Về chặng "Sơ chế cả bữa" (tab Sơ chế, "Bước trước" ở bước đầu món 1).
  Future<void> showPrep() async {
    final session = state;
    if (session == null || session.inPrep) return;
    await _save(session.copyWith(inPrep: true, inNotes: false));
  }

  /// Sang trang "Lưu ý cách dùng" (sau bước cuối một món, chặng cuối bữa).
  Future<void> showNotes() async {
    final session = state;
    if (session == null || session.inNotes) return;
    await _save(session.copyWith(inNotes: true, inPrep: false));
  }

  /// Tick ([done] true) hoặc bỏ tick các việc sơ chế [ids].
  Future<void> setPrepDone(Iterable<String> ids, {required bool done}) async {
    final session = state;
    if (session == null) return;
    final next = {...session.prepDone};
    done ? next.addAll(ids) : next.removeAll(ids);
    if (setEquals(next, session.prepDone)) return;
    await _save(session.copyWith(prepDone: next));
  }

  /// Đánh dấu món thứ [dish] đã nấu xong.
  Future<void> finishDish(int dish) async {
    final session = state;
    if (session == null || dish < 0 || dish >= session.dishes.length) return;
    await _save(session.copyWith(finished: {...session.finished, dish}));
  }

  /// "Xong" / "Xong cả bữa": mọi món xong, phiên chờ màn Hoàn thành (không còn "Nấu tiếp").
  Future<void> complete() async {
    final session = state;
    if (session == null || session.done) return;
    await _save(
      session.copyWith(
        finished: {for (var i = 0; i < session.dishes.length; i++) i},
        inNotes: false,
        done: true,
      ),
    );
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
