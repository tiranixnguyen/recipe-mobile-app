import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';

/// Thẻ công thức trong lưới hoặc danh sách (component `RecipeCard`).
///
/// Nền `surfaceRaised`, viền `line`, bo `radius-md`; ảnh 16:10 ([RecipeCover]), tên tối đa 2 dòng,
/// meta `15 phút · 1 người · Bếp từ`. Hai slot để `core` không phụ thuộc feature:
///
/// ```dart
/// RecipeCard(
///   title: recipe.name, minutes: recipe.minutes, servings: recipe.servings, tool: 'Bếp từ',
///   imageAsset: recipe.imageAsset,
///   badge: AvailabilityBadge(missing: availability.missing), // bỏ trống khi không biết tủ đồ
///   action: SaveButton(recipeId: recipe.id),                 // nút lưu góc trên ảnh
///   onTap: () => context.push(recipeLocation(recipe.id)),
/// )
/// ```
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.title,
    required this.minutes,
    this.servings,
    this.tool,
    this.imageAsset,
    this.badge,
    this.action,
    this.onTap,
  });

  final String title;
  final int minutes;
  final int? servings;

  /// Dụng cụ chính, ngắn gọn: "Bếp từ", "Nồi cơm điện".
  final String? tool;
  final String? imageAsset;

  /// Thường là `AvailabilityBadge`, hiện dưới dòng meta.
  final Widget? badge;

  /// Thường là `SaveButton`, đặt góc trên bên phải ảnh.
  final Widget? action;
  final VoidCallback? onTap;

  static String metaText({required int minutes, int? servings, String? tool}) => [
    '$minutes phút',
    if (servings != null) '$servings người',
    ?tool,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badge = this.badge;
    final action = this.action;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                RecipeCover(imageAsset: imageAsset),
                if (action != null)
                  Positioned(top: AppSpacing.s2, right: AppSpacing.s2, child: action),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s2,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                  ),
                  Row(
                    spacing: AppSpacing.s1,
                    children: [
                      Icon(AppIcons.clock, size: 16, color: colors.inkMuted),
                      Flexible(
                        child: Text(
                          metaText(minutes: minutes, servings: servings, tool: tool),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                  ?badge,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
