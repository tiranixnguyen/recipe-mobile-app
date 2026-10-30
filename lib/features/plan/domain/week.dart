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

/// 0h của ngày cách [day] [days] ngày (âm là lùi), không lệch giờ khi đổi giờ mùa hè.
DateTime addDays(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

/// Các ô của lịch tháng [month] năm [year], bắt đầu từ Thứ Hai: đủ hàng 7 ngày, có ngày cuối tháng
/// trước và đầu tháng sau cho đầy hàng. Thường 5 hàng, 6 hàng chỉ khi tháng cần (như prototype).
List<DateTime> monthGrid(int year, int month) {
  final first = DateTime(year, month);
  final lead = weekdayIndex(first);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final cells = ((lead + daysInMonth) / 7).ceil() * 7;
  return [for (var i = 0; i < cells; i++) DateTime(year, month, 1 - lead + i)];
}

/// 7 ngày cuốn từ hôm nay ([now]) cho sheet Thêm vào thực đơn: ngày gần nhất trước.
List<DateTime> upcomingDays(DateTime now) => [for (var i = 0; i < 7; i++) addDays(now, i)];
