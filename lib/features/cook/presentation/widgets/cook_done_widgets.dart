import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Đầu màn Hoàn thành: vòng tròn 88 `chiliSoft` có icon bát, "Xong rồi! Ăn ngon nhé", dòng meta.
class DoneHero extends StatelessWidget {
  const DoneHero({super.key, required this.meta});

  final String meta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      spacing: AppSpacing.s3,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(color: colors.chiliSoft, shape: BoxShape.circle),
          child: Icon(AppIcons.bowl, size: 44, color: colors.chili),
        ),
        Semantics(
          header: true,
          child: Text(
            CookStrings.doneTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(color: colors.ink),
          ),
        ),
        Text(
          meta,
          textAlign: TextAlign.center,
          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}

/// "Cập nhật Tủ đồ": mỗi đồ vừa dùng một dòng, tick "Hết" thì bỏ khỏi tủ.
class UpdatePantrySection extends StatelessWidget {
  const UpdatePantrySection({
    super.key,
    required this.items,
    required this.usedUp,
    required this.onToggle,
  });

  final List<UsedItem> items;
  final Set<String> usedUp;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        const SectionHeader(title: CookStrings.updatePantry),
        Text(
          CookStrings.updatePantryHint,
          style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w400, color: colors.inkMuted),
        ),
        RowsBox(
          rows: [
            for (final item in items)
              _UsedUpRow(
                item: item,
                checked: usedUp.contains(item.ingredientId),
                onChanged: () => onToggle(item.ingredientId),
              ),
          ],
        ),
      ],
    );
  }
}

class _UsedUpRow extends StatelessWidget {
  const _UsedUpRow({required this.item, required this.checked, required this.onChanged});

  final UsedItem item;
  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: CookStrings.usedUpLabel(item.name),
      child: InkWell(
        onTap: onChanged,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          item.note,
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  CookStrings.usedUp,
                  style: AppTextStyles.label.copyWith(color: colors.ink),
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon của từng đánh giá theo bộ icon design.
IconData ratingIcon(CookRating rating) => switch (rating) {
  CookRating.good => AppIcons.smile,
  CookRating.ok => AppIcons.meh,
  CookRating.bad => AppIcons.frown,
};

/// Ba nút Ngon / Tạm / Chê cao 64; nút đang chọn nền `chiliSoft`, chữ `chiliDeep`.
class RatingGrid extends StatelessWidget {
  const RatingGrid({super.key, required this.selected, required this.onSelect});

  final CookRating? selected;
  final ValueChanged<CookRating> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      label: CookStrings.rateGroup,
      child: Row(
        spacing: AppSpacing.s2,
        children: [
          for (final rating in CookRating.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: rating == selected,
                child: Material(
                  color: rating == selected ? colors.chiliSoft : colors.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll,
                    side: BorderSide(
                      color: rating == selected ? colors.chiliSoft : colors.outline,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelect(rating),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Icon(
                              ratingIcon(rating),
                              color: rating == selected ? colors.chiliDeep : colors.ink,
                            ),
                            Text(
                              rating.label,
                              style: AppTextStyles.button.copyWith(
                                color: rating == selected ? colors.chiliDeep : colors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
