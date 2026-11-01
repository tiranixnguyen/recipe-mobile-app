import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';
import 'package:recipe_mobile_app/features/discover/data/today_prefs.dart';
import 'package:recipe_mobile_app/features/discover/domain/today.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Số món xếp hạng lấy làm ứng viên cho nút "Đổi" một món.
const _swapPool = 50;

@immutable
class TodayState {
  const TodayState({
    required this.meal,
    this.skipped = const {},
    this.swaps = const {},
    this.tried = const {},
    this.showReasons = false,
  });

  /// Bữa sắp tới theo giờ, cố định khi mở màn.
  final Meal meal;

  /// Món của các bữa đã bỏ qua (Đổi cả bữa, chọn Hoặc thử); bữa chính không dùng lại món nào.
  final Set<String> skipped;

  /// Món đã đổi theo vị trí trong bữa chính.
  final Map<int, Recipe> swaps;

  /// Món đã thử ở từng vị trí, để "Đổi" lần lượt qua các món rồi mới quay vòng.
  final Map<int, Set<String>> tried;
  final bool showReasons;

  /// Bữa chính khác đi thì bỏ mọi món đã đổi.
  TodayState _withSkipped(Set<String> skipped) => TodayState(meal: meal, skipped: skipped);

  TodayState _copyWith({
    Map<int, Recipe>? swaps,
    Map<int, Set<String>>? tried,
    bool? showReasons,
  }) => TodayState(
    meal: meal,
    skipped: skipped,
    swaps: swaps ?? this.swaps,
    tried: tried ?? this.tried,
    showReasons: showReasons ?? this.showReasons,
  );
}

/// Một bữa đang hiện: món, tổng phút, đồ thiếu và lý do gợi ý.
@immutable
class TodayMeal {
  const TodayMeal({
    required this.dishes,
    required this.scale,
    required this.totalMinutes,
    required this.missing,
    required this.reasons,
  });

  factory TodayMeal._from(MealSuggestion suggestion) => TodayMeal(
    dishes: suggestion.dishes,
    scale: suggestion.scale,
    totalMinutes: suggestion.totalMinutes,
    missing: suggestion.availability.missing,
    reasons: suggestion.reasons,
  );

  final List<Recipe> dishes;
  final MealScale scale;
  final int totalMinutes;

  /// Tên đồ còn thiếu của cả bữa, đưa vào `AvailabilityBadge`.
  final List<String> missing;

  /// Lý do ngắn chỉ nêu dữ kiện, nối bằng " · " ở View.
  final List<String> reasons;

  List<String> get ids => [for (final d in dishes) d.id];

  /// Tên bữa ở "Hoặc thử": "A, B +N món".
  String get names => mealNames([for (final d in dishes) d.name]);

  /// Dụng cụ của các món, theo thứ tự trong [Tool.values], nhãn ngắn ("Bếp từ").
  List<String> get tools => [
    for (final tool in Tool.values)
      if (dishes.any((d) => d.tools.contains(tool))) tool.shortLabel,
  ];
}

/// Mọi thứ màn Hôm nay ăn gì vẽ: bữa chính (null khi không có gợi ý nào), tối đa 2 bữa "Hoặc thử",
/// câu "Đã nới…" và bữa đang hiện đã lưu hay chưa.
@immutable
class TodayMeals {
  const TodayMeals({
    this.main,
    this.alternatives = const [],
    this.relaxedNote,
    this.isSaved = false,
  });

  final TodayMeal? main;
  final List<TodayMeal> alternatives;
  final String? relaxedNote;
  final bool isSaved;
}

class TodayViewModel extends Notifier<TodayState> {
  bool _tracked = false;

  @override
  TodayState build() {
    // Sửa tiêu chí rồi quay lại: gợi ý lại từ đầu theo tiêu chí mới.
    ref.listen(todayPrefsProvider, (_, _) => state = TodayState(meal: state.meal));
    return TodayState(meal: mealForHour(ref.read(todayClockProvider)().hour));
  }

  MealPrefs get _prefs => ref.read(todayPrefsProvider).resolved();

  /// Đọc cùng cách tính với [todayMealsProvider]; Notifier không được đọc provider phụ thuộc nó.
  TodayMeals? get _meals => _computeMeals(state, ref.read).value;

  TodayMeal? get _main => _meals?.main;

  /// Đổi cả bữa: bỏ qua các món của bữa chính; hết bữa hợp tiêu chí thì quay lại từ đầu.
  void shuffle() {
    final main = _main;
    if (main == null) return;
    _skip(main.ids);
  }

  /// Chọn bữa thứ [index] trong "Hoặc thử": bỏ qua bữa chính và các bữa đứng trước nó, nên bữa đó
  /// thành bữa chính.
  void pickAlt(int index) {
    final meals = _meals;
    final main = meals?.main;
    if (meals == null || main == null || index >= meals.alternatives.length) return;
    _skip([
      ...main.ids,
      for (final alt in meals.alternatives.take(index)) ...alt.ids,
    ]);
  }

  void _skip(List<String> ids) {
    final skipped = {...state.skipped, ...ids};
    final suggester = ref.read(mealSuggesterProvider).value;
    final fresh = suggester != null && _hasFresh(suggester, _prefs, state.meal, skipped);
    state = state._withSkipped(fresh ? skipped : const {});
  }

  /// Đổi món ở vị trí [index] sang món cùng vai kế tiếp trong danh sách gợi ý.
  Future<void> swapDish(int index) async {
    final main = _main;
    if (main == null || index >= main.dishes.length) return;
    final ranked = await ref.read(suggestionsProvider((meal: state.meal, count: _swapPool)).future);
    if (!ref.mounted) return;
    final current = _main;
    if (current == null || index >= current.dishes.length) return;
    final next = swapCandidate(
      ranked,
      current.dishes,
      index,
      state.tried[index] ?? const {},
      feel: _prefs.feel,
    );
    if (next == null) return;
    state = state._copyWith(
      swaps: {...state.swaps, index: next.recipe},
      tried: {...state.tried, index: next.tried},
    );
  }

  void toggleReasons() => state = state._copyWith(showReasons: !state.showReasons);

  /// Không hợp: chê mọi món của bữa đang hiện, món bị chê tự rời gợi ý.
  Future<void> dislike(DislikeReason reason) async {
    final main = _main;
    if (main == null) return;
    final analytics = ref.read(analyticsProvider);
    final dislikes = ref.read(dislikedProvider.notifier);
    for (final id in main.ids) {
      await dislikes.dislike(id, reason);
    }
    analytics.track('today_dislike', {'reason': reason.id});
    if (ref.mounted) state = state._withSkipped(state.skipped);
  }

  /// Lưu hoặc bỏ lưu bữa đang hiện; trả true khi vừa lưu, false khi vừa bỏ lưu, null khi chưa có bữa.
  Future<bool?> toggleSave() async {
    final main = _main;
    if (main == null) return null;
    final analytics = ref.read(analyticsProvider);
    final controller = ref.read(savedMealsProvider.notifier);
    final existing = ref
        .read(savedMealsProvider)
        .where((m) => listEquals(m.recipeIds, main.ids))
        .firstOrNull;
    if (existing != null) {
      await controller.unsaveMeal(existing);
      return false;
    }
    final tags = [
      for (final tag in RecipeTag.values)
        if (_prefs.tags.contains(tag)) tag,
    ];
    await controller.saveMeal(
      SavedMeal(
        recipeIds: main.ids,
        servings: main.dishes.map((d) => d.servings).reduce((a, b) => a > b ? a : b),
        tags: tags,
      ),
    );
    analytics.track('save_meal', {'dishes': main.dishes.length, 'tags': tags.length});
    return true;
  }

  /// Mở sheet thêm cả bữa vào thực đơn ([show], View truyền `showAddMealToPlanSheet`); ghi sự kiện
  /// khi thêm được. Sheet chuyển sang tab Thực đơn nên lấy sẵn analytics trước khi chờ.
  Future<void> addToPlan(Future<bool> Function(List<Recipe> dishes) show) async {
    final main = _main;
    if (main == null) return;
    final analytics = ref.read(analyticsProvider);
    if (await show(main.dishes)) {
      analytics.track('add_meal_to_plan', {'dishes': main.dishes.length});
    }
  }

  /// Ghi `today_suggest` một lần, khi bữa đầu tiên hiện.
  void suggested() {
    if (_tracked) return;
    final main = _main;
    if (main == null) return;
    _tracked = true;
    ref.read(analyticsProvider).track('today_suggest', {
      'scale': main.scale.name,
      'dishes': main.dishes.length,
    });
  }
}

/// Giờ hiện tại để chọn bữa sắp tới; test override để cố định.
final todayClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final todayViewModelProvider = NotifierProvider.autoDispose<TodayViewModel, TodayState>(
  TodayViewModel.new,
);

/// Dải tiêu chí đang dùng ([criteriaLabels]).
final todayCriteriaProvider = Provider.autoDispose<List<String>>(
  (ref) => criteriaLabels(ref.watch(todayPrefsProvider)),
);

/// Bữa chính, "Hoặc thử" và trạng thái lưu theo [TodayState]; tính lại khi tủ đồ, tiêu chí, món chê
/// hay bữa đã lưu đổi.
final todayMealsProvider = Provider.autoDispose<AsyncValue<TodayMeals>>(
  (ref) => _computeMeals(ref.watch(todayViewModelProvider), ref.watch),
);

/// `ref.watch` (provider) hoặc `ref.read` (ViewModel).
typedef _Get = T Function<T>(ProviderListenable<T> provider);

AsyncValue<TodayMeals> _computeMeals(TodayState state, _Get get) {
  final prefs = get(todayPrefsProvider).resolved();
  return get(mealSuggesterProvider).whenData((suggester) {
    final picked = _pick(suggester, prefs, state.meal, state.skipped);
    final main = picked.main;
    if (main == null) return const TodayMeals();
    final shown = state.swaps.isEmpty ? main : _applySwaps(get, main, state.swaps);
    final saved = get(savedMealsProvider).any((m) => listEquals(m.recipeIds, shown.ids));
    return TodayMeals(
      main: shown,
      alternatives: picked.alternatives,
      relaxedNote: picked.relaxedNote,
      isSaved: saved,
    );
  });
}

/// Còn bữa hợp tiêu chí khi bỏ qua [skipped]: có bữa và không phải nới thêm so với lúc chưa bỏ qua.
bool _hasFresh(MealSuggester suggester, MealPrefs prefs, Meal meal, Set<String> skipped) {
  final base = suggester(prefs, meal: meal);
  final next = suggester(prefs, meal: meal, exclude: skipped);
  return base != null && next != null && next.relaxedNote == base.relaxedNote;
}

/// Bữa chính và tối đa 2 bữa thay thế, mỗi bữa không dùng lại món của bữa trước.
///
/// Chỉ giữ bữa nới tiêu chí đúng như khi không bỏ qua món nào: bỏ qua nhiều tới mức phải nới thêm
/// thì coi như đã hết bữa hợp tiêu chí và quay về bữa đầu.
({TodayMeal? main, List<TodayMeal> alternatives, String? relaxedNote}) _pick(
  MealSuggester suggester,
  MealPrefs prefs,
  Meal meal,
  Set<String> skipped,
) {
  final base = suggester(prefs, meal: meal);
  if (base == null) return (main: null, alternatives: const [], relaxedNote: null);
  bool sameRelax(MealSuggestion? s) => s != null && s.relaxedNote == base.relaxedNote;

  final first = skipped.isEmpty ? base : suggester(prefs, meal: meal, exclude: skipped);
  final fresh = sameRelax(first);
  final main = fresh ? first! : base;
  final exclude = {if (fresh) ...skipped, ...main.dishes.map((d) => d.id)};
  final alternatives = <TodayMeal>[];
  for (var i = 0; i < 2; i++) {
    final alt = suggester(prefs, meal: meal, exclude: exclude);
    if (!sameRelax(alt)) break;
    alternatives.add(TodayMeal._from(alt!));
    exclude.addAll(alt.dishes.map((d) => d.id));
  }
  return (
    main: TodayMeal._from(main),
    alternatives: alternatives,
    relaxedNote: base.relaxedNote,
  );
}

/// Bữa chính đã thay các món ở [swaps]; tính lại phút và đồ thiếu, lý do chỉ còn dữ kiện.
TodayMeal _applySwaps(_Get get, TodayMeal main, Map<int, Recipe> swaps) {
  final dishes = [
    for (final (i, dish) in main.dishes.indexed) swaps[i] ?? dish,
  ];
  final ingredients = get(ingredientsProvider).value ?? const <Ingredient>[];
  final byId = <String, Ingredient>{for (final i in ingredients) i.id: i};
  final pantry = get(pantryItemsProvider);
  final missing = <String>[];
  for (final dish in dishes) {
    for (final name in availabilityFor(dish, pantry, byId).missing) {
      if (!missing.contains(name)) missing.add(name);
    }
  }
  final total = dishes.fold(0, (sum, d) => sum + d.minutes);
  return TodayMeal(
    dishes: List.unmodifiable(dishes),
    scale: main.scale,
    totalMinutes: total,
    missing: List.unmodifiable(missing),
    reasons: [
      missing.isEmpty
          ? DiscoverStrings.todayHasAll
          : DiscoverStrings.todayMissingCount(missing.length),
      DiscoverStrings.todayAboutMinutes(total),
    ],
  );
}
