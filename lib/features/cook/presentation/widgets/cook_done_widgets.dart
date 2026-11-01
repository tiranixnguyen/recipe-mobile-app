import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Đầu màn Hoàn thành: vòng tròn 88 `chiliSoft` có icon bát, "Xong rồi! Ăn ngon nhé", dòng meta.
class DoneHero extends StatelessWidget {
  const DoneHero({super.key, required this.meta, this.title = CookStrings.doneTitle});

  final String title;
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
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(color: colors.ink),
          ),
        ),
        Text(
          meta,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
        ),
      ],
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
