import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/serving_stepper.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Header của chế độ nấu: nút tròn 48 bên trái, tiêu đề và dòng phụ.
class CookHeader extends StatelessWidget {
  const CookHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.subtitleMaxLines = 2,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Dòng phụ là tên món (Chuẩn bị một món) thì 1 dòng.
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s1, AppSpacing.s2, AppSpacing.s4, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          spacing: AppSpacing.s1,
          children: [
            IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: Icon(icon, color: colors.ink),
              style: IconButton.styleFrom(minimumSize: const Size.square(48)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: AppTextStyles.title.copyWith(color: colors.ink)),
                  ),
                  Text(
                    subtitle,
                    maxLines: subtitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung "Khẩu phần · Nguyên liệu tự nhân theo" với `ServingStepper` 1–6.
class ServingsBox extends StatelessWidget {
  const ServingsBox({super.key, required this.value, required this.onChanged, this.hint});

  final int value;
  final ValueChanged<int> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s3,
          AppSpacing.s3,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.s2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CookStrings.servings,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                Text(
                  hint ?? CookStrings.servingsHint,
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
            ServingStepper(
              value: value,
              min: minCookServings,
              max: maxCookServings,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Viên thông tin "15 phút · 4 bước", "Bếp từ": nền `surfaceRaised`, viền `line`, chữ `inkMuted`.
class CookInfoChip extends StatelessWidget {
  const CookInfoChip({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s1,
          children: [
            if (icon != null) Icon(icon, size: 16, color: colors.inkMuted),
            Flexible(
              child: Text(text, style: AppTextStyles.meta.copyWith(color: colors.inkMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề section 17/24, bên phải chữ phụ như "Đã lấy 1/4".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trailing = this.trailing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.s2,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.subtitle.copyWith(color: colors.ink)),
          ),
        ),
        if (trailing != null)
          Text(trailing, style: AppTextStyles.meta.copyWith(color: colors.inkMuted)),
      ],
    );
  }
}

/// Khung `surfaceRaised` viền `line`, các dòng ngăn bằng đường `line`.
class RowsBox extends StatelessWidget {
  const RowsBox({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        child: Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
              row,
            ],
          ],
        ),
      ),
    );
  }
}

/// Dòng checklist cao tối thiểu 56: ô tick, tên (gạch ngang khi đã tick), trạng thái bên phải.
class GatherRow extends StatelessWidget {
  const GatherRow({
    super.key,
    required this.label,
    required this.status,
    required this.checked,
    required this.onChanged,
    this.muted = false,
  });

  final String label;
  final String status;
  final bool checked;
  final VoidCallback onChanged;

  /// Dòng gia vị cơ bản: trạng thái chữ `inkMuted`.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: checked,
                  onChanged: (_) => onChanged(),
                  activeColor: colors.herb,
                  side: BorderSide(color: colors.outline, width: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: checked ? colors.inkMuted : colors.ink,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: colors.inkMuted,
                    ),
                  ),
                ),
              ),
              Text(
                status,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                  color: muted ? colors.inkMuted : colors.herbInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng "Lấy đồ ra · cả bữa" hai tầng: ô tick, tên nguyên liệu (tối đa 2 dòng) và tổng lượng căn
/// phải; dưới là tag tên đầy đủ từng món dùng tới, tự xuống dòng. Tick thì tên gạch ngang, lượng
/// chuyển `inkMuted`.
class MealGatherRow extends StatelessWidget {
  const MealGatherRow({
    super.key,
    required this.name,
    required this.amount,
    required this.checked,
    required this.onChanged,
    this.dishes = const [],
  });

  final String name;
  final String amount;
  final bool checked;
  final VoidCallback onChanged;
  final List<String> dishes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strong = AppTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                Row(
                  spacing: AppSpacing.s3,
                  children: [
                    SizedBox.square(
                      dimension: 24,
                      child: Checkbox(
                        value: checked,
                        onChanged: (_) => onChanged(),
                        activeColor: colors.herb,
                        side: BorderSide(color: colors.outline, width: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: strong.copyWith(
                          color: checked ? colors.inkMuted : colors.ink,
                          decoration: checked ? TextDecoration.lineThrough : null,
                          decorationColor: colors.inkMuted,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: strong.copyWith(color: checked ? colors.inkMuted : colors.ink),
                    ),
                  ],
                ),
                if (dishes.isNotEmpty)
                  Padding(
                    // Thẳng hàng với tên: ô tick 24 + khoảng 12.
                    padding: const EdgeInsets.only(left: 36),
                    child: Wrap(
                      spacing: AppSpacing.s1,
                      runSpacing: AppSpacing.s1,
                      children: [for (final dish in dishes) DishTag(text: dish)],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tag tên món (hoặc phần lượng "~2 tép") dưới một dòng nguyên liệu: nền `surface`, viền `line`,
/// chữ `inkMuted` 12/16 đậm 600; tên dài tự xuống dòng trong tag.
class DishTag extends StatelessWidget {
  const DishTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 1),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Khung đồ còn thiếu: badge "Thiếu: …", ghi chú thay thế, link "Thêm vào đi chợ".
class MissingBox extends StatelessWidget {
  const MissingBox({
    super.key,
    required this.missing,
    required this.notes,
    required this.onAddToShopping,
  });

  final List<String> missing;
  final List<String> notes;
  final VoidCallback onAddToShopping;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s2,
          children: [
            AvailabilityBadge(missing: missing),
            for (final note in notes)
              Text(
                note,
                style: AppTextStyles.meta.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colors.ink,
                ),
              ),
            TextButton(
              onPressed: onAddToShopping,
              style: TextButton.styleFrom(
                foregroundColor: colors.chiliDeep,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTextStyles.label,
              ),
              child: const Text(CookStrings.addToShopping),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer `surfaceRaised` viền trên `line`, padding 12/16/24 như prototype.
class CookFooter extends StatelessWidget {
  const CookFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s6,
          ),
          child: child,
        ),
      ),
    );
  }
}
