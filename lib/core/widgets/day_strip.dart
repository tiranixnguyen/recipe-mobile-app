import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';

/// Dải 7 ngày T2…CN ở màn Thực đơn, theo prototype `MealPlan` (design system chưa có component này).
///
/// Ngày tính theo chỉ số 0 = Thứ Hai … 6 = Chủ Nhật (`DateTime.weekday - 1`). Ô đang chọn nền
/// `chili` chữ trắng; ngày đã có món có chấm `herb`; hôm nay (chưa chọn) chữ `chiliDeep`.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.today,
    this.daysWithMeals = const {},
  });

  final int selected;
  final ValueChanged<int> onSelected;

  /// Chỉ số hôm nay nếu tuần đang xem là tuần này.
  final int? today;
  final Set<int> daysWithMeals;

  static const shortNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const fullNames = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.s1,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              index: i,
              selected: i == selected,
              isToday: i == today,
              hasMeals: daysWithMeals.contains(i),
              onTap: () => onSelected(i),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.selected,
    required this.isToday,
    required this.hasMeals,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final bool isToday;
  final bool hasMeals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Chữ và chấm trắng trên nền `chili` như prototype.
    final foreground = selected
        ? Colors.white
        : isToday
        ? colors.chiliDeep
        : colors.ink;
    final dot = !hasMeals
        ? Colors.transparent
        : selected
        ? Colors.white
        : colors.herb;
    return Semantics(
      button: true,
      selected: selected,
      label: [DayStrip.fullNames[index], if (isToday) 'Hôm nay'].join(', '),
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.chili : colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? colors.chili : colors.line),
          borderRadius: AppRadius.mdAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Text(
                  DayStrip.shortNames[index],
                  style: AppTextStyles.label.copyWith(color: foreground),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  child: const SizedBox.square(dimension: 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
