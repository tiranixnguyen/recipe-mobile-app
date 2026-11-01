/// Nhóm thời gian của Đã lưu, theo thứ tự hiển thị (như Lịch sử nấu).
enum SavedGroup { today, yesterday, thisWeek, earlier }

/// Nhóm theo ngày lịch của [at] so với [now]; không có giờ lưu (lưu từ bản cũ) thì [SavedGroup.earlier].
SavedGroup savedGroupOf(DateTime? at, DateTime now) {
  if (at == null) return SavedGroup.earlier;
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days <= 0) return SavedGroup.today;
  if (days == 1) return SavedGroup.yesterday;
  if (days < 7) return SavedGroup.thisWeek;
  return SavedGroup.earlier;
}
