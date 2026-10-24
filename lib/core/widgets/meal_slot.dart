import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';

/// Ô một bữa trong Thực đơn, theo prototype `MealPlan` (design system chưa có component này).
///
/// - Có món: ảnh 56, tên 15/22 600 và meta `inkMuted`, nền `surfaceRaised` viền `line`.
/// - Trống ([MealSlot.empty]): cao 72, viền đứt 1.5px `outline`, "+ Thêm món".
///
/// Nhãn bữa ("Sáng", "Trưa"…) phía trên do màn tự đặt.
class MealSlot extends StatelessWidget {
  const MealSlot({
    super.key,
    required String this.title,
    this.meta,
    this.imageAsset,
    required this.onTap,
  });

  const MealSlot.empty({super.key, required this.onTap})
    : title = null,
      meta = null,
      imageAsset = null;

  /// Tên món; null là ô trống.
  final String? title;

  /// Ví dụ "15 phút · Bếp từ".
  final String? meta;
  final String? imageAsset;
  final VoidCallback? onTap;

  static const emptyLabel = 'Thêm món';

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return title == null ? _buildEmpty(context) : _buildFilled(context, title);
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: colors.outline),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.s2,
                children: [
                  Icon(AppIcons.plus, size: 20, color: colors.ink),
                  Text(
                    emptyLabel,
                    style: AppTextStyles.button.copyWith(color: colors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilled(BuildContext context, String title) {
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
          padding: const EdgeInsets.all(AppSpacing.s2),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: SizedBox.square(
                  dimension: 56,
                  child: RecipeCover(imageAsset: imageAsset, aspectRatio: 1),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.button.copyWith(color: colors.ink),
                    ),
                    if (meta != null)
                      Text(meta, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),
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

/// Viền đứt bo `radius-md` (Flutter không có `border-style: dashed`).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const strokeWidth = 1.5;
  static const dash = 6.0;
  static const gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(AppRadius.mdAll.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
