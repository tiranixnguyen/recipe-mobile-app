import 'package:intl/intl.dart';

import 'package:recipe_mobile_app/core/models/recipe.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';

final _amountFormat = NumberFormat('0.##', 'vi');

/// Hiển thị lượng nguyên liệu kiểu Việt Nam: bỏ số 0 thừa, dấu phẩy thập phân, tối đa 2 chữ số lẻ.
///
/// `4.0` → `4`, `1.5` → `1,5`, `1 / 3` → `0,33`.
String formatAmount(double amount) => _amountFormat.format(amount);

/// Dòng meta của món: "15 phút · Bếp từ", hoặc "15 phút · 2 người · Bếp từ" khi [servings].
///
/// Dụng cụ lấy cái đầu tiên của món, nhãn ngắn (`Tool.shortLabel`).
String recipeMeta(Recipe recipe, {bool servings = false}) => RecipeCard.metaText(
  minutes: recipe.minutes,
  servings: servings ? recipe.servings : null,
  tool: recipe.tools.firstOrNull?.shortLabel,
);
