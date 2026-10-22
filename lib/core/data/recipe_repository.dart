import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

/// Đọc công thức và danh mục nguyên liệu đóng gói trong `assets/data/`.
///
/// Feature không gọi thẳng class này mà đọc qua [recipesProvider] và [ingredientsProvider].
class RecipeRepository {
  RecipeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<Ingredient>> loadIngredients() async {
    final list = jsonDecode(await _bundle.loadString('assets/data/ingredients.json')) as List;
    return List.unmodifiable(list.map((e) => Ingredient.fromJson(e as Map<String, dynamic>)));
  }

  Future<List<Recipe>> loadRecipes() async {
    final list = jsonDecode(await _bundle.loadString('assets/data/recipes.json')) as List;
    return List.unmodifiable(list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)));
  }
}

/// Test override bằng repository đọc [AssetBundle] giả, hoặc override thẳng [recipesProvider].
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) => RecipeRepository());

/// Dữ liệu đóng gói lỗi thì đọc lại vẫn lỗi, nên tắt retry mặc định của Riverpod.
Duration? _noRetry(int retryCount, Object error) => null;

/// Danh mục nguyên liệu đóng gói, đọc một lần cho cả phiên.
final ingredientsProvider = FutureProvider<List<Ingredient>>(
  (ref) => ref.watch(recipeRepositoryProvider).loadIngredients(),
  retry: _noRetry,
);

/// Toàn bộ công thức đóng gói, đọc một lần cho cả phiên.
final recipesProvider = FutureProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).loadRecipes(),
  retry: _noRetry,
);
