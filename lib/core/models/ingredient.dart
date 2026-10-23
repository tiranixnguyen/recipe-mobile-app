import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/models/ingredient_group.dart';

/// Nguyên liệu trong danh mục đóng gói sẵn (`assets/data/ingredients.json`).
@immutable
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.group,
    this.isBasicSpice = false,
  });

  /// Khóa duy nhất, dùng để tham chiếu trong công thức.
  final String id;

  /// Tên hiển thị tiếng Việt.
  final String name;

  /// Nhóm để gom trong Tủ đồ.
  final IngredientGroup group;

  /// Gia vị cơ bản — app coi như luôn có sẵn trong bếp.
  final bool isBasicSpice;

  /// Ném [FormatException] kèm id nguyên liệu khi `group` thiếu hoặc không có trong [IngredientGroup].
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    try {
      return Ingredient(
        id: id,
        name: json['name'] as String,
        group: IngredientGroup.fromId(json['group'] as String? ?? ''),
        isBasicSpice: json['isBasicSpice'] as bool? ?? false,
      );
    } on FormatException catch (e) {
      throw FormatException('Nguyên liệu "$id": ${e.message}');
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'group': group.id,
    'isBasicSpice': isBasicSpice,
  };

  @override
  bool operator ==(Object other) =>
      other is Ingredient &&
      other.id == id &&
      other.name == name &&
      other.group == group &&
      other.isBasicSpice == isBasicSpice;

  @override
  int get hashCode => Object.hash(id, name, group, isBasicSpice);
}
