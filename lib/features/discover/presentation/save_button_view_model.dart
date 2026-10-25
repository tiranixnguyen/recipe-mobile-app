import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';

/// Điều phối nút lưu; chỉ ghi analytics sau khi LocalStore đã ghi thành công.
class SaveButtonViewModel extends Notifier<void> {
  Future<void> _pending = Future.value();

  @override
  void build() {}

  Future<void> toggle(String recipeId) {
    final operation = _pending.then((_) async {
      final wasSaved = ref.read(savedIdsProvider).contains(recipeId);
      await ref.read(savedIdsProvider.notifier).toggle(recipeId);
      ref.read(analyticsProvider).track('save_recipe', {'saved': !wasSaved});
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}

final saveButtonViewModelProvider = NotifierProvider<SaveButtonViewModel, void>(
  SaveButtonViewModel.new,
);
