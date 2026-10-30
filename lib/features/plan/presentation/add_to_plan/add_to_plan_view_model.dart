import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/domain/plan_labels.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Key family của sheet: id các món nối bằng dấu phẩy ("trung,canh"), một món thì là id đó.
String addToPlanKey(Iterable<String> recipeIds) => recipeIds.join(',');

/// Một ô trong 7 ngày cuốn từ hôm nay.
@immutable
class DayOption {
  const DayOption({
    required this.date,
    required this.short,
    required this.label,
    required this.selected,
  });

  final DateTime date;

  /// "T3", "CN".
  final String short;

  /// Cho trình đọc màn hình: "Thứ Ba, hôm nay", "Thứ Hai tuần sau".
  final String label;
  final bool selected;
}

@immutable
class AddToPlanState {
  const AddToPlanState({
    required this.recipes,
    required this.subline,
    required this.days,
    required this.date,
    required this.meal,
    required this.servings,
    required this.mealSummaries,
    required this.joinText,
    required this.confirmLabel,
  });

  static const minServings = 1;
  static const maxServings = 6;

  /// Món đang thêm: một món (Chi tiết) hoặc cả bữa (Hôm nay ăn gì, Đã lưu).
  final List<Recipe> recipes;

  /// "Trứng chiên hành · 15 phút · Bếp từ" hoặc "A + B · 2 món".
  final String subline;

  /// 7 ngày từ hôm nay.
  final List<DayOption> days;
  final DateTime date;
  final Meal meal;
  final int servings;

  /// Món đang có trong từng bữa của ngày đang chọn ("Cơm rang, Canh rau +1 món") hoặc "Trống".
  final Map<Meal, String> mealSummaries;

  /// "Sẽ thêm cùng … · bữa này thành n món"; null khi bữa chưa có món khác.
  final String? joinText;

  /// "Thêm vào Tối nay".
  final String confirmLabel;
}

/// Sheet "Thêm vào thực đơn" (prototype `AddToPlan`, tweak `source` món/bữa). Key là
/// [addToPlanKey] của các món.
class AddToPlanViewModel extends Notifier<AsyncValue<AddToPlanState>> {
  AddToPlanViewModel(this.key);

  final String key;

  List<String> get _ids => key.split(',');

  @override
  AsyncValue<AddToPlanState> build() {
    final now = ref.watch(nowProvider);
    final today = dateOnly(now);
    final selection = ref.watch(_selectionProvider(key));
    final date = selection.date ?? today;
    final meal = selection.meal ?? mealAt(now);
    final planned = ref.watch(plannedMealsProvider);

    return ref.watch(recipesProvider).whenData((all) {
      final byId = {for (final r in all) r.id: r};
      final recipes = [for (final id in _ids) byId[id] ?? (throw StateError('Không có món "$id"'))];
      final servings =
          (selection.servings ?? recipes.map((r) => r.servings).reduce((a, b) => a > b ? a : b))
              .clamp(AddToPlanState.minServings, AddToPlanState.maxServings);

      List<Recipe> dishesOf(Meal m) => [
        for (final p in planned)
          if (p.day == date && p.meal == m) ?byId[p.recipeId],
      ];

      return AddToPlanState(
        recipes: recipes,
        subline: recipes.length == 1
            ? '${recipes.single.name} · ${recipeMeta(recipes.single)}'
            : PlanStrings.addMealSubline([for (final r in recipes) r.name]),
        days: [
          for (final day in upcomingDays(now))
            DayOption(
              date: day,
              short: weekdayShortNames[weekdayIndex(day)],
              label: dayOptionLabel(day, today),
              selected: day == date,
            ),
        ],
        date: date,
        meal: meal,
        servings: servings,
        mealSummaries: {
          for (final m in Meal.values)
            m: switch (dishesOf(m)) {
              [] => PlanStrings.addEmptyMeal,
              final dishes => dishSummary([for (final r in dishes) r.name]),
            },
        },
        joinText: joinText(dishesOf(meal), _ids),
        confirmLabel: PlanStrings.addConfirm(whenLabel(meal, date, today)),
      );
    });
  }

  void pickDay(DateTime date) => _update((s) => s.copyWith(date: dateOnly(date)));

  void pickMeal(Meal meal) => _update((s) => s.copyWith(meal: meal));

  void setServings(int servings) => _update(
    (s) => s.copyWith(
      servings: servings.clamp(AddToPlanState.minServings, AddToPlanState.maxServings),
    ),
  );

  /// Thêm mọi món vào cuối bữa đang chọn với khẩu phần đang chọn. Trả ngày và bữa vừa thêm để mở
  /// Thực đơn đúng chỗ; null khi chưa tải xong.
  Future<({DateTime date, Meal meal})?> confirm() async {
    final current = state.value;
    if (current == null) return null;
    final plan = ref.read(plannedMealsProvider.notifier);
    for (final recipe in current.recipes) {
      await plan.addToPlan(recipe.id, current.date, current.meal, servings: current.servings);
    }
    ref.read(analyticsProvider).track('plan_add', {'dishes': current.recipes.length});
    return (date: current.date, meal: current.meal);
  }

  void _update(_Selection Function(_Selection) change) {
    final provider = _selectionProvider(key);
    ref.read(provider.notifier).set(change(ref.read(provider)));
  }
}

/// Lựa chọn trong sheet; `date` null là hôm nay, `meal` null là bữa tới theo giờ, `servings` null
/// là khẩu phần chuẩn (lớn nhất trong các món).
@immutable
class _Selection {
  const _Selection({this.date, this.meal, this.servings});

  final DateTime? date;
  final Meal? meal;
  final int? servings;

  _Selection copyWith({DateTime? date, Meal? meal, int? servings}) => _Selection(
    date: date ?? this.date,
    meal: meal ?? this.meal,
    servings: servings ?? this.servings,
  );
}

class _SelectionNotifier extends Notifier<_Selection> {
  _SelectionNotifier(String _);

  @override
  _Selection build() => const _Selection();

  void set(_Selection selection) => state = selection;
}

final _selectionProvider = NotifierProvider.autoDispose
    .family<_SelectionNotifier, _Selection, String>(_SelectionNotifier.new);

final addToPlanViewModelProvider = NotifierProvider.autoDispose
    .family<AddToPlanViewModel, AsyncValue<AddToPlanState>, String>(AddToPlanViewModel.new);
