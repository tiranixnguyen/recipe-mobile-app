import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';

/// Hàng món gọn: ảnh vuông, tên và một dòng phụ, theo các list trong prototype `Main` ("Nhanh sau
/// giờ học"), `Pantry` và `MealPlan` (design system chưa có component này).
///
/// Nền `surfaceRaised`, viền `line`, bo `radius-md`, đệm 8 (đổi bằng [padding]). Dòng phụ thường là meta `inkMuted`
/// ("15 phút · Bếp từ"); [emphasizeMeta] tô `chiliDeep` đậm cho "Thiếu: hành lá".
class RecipeRow extends StatelessWidget {
  const RecipeRow({
    super.key,
    required this.title,
    this.meta,
    this.emphasizeMeta = false,
    this.imageAsset,
    this.thumbSize = 56,
    this.padding = const EdgeInsets.all(AppSpacing.s2),
    this.onTap,
  });

  final String title;
  final String? meta;
  final bool emphasizeMeta;
  final String? imageAsset;

  /// 56 ở Khám phá, 48 ở Tủ đồ, 44 trong bữa của Thực đơn.
  final double thumbSize;

  /// Đệm quanh ảnh và chữ; Thực đơn dùng 6/8 cho gọn.
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = this.meta;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: SizedBox.square(
                  dimension: thumbSize,
                  child: RecipeCover(imageAsset: imageAsset, aspectRatio: 1),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.button.copyWith(color: colors.ink),
                    ),
                    if (meta != null)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: emphasizeMeta
                            ? AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.chiliDeep,
                              )
                            : AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
