import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/domain/meal_detail.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Một món trong bữa kèm độ sẵn đồ so với Tủ đồ.
typedef MealDish = ({Recipe recipe, Availability availability});

/// Sheet chọn món đang mở: thêm món ([swapId] null) hoặc đổi món [swapId].
@immutable
class PickerState {
  const PickerState({this.swapId, this.query = '', this.role});

  final String? swapId;
  final String query;

  /// Lọc theo loại món; null là Tất cả.
  final DishRole? role;

  bool get swapping => swapId != null;

  PickerState copyWith({String? query, DishRole? role, bool clearRole = false}) => PickerState(
    swapId: swapId,
    query: query ?? this.query,
    role: clearRole ? null : role ?? this.role,
  );
}

/// Một món trong sheet chọn món.
typedef PickItem = ({Recipe recipe, Availability availability, bool inMeal});

/// Nhóm món trong sheet: "Món bạn đã lưu" ([saved]) hoặc "Tất cả món".
typedef PickGroup = ({bool saved, List<PickItem> items});

@immutable
class MealDetailState {
  const MealDetailState({
    required this.dishes,
    required this.servings,
    required this.tags,
    required this.saved,
    required this.ingredients,
    required this.shoppingCount,
    this.picker,
    this.groups = const [],
  });

  /// Món đang sửa, theo thứ tự hiển thị.
  final List<MealDish> dishes;
  final int servings;
  final List<RecipeTag> tags;

  /// Bữa (với danh sách món hiện tại) đang nằm trong Đã lưu.
  final bool saved;
  final MealIngredients ingredients;

  /// Số trên badge nút Đi chợ.
  final int shoppingCount;

  /// Sheet chọn món; null khi đóng.
  final PickerState? picker;

  /// Món của sheet sau khi lọc; rỗng khi sheet đóng hoặc không món nào khớp.
  final List<PickGroup> groups;

  List<Recipe> get recipes => [for (final d in dishes) d.recipe];

  /// Bỏ món chỉ khi bữa còn hơn một món.
  bool get canRemove => dishes.length > 1;

  /// Nấu lần lượt từng món nên cộng thời gian; prototype ghi "~".
  int get minutes => dishes.fold(0, (sum, d) => sum + d.recipe.minutes);

  /// Dụng cụ của cả bữa, không trùng: "Bếp từ, Nồi cơm điện".
  String? get tools {
    final labels = {
      for (final d in dishes)
        for (final t in d.recipe.tools) t.shortLabel,
    };
    return labels.isEmpty ? null : labels.join(', ');
  }

  /// Nguyên liệu thiếu, mỗi thứ một lần dù xuất hiện ở nhiều đơn vị.
  List<String> get missingIds => List.unmodifiable({
    for (final m in ingredients.missing) m.ingredientId,
  });

  /// Nguyên liệu thiếu mà chưa nằm trong đi chợ: nút "Thêm n thứ" sẽ thêm đúng các thứ này.
  List<String> get toAddIds => List.unmodifiable({
    for (final m in ingredients.missing)
      if (!m.inShopping) m.ingredientId,
  });
}

/// Thay đổi món vừa làm, để View báo snackbar và Hoàn tác.
enum MealChangeKind { added, removed, swapped }

typedef MealChange = ({
  MealChangeKind kind,

  /// Tên món vừa thêm, bỏ, hoặc món mới khi đổi.
  String name,

  /// Tên món bị thay khi đổi.
  String? from,

  /// Trả bữa về danh sách trước đó, cả khi màn đã đóng.
  Future<void> Function() undo,
});

/// Chi tiết một bữa (prototype `MealDetail`), mở bằng `SavedMeal.key`. Dữ liệu là null khi bữa
/// không có trong Đã lưu lúc mở, hoặc không món nào còn trong dữ liệu.
///
/// Bữa được sửa tại chỗ: thêm, bỏ, đổi món và Hoàn tác. Danh sách đang sửa nằm ở đây, nên bỏ lưu
/// xong vẫn ở lại màn và sửa tiếp được; khi bữa đang lưu thì mỗi lần sửa ghi lại
/// `savedMealsProvider`. Màn giữ nguyên khoá mở ban đầu, vì khoá đổi theo danh sách món.
class SavedMealViewModel extends Notifier<AsyncValue<MealDetailState?>> {
  SavedMealViewModel(this._key);

  final String _key;

  // Giữ qua các lần build lại, chỉ mất khi rời màn.
  List<String>? _ids;
  int _servings = 1;
  List<RecipeTag> _tags = const [];
  PickerState? _picker;

  @override
  AsyncValue<MealDetailState?> build() {
    final savedMeals = ref.watch(savedMealsProvider);
    if (_ids == null) {
      final meal = savedMeals.where((m) => m.key == _key).firstOrNull;
      if (meal != null) {
        _ids = meal.recipeIds;
        _servings = meal.servings;
        _tags = meal.tags;
      }
    }
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);
    return switch ((recipes, ingredients)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => AsyncData(
        _detail(savedMeals, recipes, ingredients),
      ),
      _ => const AsyncLoading(),
    };
  }

  MealDetailState? _detail(
    List<SavedMeal> savedMeals,
    List<Recipe> all,
    List<Ingredient> ingredients,
  ) {
    final ids = _ids;
    if (ids == null) return null;
    final byId = {for (final r in all) r.id: r};
    final ingredientsById = {for (final i in ingredients) i.id: i};
    final pantry = ref.watch(pantryItemsProvider);
    final shoppingItems = ref.watch(shoppingItemsProvider);
    final recipes = [for (final id in ids) ?byId[id]];
    if (recipes.isEmpty) return null;

    MealDish dish(Recipe r) =>
        (recipe: r, availability: availabilityFor(r, pantry, ingredientsById));
    final picker = _picker;
    return MealDetailState(
      dishes: List.unmodifiable([for (final r in recipes) dish(r)]),
      servings: _servings,
      tags: _tags,
      saved: savedMeals.any((m) => m.key == SavedMeal.keyOf(ids)),
      ingredients: mergeMealIngredients(recipes, _servings, pantry, ingredientsById, {
        for (final i in shoppingItems) ?i.ingredientId,
      }),
      shoppingCount: ref.watch(shoppingCountProvider),
      picker: picker,
      groups: picker == null
          ? const []
          : _groups(all, picker, ids, ref.watch(savedIdsProvider), dish),
    );
  }

  List<PickGroup> _groups(
    List<Recipe> all,
    PickerState picker,
    List<String> ids,
    Set<String> savedIds,
    MealDish Function(Recipe) dish,
  ) {
    final lists = filterPickerRecipes(
      all,
      savedIds: savedIds,
      query: picker.query,
      role: picker.role,
    );
    PickItem item(Recipe r) => (
      recipe: r,
      availability: dish(r).availability,
      inMeal: ids.contains(r.id),
    );
    return List.unmodifiable([
      if (lists.saved.isNotEmpty) (saved: true, items: [for (final r in lists.saved) item(r)]),
      if (lists.others.isNotEmpty) (saved: false, items: [for (final r in lists.others) item(r)]),
    ]);
  }

  // Sheet chọn món

  /// Mở sheet "Thêm món vào bữa".
  void openAdd() {
    _picker = const PickerState();
    ref.invalidateSelf();
  }

  /// Mở sheet "Đổi món [id] thành": lọc sẵn theo loại của món đó (trừ loại không có chip lọc).
  void openSwap(String id) {
    final role = ref.read(recipesProvider).value?.where((r) => r.id == id).firstOrNull?.role;
    _picker = PickerState(swapId: id, role: pickerRoles.contains(role) ? role : null);
    ref.invalidateSelf();
  }

  void closePicker() {
    if (_picker == null) return;
    _picker = null;
    if (ref.mounted) ref.invalidateSelf();
  }

  void setQuery(String query) {
    final picker = _picker;
    if (picker == null) return;
    _picker = picker.copyWith(query: query);
    ref.invalidateSelf();
  }

  void setRole(DishRole? role) {
    final picker = _picker;
    if (picker == null) return;
    _picker = picker.copyWith(role: role, clearRole: role == null);
    ref.invalidateSelf();
  }

  // Sửa món

  /// Thêm món [id] vào cuối bữa; null nếu món đã có hoặc không có trong dữ liệu.
  Future<MealChange?> add(String id) async {
    final ids = _ids;
    final recipe = _recipe(id);
    if (ids == null || recipe == null || ids.contains(id)) return null;
    return _change([...ids, id], MealChangeKind.added, recipe.name);
  }

  /// Bỏ món [id]; null nếu món không có trong bữa hoặc là món duy nhất.
  Future<MealChange?> remove(String id) async {
    final ids = _ids;
    final recipe = _recipe(id);
    if (ids == null || recipe == null || !ids.contains(id) || ids.length <= 1) return null;
    return _change([...ids]..remove(id), MealChangeKind.removed, recipe.name);
  }

  /// Đổi món [oldId] thành [newId] ngay vị trí cũ; null nếu [oldId] không có trong bữa hoặc [newId]
  /// đã có.
  Future<MealChange?> swap(String oldId, String newId) async {
    final ids = _ids;
    final from = _recipe(oldId);
    final to = _recipe(newId);
    if (ids == null || from == null || to == null || !ids.contains(oldId) || ids.contains(newId)) {
      return null;
    }
    return _change(
      [for (final id in ids) id == oldId ? newId : id],
      MealChangeKind.swapped,
      to.name,
      from: from.name,
    );
  }

  Recipe? _recipe(String id) =>
      ref.read(recipesProvider).value?.where((r) => r.id == id).firstOrNull;

  Future<MealChange> _change(
    List<String> next,
    MealChangeKind kind,
    String name, {
    String? from,
  }) async {
    final previous = _ids!;
    final before = SavedMeal(recipeIds: previous, servings: _servings, tags: _tags);
    final after = SavedMeal(recipeIds: next, servings: _servings, tags: _tags);
    final meals = ref.read(savedMealsProvider.notifier);
    final wasSaved = ref.read(savedMealsProvider).any((m) => m.key == before.key);
    _ids = next;
    if (wasSaved) await meals.replaceMeal(before, after);
    if (ref.mounted) ref.invalidateSelf();
    return (
      kind: kind,
      name: name,
      from: from,
      undo: () async {
        if (wasSaved) await meals.replaceMeal(after, before);
        if (ref.mounted) {
          _ids = previous;
          ref.invalidateSelf();
        }
      },
    );
  }

  // Lưu

  /// Nút bookmark ở header: đang lưu thì bỏ lưu (trả [UnsaveOutcome] để View báo Hoàn tác), chưa
  /// lưu thì lưu lại bữa đang sửa (trả null). Cả hai đều ở lại màn.
  Future<UnsaveOutcome?> toggleSave() async {
    final detail = state.value;
    final ids = _ids;
    if (detail == null || ids == null) return null;
    if (detail.saved) {
      final stored = ref.read(savedMealsProvider).firstWhere((m) => m.key == SavedMeal.keyOf(ids));
      return unsaveEntry(ref, SavedMealEntry(meal: stored, recipes: detail.recipes));
    }
    final saved = await ref
        .read(savedMealsProvider.notifier)
        .saveMeal(SavedMeal(recipeIds: ids, servings: _servings, tags: _tags));
    if (saved) {
      ref.read(analyticsProvider).track('save_meal', {
        'dishes': ids.length,
        'tags': _tags.length,
      });
    }
    return null;
  }

  // Đi chợ, thực đơn, nấu

  /// "Thêm n thứ còn thiếu vào đi chợ": thêm từng thứ thiếu chưa có trong đi chợ. Trả số thứ thêm
  /// được và số thứ đã có sẵn, cho snackbar.
  Future<({int added, int skipped})> addMissingToShopping() async {
    final detail = state.value;
    if (detail == null) return (added: 0, skipped: 0);
    final shopping = ref.read(shoppingItemsProvider.notifier);
    var added = 0;
    for (final id in detail.toAddIds) {
      if (await shopping.addIngredient(id) == AddToShoppingResult.added) added++;
    }
    if (added > 0) {
      ref.read(analyticsProvider).track('add_missing_to_shopping', {
        'from': 'meal',
        'items': added,
      });
    }
    return (added: added, skipped: detail.missingIds.length - added);
  }

  /// Mở sheet thêm cả bữa vào thực đơn ([show], View truyền `showAddMealToPlanSheet`); ghi sự kiện
  /// khi thêm được. Lấy sẵn analytics vì sheet chuyển sang tab Thực đơn.
  Future<void> addToPlan(Future<bool> Function(List<Recipe> dishes) show) async {
    final detail = state.value;
    if (detail == null) return;
    final analytics = ref.read(analyticsProvider);
    if (await show(detail.recipes)) {
      analytics.track('add_meal_to_plan', {'dishes': detail.dishes.length});
    }
  }

  /// "Bắt đầu nấu": đường dẫn tới Chuẩn bị nấu cả bữa với các món đang sửa. Sự kiện
  /// `start_cooking` ghi ở màn đó, khi người dùng bắt đầu thật.
  String? startCooking() {
    final detail = state.value;
    if (detail == null) return null;
    return mealCookDishesLocation([for (final d in detail.dishes) d.recipe.id], detail.servings);
  }
}

final savedMealViewModelProvider = NotifierProvider.autoDispose
    .family<SavedMealViewModel, AsyncValue<MealDetailState?>, String>(SavedMealViewModel.new);
