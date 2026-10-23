import 'package:flutter/painting.dart';

/// Bo góc theo token `radius-*` trong `tokens.json`.
abstract final class AppRadius {
  /// `radius-sm`: badge trạng thái (Đủ đồ, Thiếu…), ảnh thumbnail nhỏ.
  static const sm = 8.0;

  /// `radius-md`: thẻ công thức, nút, ô tìm kiếm, ô thực đơn.
  static const md = 12.0;

  /// `radius-pill`: chip lọc, viên tab đang mở.
  static const pill = 999.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const pillAll = BorderRadius.all(Radius.circular(pill));

  /// Tên token trong `tokens.json` → giá trị. Dùng cho test và trang xem theme.
  static const byToken = {'radius-sm': sm, 'radius-md': md, 'radius-pill': pill};
}
