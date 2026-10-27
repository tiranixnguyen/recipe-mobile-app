import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/models/diet.dart';
import 'package:recipe_mobile_app/core/models/meal.dart';
import 'package:recipe_mobile_app/core/models/tool.dart';

/// Một nguyên liệu trong công thức, kèm lượng và ghi chú thay thế.
@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.id,
    required this.amount,
    required this.unit,
    this.optional = false,
    this.substituteNote,
  });

  /// Tham chiếu tới `Ingredient.id`.
  final String id;

  /// Lượng cho [Recipe.servings] khẩu phần.
  final double amount;

  /// Đơn vị: quả, nhánh, muỗng canh, g…
  final String unit;

  /// Nguyên liệu tuỳ chọn — thiếu vẫn nấu được.
  final bool optional;

  /// Ghi chú cách thay thế khi thiếu.
  final String? substituteNote;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      optional: json['optional'] as bool? ?? false,
      substituteNote: json['substituteNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'amount': amount,
    'unit': unit,
    'optional': optional,
    if (substituteNote != null) 'substituteNote': substituteNote,
  };

  @override
  bool operator ==(Object other) =>
      other is RecipeIngredient &&
      other.id == id &&
      other.amount == amount &&
      other.unit == unit &&
      other.optional == optional &&
      other.substituteNote == substituteNote;

  @override
  int get hashCode => Object.hash(id, amount, unit, optional, substituteNote);
}

/// Một việc sơ chế trên một nguyên liệu của bước sơ chế: "Cà chua — Bổ múi cau".
@immutable
class PrepTask {
  const PrepTask({required this.id, required this.action, this.amount});

  /// Nguyên liệu được sơ chế, tham chiếu tới `RecipeIngredient.id` cùng món.
  final String id;

  /// Cách sơ chế, ngắn, viết hoa chữ đầu, không dấu chấm cuối: "Thái nhỏ", "Đập ra bát rồi đánh tan".
  final String action;

  /// Lượng sơ chế theo cách này, cùng đơn vị với nguyên liệu [id] của món; null = cả lượng của món.
  /// Dùng khi một nguyên liệu chia hai cách làm (một nửa thái nhỏ, một nửa cắt khúc).
  final double? amount;

  factory PrepTask.fromJson(Map<String, dynamic> json) {
    return PrepTask(
      id: json['id'] as String,
      action: json['action'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'action': action,
    if (amount != null) 'amount': amount,
  };

  @override
  bool operator ==(Object other) =>
      other is PrepTask && other.id == id && other.action == action && other.amount == amount;

  @override
  int get hashCode => Object.hash(id, action, amount);

  @override
  String toString() => 'PrepTask($id: $action${amount == null ? '' : ' · $amount'})';
}

/// Một bước nấu, có thể kèm thời gian hẹn giờ.
@immutable
class RecipeStep {
  const RecipeStep({required this.text, this.timerSeconds, this.prep = const []});

  final String text;

  /// Thời gian hẹn giờ (giây) cho bước này, null nếu không có.
  final int? timerSeconds;

  /// Việc sơ chế trong bước, theo nguyên liệu; rỗng = bước đứng bếp. Bước sơ chế (rửa, thái, ngâm,
  /// ướp, đánh trứng, vo gạo) làm trước được, không cần bếp, nước sôi hay hẹn giờ. Nấu cả bữa gom
  /// việc của mọi món thành chặng "Sơ chế cả bữa" đầu tiên.
  final List<PrepTask> prep;

  /// Bước sơ chế ([prep] không rỗng).
  bool get isPrep => prep.isNotEmpty;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      text: json['text'] as String,
      timerSeconds: json['timerSeconds'] as int?,
      prep: List.unmodifiable(
        ((json['prep'] as List<dynamic>?) ?? const []).map(
          (e) => PrepTask.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    if (timerSeconds != null) 'timerSeconds': timerSeconds,
    if (prep.isNotEmpty) 'prep': prep.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is RecipeStep &&
      other.text == text &&
      other.timerSeconds == timerSeconds &&
      listEquals(other.prep, prep);

  @override
  int get hashCode => Object.hash(text, timerSeconds, Object.hashAll(prep));
}

/// Công thức nấu ăn đóng gói sẵn trong app — **không có trường giá**.
@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.minutes,
    this.prepMinutes,
    required this.servings,
    required this.tools,
    required this.diets,
    required this.meals,
    required this.ingredients,
    required this.steps,
    this.notes = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Đường dẫn asset ảnh (tương đối trong `assets/`).
  final String imageAsset;

  /// Tổng thời gian nấu (phút).
  final int minutes;

  /// Phút sơ chế, đã tính trong [minutes]; null khi món không có bước sơ chế. Nấu cả bữa cộng lại
  /// thành "sơ chế ~8 phút, nấu ~27 phút".
  final int? prepMinutes;

  /// Khẩu phần chuẩn của công thức.
  final int servings;

  /// Dụng cụ cần có.
  final List<Tool> tools;

  /// Các chế độ ăn món này thoả mãn (rỗng = không hợp chế độ nào).
  ///
  /// Người có chế độ X chỉ được gợi ý món có X trong danh sách. Nhập thiếu tag thì món chỉ bị ẩn bớt,
  /// không bị gợi ý nhầm cho người không ăn được.
  final List<Diet> diets;

  /// Bữa phù hợp (rỗng = mọi bữa).
  final List<Meal> meals;

  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  /// Lưu ý cách dùng (ăn nóng, ăn kèm gì, để được bao lâu), mỗi mục một câu ngắn; rỗng = không có.
  /// Màn Nấu hiện ở trang "Lưu ý cách dùng" sau bước cuối.
  final List<String> notes;

  /// Ném [FormatException] kèm id món khi có dụng cụ, chế độ ăn hoặc bữa không thuộc danh sách.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    try {
      return Recipe(
        id: id,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        imageAsset: json['imageAsset'] as String,
        minutes: json['minutes'] as int,
        prepMinutes: json['prepMinutes'] as int?,
        servings: json['servings'] as int,
        tools: _parseEnumList(json['tools'], Tool.fromId),
        diets: _parseEnumList(json['diets'], Diet.fromId),
        meals: _parseEnumList(json['meals'], Meal.fromId),
        ingredients: List.unmodifiable(
          (json['ingredients'] as List<dynamic>).map(
            (e) => RecipeIngredient.fromJson(e as Map<String, dynamic>),
          ),
        ),
        steps: List.unmodifiable(
          (json['steps'] as List<dynamic>).map(
            (e) => RecipeStep.fromJson(e as Map<String, dynamic>),
          ),
        ),
        notes: List.unmodifiable(((json['notes'] as List<dynamic>?) ?? const []).cast<String>()),
      );
    } on FormatException catch (e) {
      throw FormatException('Món "$id": ${e.message}');
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'imageAsset': imageAsset,
    'minutes': minutes,
    if (prepMinutes != null) 'prepMinutes': prepMinutes,
    'servings': servings,
    'tools': tools.map((e) => e.id).toList(),
    'diets': diets.map((e) => e.id).toList(),
    'meals': meals.map((e) => e.id).toList(),
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    if (notes.isNotEmpty) 'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.imageAsset == imageAsset &&
      other.minutes == minutes &&
      other.prepMinutes == prepMinutes &&
      other.servings == servings &&
      listEquals(other.tools, tools) &&
      listEquals(other.diets, diets) &&
      listEquals(other.meals, meals) &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.steps, steps) &&
      listEquals(other.notes, notes);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    imageAsset,
    minutes,
    prepMinutes,
    servings,
    Object.hashAll(tools),
    Object.hashAll(diets),
    Object.hashAll(meals),
    Object.hashAll(ingredients),
    Object.hashAll(steps),
    Object.hashAll(notes),
  );

  static List<T> _parseEnumList<T>(dynamic value, T Function(String) parser) {
    if (value == null) return List<T>.unmodifiable(const []);
    return List<T>.unmodifiable((value as List<dynamic>).map((e) => parser(e as String)));
  }
}

/// Nhân lượng nguyên liệu theo khẩu phần mong muốn (hàm thuần, có unit test).
///
/// [amount] là lượng cho [baseServings] khẩu phần; trả về lượng cho [targetServings].
double scaleAmount(double amount, int baseServings, int targetServings) {
  if (baseServings <= 0) return amount;
  return amount * targetServings / baseServings;
}

/// Nhân toàn bộ nguyên liệu của [recipe] theo [targetServings] khẩu phần.
List<RecipeIngredient> scaleIngredients(Recipe recipe, int targetServings) {
  return recipe.ingredients
      .map(
        (ing) => RecipeIngredient(
          id: ing.id,
          amount: scaleAmount(ing.amount, recipe.servings, targetServings),
          unit: ing.unit,
          optional: ing.optional,
          substituteNote: ing.substituteNote,
        ),
      )
      .toList();
}

/// Tổng lượng một nguyên liệu (cùng đơn vị) cho nhiều món, kèm món dùng tới nó.
@immutable
class GatheredIngredient {
  const GatheredIngredient({
    required this.ingredientId,
    required this.unit,
    required this.amount,
    required this.recipeIds,
  });

  final String ingredientId;
  final String unit;
  final double amount;

  /// Món dùng tới nguyên liệu này, theo thứ tự gặp đầu tiên, không trùng.
  final List<String> recipeIds;

  @override
  bool operator ==(Object other) =>
      other is GatheredIngredient &&
      other.ingredientId == ingredientId &&
      other.unit == unit &&
      other.amount == amount &&
      listEquals(other.recipeIds, recipeIds);

  @override
  int get hashCode => Object.hash(ingredientId, unit, amount, Object.hashAll(recipeIds));

  @override
  String toString() => 'GatheredIngredient($ingredientId, $amount $unit, $recipeIds)';
}

/// Gom nguyên liệu của [dishes] (mỗi món kèm số người nấu) — dùng cho danh sách đi chợ và Nấu cả bữa.
///
/// Lượng nhân theo khẩu phần bằng [scaleAmount], cộng dồn theo (nguyên liệu, đơn vị); khác đơn vị
/// thì tách dòng. Giữ thứ tự xuất hiện đầu tiên. Món không có trong [recipesById] bị bỏ qua.
List<GatheredIngredient> gatherIngredients(
  Iterable<({String recipeId, int servings})> dishes,
  Map<String, Recipe> recipesById,
) {
  final amounts = <(String, String), double>{};
  final usedBy = <(String, String), List<String>>{};
  for (final dish in dishes) {
    final recipe = recipesById[dish.recipeId];
    if (recipe == null) continue;
    for (final ing in recipe.ingredients) {
      final key = (ing.id, ing.unit);
      final amount = scaleAmount(ing.amount, recipe.servings, dish.servings);
      amounts[key] = (amounts[key] ?? 0) + amount;
      final ids = usedBy.putIfAbsent(key, () => []);
      if (!ids.contains(recipe.id)) ids.add(recipe.id);
    }
  }
  return List.unmodifiable([
    for (final MapEntry(key: (id, unit), value: amount) in amounts.entries)
      GatheredIngredient(
        ingredientId: id,
        unit: unit,
        amount: amount,
        recipeIds: List.unmodifiable(usedBy[(id, unit)]!),
      ),
  ]);
}
