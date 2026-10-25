import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';

/// Một món trong [MealSlot].
@immutable
class MealSlotDish {
  const MealSlotDish({required this.title, this.meta, this.imageAsset});

  final String title;

  /// Ví dụ "15 phút · Bếp từ".
  final String? meta;
  final String? imageAsset;
}

/// Một bữa trong Thực đơn, theo prototype `MealPlan` (design system chưa có component này). Một
/// bữa có thể nhiều món (cơm + canh + mặn).
///
/// - [MealSlot]: dòng nhãn "Sáng" hoặc "Sáng · 2 món" (12/16 600 `inkMuted`), có món thì thêm
///   link "+ Thêm món" `chiliDeep` bên phải; mỗi món một [RecipeRow] ảnh 44. Bữa trống: ô viền
///   đứt 1.5px `outline` cao 58, "+ Thêm món".
/// - [MealSlot.compact]: ô cao 56 trong lưới Tuần, "Tên món đầu +N"; trống thì ô viền đứt "+".
class MealSlot extends StatelessWidget {
  const MealSlot({
    super.key,
    required String this.label,
    required this.dishes,
    required VoidCallback this.onAdd,
    this.onDishTap,
  }) : titles = const [],
       onTap = null;

  const MealSlot.compact({super.key, required this.titles, required VoidCallback this.onTap})
    : label = null,
      dishes = const [],
      onAdd = null,
      onDishTap = null;

  /// Tên bữa ("Sáng", "Trưa", "Tối"); null ở [MealSlot.compact].
  final String? label;
  final List<MealSlotDish> dishes;
  final VoidCallback? onAdd;

  /// Bấm món thứ i trong [dishes].
  final ValueChanged<int>? onDishTap;

  /// Tên các món ở [MealSlot.compact].
  final List<String> titles;
  final VoidCallback? onTap;

  static const addLabel = 'Thêm món';

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return label == null ? _buildCompact(context) : _buildFull(context, label);
  }

  Widget _buildFull(BuildContext context, String label) {
    final colors = context.colors;
    final onAdd = this.onAdd!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        // Cao 24 như prototype; có link "+ Thêm món" thì 48 cho đủ vùng chạm.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dishes.length > 1 ? '$label · ${dishes.length} món' : label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.inkMuted,
                  ),
                ),
              ),
              if (dishes.isNotEmpty)
                Semantics(
                  button: true,
                  label: '$addLabel bữa ${label.toLowerCase()}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: AppRadius.smAll,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '+ $addLabel',
                            style: AppTextStyles.label.copyWith(color: colors.chiliDeep),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final (i, dish) in dishes.indexed)
          RecipeRow(
            title: dish.title,
            meta: dish.meta,
            imageAsset: dish.imageAsset,
            thumbSize: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 6),
            onTap: onDishTap == null ? null : () => onDishTap!(i),
          ),
        if (dishes.isEmpty)
          _Dashed(
            radius: AppRadius.mdAll,
            onTap: onAdd,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.s2,
                children: [
                  Icon(AppIcons.plus, size: 20, color: colors.ink),
                  Text(addLabel, style: AppTextStyles.button.copyWith(color: colors.ink)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    final colors = context.colors;
    if (titles.isEmpty) {
      return _Dashed(
        radius: AppRadius.smAll,
        onTap: onTap,
        semanticLabel: addLabel,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              '+',
              style: AppTextStyles.body.copyWith(fontSize: 16, color: colors.inkMuted),
            ),
          ),
        ),
      );
    }
    final more = titles.length - 1;
    return Semantics(
      button: true,
      label: titles.join(', '),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.line),
          borderRadius: AppRadius.smAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 6),
              // "+N" nằm ngoài phần cắt chữ để luôn thấy món còn lại.
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      titles.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: colors.ink),
                    ),
                  ),
                  if (more > 0)
                    Text(' +$more', style: AppTextStyles.caption.copyWith(color: colors.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô bấm được viền đứt 1.5px `outline`.
class _Dashed extends StatelessWidget {
  const _Dashed({
    required this.radius,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final BorderRadius radius;
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: context.colors.outline, radius: radius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, borderRadius: radius, child: child),
        ),
      ),
    );
  }
}

/// Viền đứt bo góc (Flutter không có `border-style: dashed`).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  static const strokeWidth = 1.5;
  static const dash = 6.0;
  static const gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(radius.toRRect(rect));
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
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
