import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/plan/domain/plan_labels.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Sheet "Chọn ngày" của Thực đơn (prototype `MealPlan`, nút lịch): lịch tháng bắt đầu Thứ Hai,
/// mở ở tháng của [selected]. Trả ngày được chọn (Hôm nay trả [today]), null khi đóng.
Future<DateTime?> showCalendarSheet(
  BuildContext context, {
  required DateTime selected,
  required DateTime today,
}) => showModalBottomSheet<DateTime>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => CalendarSheet(selected: selected, today: today),
);

class CalendarSheet extends StatefulWidget {
  const CalendarSheet({super.key, required this.selected, required this.today});

  final DateTime selected;
  final DateTime today;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  /// Tháng đang xem (ngày 1); chỉ là vị trí lật lịch, chưa chọn gì nên giữ trong sheet.
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  void _turn(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cells = monthGrid(_month.year, _month.month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s3,
        children: [
          Semantics(
            header: true,
            child: Text(
              PlanStrings.calendarTitle,
              style: AppTextStyles.title.copyWith(color: colors.ink),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _turn(-1),
                tooltip: PlanStrings.previousMonth,
                icon: const Icon(Symbols.chevron_left_rounded, size: 22),
                color: colors.ink,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    PlanStrings.monthLabel(_month.month, _month.year),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button.copyWith(color: colors.ink),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _turn(1),
                tooltip: PlanStrings.nextMonth,
                icon: const Icon(Symbols.chevron_right_rounded, size: 22),
                color: colors.ink,
              ),
            ],
          ),
          ExcludeSemantics(
            child: Row(
              spacing: AppSpacing.s1,
              children: [
                for (final name in weekdayShortNames)
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            spacing: AppSpacing.s1,
            children: [
              for (var row = 0; row < cells.length; row += 7)
                Row(
                  spacing: AppSpacing.s1,
                  children: [
                    for (final day in cells.sublist(row, row + 7))
                      Expanded(
                        child: _DayCell(
                          day: day,
                          inMonth: day.month == _month.month,
                          selected: day == addDays(widget.selected, 0),
                          isToday: day == addDays(widget.today, 0),
                          onTap: () => Navigator.of(context).pop(day),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                Expanded(
                  child: AppButton.ghost(
                    label: PlanStrings.today,
                    block: true,
                    onPressed: () => Navigator.of(context).pop(addDays(widget.today, 0)),
                  ),
                ),
                Expanded(
                  child: AppButton.secondary(
                    label: PlanStrings.close,
                    block: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô ngày cao 44: đang chọn nền `chili` chữ trắng, hôm nay viền `chili` 2px, ngày ngoài tháng chữ
/// `inkMuted`.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = [
      '${weekdayNames[weekdayIndex(day)]} ${dayMonth(day)}',
      if (isToday) 'hôm nay',
    ].join(', ');
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.chili : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: selected
              ? BorderSide(color: colors.chili)
              : isToday
              ? BorderSide(color: colors.chili, width: 2)
              : BorderSide.none,
          borderRadius: AppRadius.mdAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '${day.day}',
                style: AppTextStyles.button.copyWith(
                  // Chữ trắng trên nền `chili` như nút chính.
                  color: selected
                      ? Colors.white
                      : inMonth
                      ? colors.ink
                      : colors.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
