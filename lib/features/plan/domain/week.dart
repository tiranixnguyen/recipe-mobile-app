/// Ngày trong tuần tính theo chỉ số 0 = Thứ Hai … 6 = Chủ Nhật (như `DayStrip`).
library;

/// Chỉ số của [day] trong tuần.
int weekdayIndex(DateTime day) => day.weekday - DateTime.monday;

/// 0h Thứ Hai của tuần chứa [day].
DateTime weekStartOf(DateTime day) => DateTime(day.year, day.month, day.day - weekdayIndex(day));

/// 0h của ngày thứ [index] trong tuần bắt đầu từ [weekStart].
DateTime dayOfWeek(DateTime weekStart, int index) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + index);

/// Vị trí của [day] (0h) trong tuần bắt đầu từ [weekStart], null nếu ngoài tuần.
int? indexInWeek(DateTime weekStart, DateTime day) {
  for (var i = 0; i < 7; i++) {
    if (dayOfWeek(weekStart, i) == day) return i;
  }
  return null;
}
