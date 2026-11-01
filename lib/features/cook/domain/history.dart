import 'package:recipe_mobile_app/core/models/models.dart';

/// Ghi chú món và ghi chú bữa tối đa chừng này ký tự (ô nhập đếm "/300").
const maxCookNote = 300;

/// Cắt khoảng trắng hai đầu và giới hạn [maxCookNote] ký tự.
String trimCookNote(String note) {
  final trimmed = note.trim();
  return trimmed.length <= maxCookNote ? trimmed : trimmed.substring(0, maxCookNote);
}

/// Bữa theo giờ nấu xong (nấu một món không gắn bữa trong Thực đơn): trước 10h sáng, trước 15h
/// trưa, còn lại tối.
Meal mealAt(DateTime at) => at.hour < 10
    ? Meal.breakfast
    : at.hour < 15
    ? Meal.lunch
    : Meal.dinner;

/// Id lần nấu [recipeId] lúc [at], tránh trùng [existingIds]. Đồng hồ cố định (test, hoặc nấu lại
/// trong cùng mili giây) vẫn ra id riêng, không đè lên lần nấu trước.
String uniqueHistoryId(String recipeId, DateTime at, Iterable<String> existingIds) {
  final ids = existingIds.toSet();
  final base = '${recipeId}_${at.microsecondsSinceEpoch}';
  if (!ids.contains(base)) return base;
  var i = 2;
  while (ids.contains('${base}_$i')) {
    i++;
  }
  return '${base}_$i';
}

/// Nhóm ở màn Lịch sử, theo thứ tự hiển thị.
enum HistoryGroup { today, yesterday, thisWeek, earlier }

/// Nhóm của lần nấu lúc [at] so với [now]: "Tuần này" là 2–6 ngày trước. Ngày trong tương lai
/// (đồng hồ máy bị chỉnh) tính là hôm nay.
HistoryGroup historyGroupOf(DateTime at, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days <= 0) return HistoryGroup.today;
  if (days == 1) return HistoryGroup.yesterday;
  if (days < 7) return HistoryGroup.thisWeek;
  return HistoryGroup.earlier;
}

const _marks = <String, String>{
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

final _plain = {
  for (final MapEntry(:key, :value) in _marks.entries)
    for (final char in value.split('')) char: key,
};

/// Chữ thường, bỏ dấu tiếng Việt: "Đậu PHỤ" → "dau phu".
String foldVietnamese(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final char in lower.split('')) {
    out.write(_plain[char] ?? char);
  }
  return out.toString();
}
