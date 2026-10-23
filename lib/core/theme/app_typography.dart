import 'package:flutter/painting.dart';

abstract final class AppFonts {
  /// Font duy nhất của app, đã bundle trong `assets/fonts/` (400, 600, 700).
  static const sans = 'Be Vietnam Pro';
}

/// Kiểu chữ theo `type` trong `tokens.json` (cỡ/dòng/đậm), cộng vài kiểu riêng của component.
///
/// Không gắn màu: theme tô [AppColors.ink] qua `TextTheme`, widget tự `copyWith(color: …)` khi cần
/// `inkMuted`, `chiliDeep`…
abstract final class AppTextStyles {
  static const display = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const title = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const subtitle = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const body = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Dòng thời gian · khẩu phần · dụng cụ; thường tô `inkMuted`.
  static const meta = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Nhãn chip, badge, tab.
  static const label = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const caption = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Chữ bước nấu ở chế độ nấu (prototype `CookStep`), đọc được khi điện thoại dựng cạnh bếp.
  static const step = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 24,
    height: 34 / 24,
    fontWeight: FontWeight.w400,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Nhãn nút (component `Button`).
  static const button = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Nhãn nút `size="lg"` ở chế độ nấu.
  static const buttonLg = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Tên style trong `tokens.json` → style. Dùng cho test và trang xem theme.
  static const byToken = {
    'display': display,
    'title': title,
    'subtitle': subtitle,
    'body': body,
    'meta': meta,
    'label': label,
    'caption': caption,
  };
}
