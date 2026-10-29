import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/domain/availability.dart';
import 'package:recipe_mobile_app/features/pantry/domain/suggest.dart';

/// Quy mô bữa ở màn Gợi ý cho mình (prototype `TodayPrefs`).
enum MealScale {
  /// "1 món gọn lẹ": một món `single` (thiếu thì một món mặn).
  one('1 món gọn lẹ'),

  /// "Cơm nhà 2 món": món mặn + canh hoặc rau/món thêm.
  two('cơm nhà 2 món'),

  /// "Mâm cơm (3+ món)": món mặn + canh + rau/món thêm.
  tray('mâm cơm');

  const MealScale(this.phrase);

  /// Cụm từ viết thường để ghép vào câu "Chưa đủ món cho mâm cơm…".
  final String phrase;
}

/// Tiêu chí gợi ý một bữa (prototype `TodayPrefs`). F1 lưu và quy "Theo thời tiết" ra [feel] trước
/// khi gọi.
@immutable
class MealPrefs {
  const MealPrefs({
    this.scale = MealScale.two,
    this.maxMinutes = 30,
    this.feel,
    this.fridge = true,
    this.tags = const {},
  });

  final MealScale scale;

  /// Tổng phút nấu cả bữa tối đa; null = Thong thả (không giới hạn).
  final int? maxMinutes;

  /// Giải nhiệt / Ấm bụng; null = không quan tâm.
  final DishFeel? feel;

  /// "Ưu tiên đồ trong tủ": xếp bữa dùng nhiều đồ đang có lên trước.
  final bool fridge;

  /// Mỗi tag phải có ở ít nhất một món của bữa.
  final Set<RecipeTag> tags;

  MealPrefs _copyWith({
    MealScale? scale,
    int? Function()? maxMinutes,
    DishFeel? Function()? feel,
    Set<RecipeTag>? tags,
  }) => MealPrefs(
    scale: scale ?? this.scale,
    maxMinutes: maxMinutes == null ? this.maxMinutes : maxMinutes(),
    feel: feel == null ? this.feel : feel(),
    fridge: fridge,
    tags: tags ?? this.tags,
  );

  @override
  bool operator ==(Object other) =>
      other is MealPrefs &&
      other.scale == scale &&
      other.maxMinutes == maxMinutes &&
      other.feel == feel &&
      other.fridge == fridge &&
      setEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(scale, maxMinutes, feel, fridge, Object.hashAllUnordered(tags));
}

/// Một bữa gợi ý: các món theo quy mô, tổng thời gian, thiếu gì và lý do.
@immutable
class MealSuggestion {
  const MealSuggestion({
    required this.dishes,
    required this.scale,
    required this.totalMinutes,
    required this.availability,
    required this.reasons,
    this.relaxedNote,
  });

  /// Món theo thứ tự vai: món mặn (hoặc món một mình) trước, rồi canh, rau.
  final List<Recipe> dishes;

  /// Quy mô thật của bữa; nhỏ hơn quy mô đã chọn khi phải hạ (xem [relaxedNote]).
  final MealScale scale;

  /// Tổng phút nấu các món.
  final int totalMinutes;

  /// Đồ còn thiếu của cả bữa, gộp các món, không trùng.
  final Availability availability;

  /// Lý do ngắn, chỉ nêu dữ kiện: "Đủ đồ", "Dùng nốt cà chua và đậu phụ", "Giải nhiệt", "~25 phút".
  final List<String> reasons;

  /// Câu báo đã nới tiêu chí để có gợi ý, hiện bằng `InlineBanner`; null khi không phải nới.
  final String? relaxedNote;

  @override
  bool operator ==(Object other) =>
      other is MealSuggestion &&
      listEquals(other.dishes, dishes) &&
      other.scale == scale &&
      other.totalMinutes == totalMinutes &&
      other.availability == availability &&
      listEquals(other.reasons, reasons) &&
      other.relaxedNote == relaxedNote;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(dishes),
    scale,
    totalMinutes,
    availability,
    Object.hashAll(reasons),
    relaxedNote,
  );

  @override
  String toString() =>
      'MealSuggestion(${dishes.map((d) => d.id).join(' + ')}, $scale, $totalMinutes phút'
      '${relaxedNote == null ? '' : ', "$relaxedNote"'})';
}

/// Ứng viên tối đa mỗi vai, để số tổ hợp không bùng nổ khi dữ liệu nhiều món.
const _perRole = 8;

/// Thang nới thời gian: lên mốc kế tiếp, quá mốc cuối thì bỏ giới hạn.
const _timeSteps = [15, 30, 45];

/// Gợi ý một bữa theo [prefs] từ [recipes].
///
/// Lọc cứng, không bao giờ nới: dụng cụ, chế độ ăn, bữa, món bị chê ([isEligible]) và [exclude] (món
/// vừa bỏ qua ở Hôm nay ăn gì). Còn lại ghép theo khung của quy mô, không trùng món, rồi lọc mềm:
/// tổng phút ≤ `maxMinutes`, đúng cảm giác (ít nhất một món đúng, không món nào ngược), mỗi tag có ở
/// ít nhất một món.
///
/// Xếp hạng: ít thiếu đồ → (nếu `fridge`) dùng nhiều đồ trong tủ → khớp tag/cảm giác nhiều → món đã
/// lưu → ít món vừa nấu/vừa chê → tổng phút ít → thứ tự dữ liệu.
///
/// Không có bữa nào thì nới lần lượt: bỏ tags → bỏ cảm giác → nới thời gian (30 → 45 → không giới
/// hạn) → hạ quy mô (mâm cơm → 2 món → 1 món), ghi câu vào [MealSuggestion.relaxedNote]. Trả null khi
/// đã nới hết mà vẫn không có món nào hợp lệ.
MealSuggestion? suggestMeal(
  List<Recipe> recipes,
  MealPrefs prefs, {
  required Set<String> pantry,
  required Map<String, Ingredient> ingredientsById,
  Meal? meal,
  Set<Tool> tools = const {},
  Set<Diet> diets = const {},
  Set<String> exclude = const {},
  Set<String> disliked = const {},
  Set<String> demoted = const {},
  Set<String> saved = const {},
  Set<String> recentlyCooked = const {},
}) {
  final pool = <_Dish>[
    for (final (position, recipe) in recipes.indexed)
      if (!exclude.contains(recipe.id) &&
          isEligible(recipe, meal: meal, tools: tools, diets: diets, disliked: disliked))
        _Dish(recipe, position, pantry, ingredientsById),
  ];
  if (pool.isEmpty) return null;

  final context = _Context(
    pantry: pantry,
    ingredientsById: ingredientsById,
    saved: saved,
    recentlyCooked: recentlyCooked,
    demoted: demoted,
  );

  final wanted = prefs;
  var current = prefs;
  final dropped = <String>[];
  String? timeNote;
  String? scaleNote;

  while (true) {
    final best = _bestMeal(pool, current, context);
    if (best != null) {
      final relaxed = [
        if (dropped.isNotEmpty) 'bỏ tiêu chí ${_joinVi(dropped)}',
        ?timeNote,
      ];
      return _build(best, current, wanted, context, [
        ?scaleNote,
        if (relaxed.isNotEmpty) 'Đã ${relaxed.join(', ')} để có đủ gợi ý.',
      ]);
    }

    if (current.tags.isNotEmpty) {
      dropped.addAll([
        for (final tag in RecipeTag.values)
          if (current.tags.contains(tag)) tag.label,
      ]);
      current = current._copyWith(tags: const {});
    } else if (current.feel case final feel?) {
      dropped.add(feel.label);
      current = current._copyWith(feel: () => null);
    } else if (current.maxMinutes case final minutes?) {
      final next = _timeSteps.where((step) => step > minutes).firstOrNull;
      timeNote = next == null ? 'bỏ giới hạn thời gian' : 'nới thời gian lên $next phút';
      current = current._copyWith(maxMinutes: () => next);
    } else if (current.scale != MealScale.one) {
      final smaller = MealScale.values[current.scale.index - 1];
      scaleNote =
          'Chưa đủ món cho ${wanted.scale.phrase}, đã gợi ý '
          '${smaller == MealScale.one ? '1 món gọn lẹ' : smaller.phrase}.';
      current = current._copyWith(scale: smaller);
    } else {
      return null;
    }
  }
}

/// Khung bữa theo quy mô: mỗi khung là danh sách ô, mỗi ô nhận các vai cho phép. Thử lần lượt, khung
/// đầu có bữa hợp lệ thì dùng.
List<List<Set<DishRole>>> _frames(MealScale scale) => switch (scale) {
  MealScale.one => [
    [
      {DishRole.single},
    ],
    [
      {DishRole.main},
    ],
  ],
  MealScale.two => [
    [
      {DishRole.main},
      {DishRole.soup, DishRole.side},
    ],
  ],
  // Thiếu canh hoặc rau thì thay bằng món mặn thứ hai.
  MealScale.tray => [
    [
      {DishRole.main},
      {DishRole.soup},
      {DishRole.side},
    ],
    [
      {DishRole.main},
      {DishRole.soup},
      {DishRole.main},
    ],
    [
      {DishRole.main},
      {DishRole.main},
      {DishRole.side},
    ],
  ],
};

List<_Dish>? _bestMeal(List<_Dish> pool, MealPrefs prefs, _Context context) {
  final maxMinutes = prefs.maxMinutes;
  final opposite = prefs.feel?.opposite;
  // Bỏ trước món tự nó đã vượt thời gian hoặc ngược cảm giác.
  final usable = [
    for (final dish in pool)
      if ((maxMinutes == null || dish.recipe.minutes <= maxMinutes) &&
          (opposite == null || dish.recipe.feel != opposite))
        dish,
  ];

  for (final frame in _frames(prefs.scale)) {
    final slots = [
      for (final roles in frame)
        (usable.where((d) => roles.contains(d.recipe.role)).toList()
              ..sort((a, b) => _compareDish(a, b, prefs, context)))
            .take(_perRole)
            .toList(),
    ];
    if (slots.any((slot) => slot.isEmpty)) continue;

    List<_Dish>? best;
    void walk(int index, List<_Dish> picked) {
      if (index == slots.length) {
        if (!_fits(picked, prefs)) return;
        if (best == null || _compareMeal(picked, best!, prefs, context) < 0) {
          best = List.of(picked);
        }
        return;
      }
      for (final dish in slots[index]) {
        // Không trùng món; hai ô cùng vai thì giữ thứ tự để không xét một cặp hai lần.
        if (picked.any((p) => p.recipe.id == dish.recipe.id)) continue;
        if (picked.isNotEmpty &&
            setEquals(frame[index], frame[index - 1]) &&
            dish.position < picked.last.position) {
          continue;
        }
        walk(index + 1, [...picked, dish]);
      }
    }

    walk(0, const []);
    if (best != null) return best;
  }
  return null;
}

bool _fits(List<_Dish> dishes, MealPrefs prefs) {
  final maxMinutes = prefs.maxMinutes;
  if (maxMinutes != null && _minutes(dishes) > maxMinutes) return false;
  final feel = prefs.feel;
  if (feel != null && !dishes.any((d) => d.recipe.feel == feel)) return false;
  for (final tag in prefs.tags) {
    if (!dishes.any((d) => d.recipe.tags.contains(tag))) return false;
  }
  return true;
}

int _minutes(List<_Dish> dishes) => dishes.fold(0, (sum, d) => sum + d.recipe.minutes);

int _matches(Recipe recipe, MealPrefs prefs) =>
    (prefs.feel != null && recipe.feel == prefs.feel ? 1 : 0) +
    recipe.tags.where(prefs.tags.contains).length;

/// So hai món đơn lẻ để chọn ứng viên mỗi vai, cùng thứ tự ưu tiên với [_compareMeal].
int _compareDish(_Dish a, _Dish b, MealPrefs prefs, _Context context) =>
    _compareKeys(_dishKeys(a, prefs, context), _dishKeys(b, prefs, context));

List<int> _dishKeys(_Dish d, MealPrefs prefs, _Context context) => [
  d.missing.length,
  if (prefs.fridge) -d.fromPantry.length,
  -_matches(d.recipe, prefs),
  context.saved.contains(d.recipe.id) ? 0 : 1,
  (context.recentlyCooked.contains(d.recipe.id) ? 1 : 0) +
      (context.demoted.contains(d.recipe.id) ? 1 : 0),
  d.recipe.minutes,
  d.position,
];

int _compareMeal(List<_Dish> a, List<_Dish> b, MealPrefs prefs, _Context context) =>
    _compareKeys(_mealKeys(a, prefs, context), _mealKeys(b, prefs, context));

List<int> _mealKeys(List<_Dish> dishes, MealPrefs prefs, _Context context) => [
  {for (final d in dishes) ...d.missing}.length,
  if (prefs.fridge) -{for (final d in dishes) ...d.fromPantry}.length,
  -dishes.fold(0, (sum, d) => sum + _matches(d.recipe, prefs)),
  -dishes.where((d) => context.saved.contains(d.recipe.id)).length,
  dishes
      .where(
        (d) =>
            context.recentlyCooked.contains(d.recipe.id) || context.demoted.contains(d.recipe.id),
      )
      .length,
  _minutes(dishes),
  for (final d in dishes) d.position,
];

int _compareKeys(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final c = a[i].compareTo(b[i]);
    if (c != 0) return c;
  }
  return a.length.compareTo(b.length);
}

MealSuggestion _build(
  List<_Dish> dishes,
  MealPrefs used,
  MealPrefs wanted,
  _Context context,
  List<String> notes,
) {
  final missing = <String>[];
  for (final dish in dishes) {
    for (final name in dish.missing) {
      if (!missing.contains(name)) missing.add(name);
    }
  }
  final fromPantry = <String>[];
  for (final dish in dishes) {
    for (final id in dish.fromPantry) {
      final name = (context.ingredientsById[id]?.name ?? id).toLowerCase();
      if (!fromPantry.contains(name)) fromPantry.add(name);
    }
  }
  final total = _minutes(dishes);
  final feel = used.feel;

  return MealSuggestion(
    dishes: List.unmodifiable(dishes.map((d) => d.recipe)),
    scale: used.scale,
    totalMinutes: total,
    availability: Availability(missing: List.unmodifiable(missing)),
    reasons: List.unmodifiable([
      missing.isEmpty ? 'Đủ đồ' : 'Thiếu ${missing.length} thứ',
      if (wanted.fridge && fromPantry.isNotEmpty)
        'Dùng nốt ${_joinVi(fromPantry.take(2).toList())}',
      if (feel != null && dishes.any((d) => d.recipe.feel == feel)) feel.label,
      '~$total phút',
    ]),
    relaxedNote: notes.isEmpty ? null : notes.join(' '),
  );
}

/// "a", "a và b", "a, b và c".
String _joinVi(List<String> items) => items.length <= 1
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} và ${items.last}';

class _Context {
  const _Context({
    required this.pantry,
    required this.ingredientsById,
    required this.saved,
    required this.recentlyCooked,
    required this.demoted,
  });

  final Set<String> pantry;
  final Map<String, Ingredient> ingredientsById;
  final Set<String> saved;
  final Set<String> recentlyCooked;
  final Set<String> demoted;
}

/// Món đã tính sẵn đồ thiếu và đồ trong tủ được dùng, để không tính lại cho mỗi tổ hợp.
class _Dish {
  _Dish(this.recipe, this.position, Set<String> pantry, Map<String, Ingredient> ingredientsById)
    : missing = availabilityFor(recipe, pantry, ingredientsById).missing,
      fromPantry = [
        for (final item in recipe.ingredients)
          // Gia vị cơ bản luôn coi là có, không tính là "dùng nốt".
          if (pantry.contains(item.id) && !(ingredientsById[item.id]?.isBasicSpice ?? false))
            item.id,
      ];

  final Recipe recipe;
  final int position;
  final List<String> missing;
  final List<String> fromPantry;
}
