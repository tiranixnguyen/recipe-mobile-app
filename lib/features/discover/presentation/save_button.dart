import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Nút lưu món: tròn [size] (40), nền `surfaceRaised`; đã lưu thì bookmark tô đặc màu `chili`.
///
/// Đặt vào slot `action` của `RecipeCard`, hoặc trên ảnh màn Chi tiết món (`size: 48`).
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.recipeId, this.size = 40});

  final String recipeId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final saved = ref.watch(savedIdsProvider.select((ids) => ids.contains(recipeId)));
    return Semantics(
      toggled: saved,
      child: IconButton(
        onPressed: () => ref.read(savedIdsProvider.notifier).toggle(recipeId),
        tooltip: saved ? DiscoverStrings.unsave : DiscoverStrings.save,
        icon: Icon(AppIcons.bookmark, fill: saved ? 1 : 0),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          minimumSize: Size.square(size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: colors.surfaceRaised,
          foregroundColor: saved ? colors.chili : colors.ink,
        ),
      ),
    );
  }
}
