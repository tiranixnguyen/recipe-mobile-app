import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/presentation/save_button_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Nút lưu món: tròn 40, nền `surfaceRaised`; đã lưu thì bookmark tô đặc màu `chili`.
///
/// Đặt vào slot `action` của `RecipeCard`, hoặc thanh trên màn Chi tiết món.
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final saved = ref.watch(savedIdsProvider.select((ids) => ids.contains(recipeId)));
    return Semantics(
      toggled: saved,
      child: IconButton(
        onPressed: () => ref.read(saveButtonViewModelProvider.notifier).toggle(recipeId),
        tooltip: saved ? DiscoverStrings.unsave : DiscoverStrings.save,
        icon: Icon(AppIcons.bookmark, fill: saved ? 1 : 0),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: colors.surfaceRaised,
          foregroundColor: saved ? colors.chili : colors.ink,
        ),
      ),
    );
  }
}
