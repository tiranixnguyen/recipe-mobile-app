import 'package:flutter/foundation.dart';

import 'diet.dart';
import 'meal.dart';
import 'tool.dart';

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

/// Một bước nấu, có thể kèm thời gian hẹn giờ.
@immutable
class RecipeStep {
  const RecipeStep({required this.text, this.timerSeconds});

  final String text;

  /// Thời gian hẹn giờ (giây) cho bước này, null nếu không có.
  final int? timerSeconds;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      text: json['text'] as String,
      timerSeconds: json['timerSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    if (timerSeconds != null) 'timerSeconds': timerSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is RecipeStep && other.text == text && other.timerSeconds == timerSeconds;

  @override
  int get hashCode => Object.hash(text, timerSeconds);
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
    required this.servings,
    required this.tools,
    required this.diets,
    required this.meals,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;

  /// Đường dẫn asset ảnh (tương đối trong `assets/`).
  final String imageAsset;

  /// Tổng thời gian nấu (phút).
  final int minutes;

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
    'servings': servings,
    'tools': tools.map((e) => e.id).toList(),
    'diets': diets.map((e) => e.id).toList(),
    'meals': meals.map((e) => e.id).toList(),
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.imageAsset == imageAsset &&
      other.minutes == minutes &&
      other.servings == servings &&
      listEquals(other.tools, tools) &&
      listEquals(other.diets, diets) &&
      listEquals(other.meals, meals) &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.steps, steps);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    imageAsset,
    minutes,
    servings,
    Object.hashAll(tools),
    Object.hashAll(diets),
    Object.hashAll(meals),
    Object.hashAll(ingredients),
    Object.hashAll(steps),
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
