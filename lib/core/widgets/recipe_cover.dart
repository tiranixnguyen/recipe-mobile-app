import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Ảnh món tỉ lệ 16:10. Chưa có ảnh (đường dẫn rỗng hoặc file không tồn tại) thì hiện hình bát
/// `chili` trên nền `chiliSoft`, như phần ảnh của `RecipeCard` trong design.
class RecipeCover extends StatelessWidget {
  const RecipeCover({super.key, this.imageAsset, this.aspectRatio = 16 / 10});

  /// Đường dẫn asset, ví dụ `Recipe.imageAsset`.
  final String? imageAsset;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: asset == null || asset.isEmpty
          ? const _Placeholder()
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const _Placeholder(),
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.chiliSoft,
      child: Center(child: Icon(AppIcons.bowl, size: 48, color: colors.chili)),
    );
  }
}
