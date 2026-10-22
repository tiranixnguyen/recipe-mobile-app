import 'package:flutter/material.dart';

/// 14 token màu của `docs/design/design-system/tokens.json`, gắn vào theme qua `ThemeData.extensions`.
///
/// Widget lấy bằng `context.colors.chiliSoft` (xem `theme.dart`). Giá trị phải khớp `tokens.json`;
/// `test/core/theme/tokens_test.dart` so từng token nên sync lại thiết kế mà lệch là test đỏ.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.outline,
    required this.chili,
    required this.chiliSoft,
    required this.chiliDeep,
    required this.herb,
    required this.herbInk,
    required this.herbSoft,
    required this.danger,
    required this.dangerInk,
  });

  static const light = AppColors(
    surface: Color(0xFFFFF8F1),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF2A1E16),
    inkMuted: Color(0xFF6E5D50),
    line: Color(0xFFEADFD3),
    outline: Color(0xFF958170),
    chili: Color(0xFFC2410C),
    chiliSoft: Color(0xFFFFE3CC),
    chiliDeep: Color(0xFF9A3412),
    herb: Color(0xFF2F7A3E),
    herbInk: Color(0xFF2F7A3E),
    herbSoft: Color(0xFFDDF0DF),
    danger: Color(0xFFB42318),
    dangerInk: Color(0xFFB42318),
  );

  static const dark = AppColors(
    surface: Color(0xFF1A1410),
    surfaceRaised: Color(0xFF26201A),
    ink: Color(0xFFF5EDE6),
    inkMuted: Color(0xFFBFAE9F),
    line: Color(0xFF3A3029),
    outline: Color(0xFF8C7A6B),
    chili: Color(0xFFC2410C),
    chiliSoft: Color(0xFF4A2513),
    chiliDeep: Color(0xFFFFB38A),
    herb: Color(0xFF2F7A3E),
    herbInk: Color(0xFF7FCB8F),
    herbSoft: Color(0xFF1F3A25),
    danger: Color(0xFFB42318),
    dangerInk: Color(0xFFFF8A80),
  );

  /// Nền trang. Sáng: kem ấm như giấy gói bánh mì. Tối: nâu than ấm, không đen tuyền.
  final Color surface;

  /// Nền thẻ công thức, ô tìm kiếm, bottom sheet nằm trên [surface].
  final Color surfaceRaised;

  /// Chữ chính trên [surface] và [surfaceRaised]. Cũng là nền thanh hẹn giờ, chữ trên đó dùng [surface].
  final Color ink;

  /// Chữ phụ: thời gian nấu, khẩu phần, dụng cụ, caption.
  final Color inkMuted;

  /// Đường kẻ và viền thẻ mảnh; chỉ trang trí, không dùng làm viền control.
  final Color line;

  /// Viền control: ô tìm kiếm, chip lọc chưa chọn, nút phụ, ô thực đơn trống (đạt 3:1 ở cả hai theme).
  final Color outline;

  /// Màu thương hiệu: nút chính, tab đang chọn, icon nhấn. Chữ trắng trên [chili] đạt 5.2:1.
  /// Trên nền tối chỉ dùng cho nền nút và icon; chữ màu thương hiệu dùng [chiliDeep].
  final Color chili;

  /// Nền chip đang chọn, viên tab đang mở, badge "Thiếu…"; chữ trên nó dùng [chiliDeep].
  final Color chiliSoft;

  /// Chữ và icon trên [chiliSoft], dòng "Thiếu: …", link; trạng thái nhấn của nút chính ở theme sáng.
  final Color chiliDeep;

  /// Có sẵn / nấu được ngay / thành công: nền badge "Đủ đồ", ô tick đã mua. Chữ trắng trên [herb]
  /// 5.3:1. Chữ màu xanh dùng [herbInk].
  final Color herb;

  /// Chữ mang nghĩa có sẵn trên [surface]/[surfaceRaised], ví dụ "Có trong tủ".
  final Color herbInk;

  /// Nền thông báo nhẹ mang nghĩa có sẵn, ví dụ "Đã bỏ 4 thứ có sẵn trong Tủ đồ"; chữ trên nó dùng [ink].
  final Color herbSoft;

  /// Chỉ cho hành động không hoàn tác được (Xoá hết): nền nút, chữ trắng 6.6:1. Không dùng trang trí.
  final Color danger;

  /// Chữ và icon cảnh báo trên [surface]/[surfaceRaised], ví dụ "Không khôi phục được".
  final Color dangerInk;

  /// Tên token trong `tokens.json` → màu, đúng thứ tự file thiết kế. Dùng cho test và trang xem theme.
  Map<String, Color> get byToken => {
    'surface': surface,
    'surface-raised': surfaceRaised,
    'ink': ink,
    'ink-muted': inkMuted,
    'line': line,
    'outline': outline,
    'chili': chili,
    'chili-soft': chiliSoft,
    'chili-deep': chiliDeep,
    'herb': herb,
    'herb-ink': herbInk,
    'herb-soft': herbSoft,
    'danger': danger,
    'danger-ink': dangerInk,
  };

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? outline,
    Color? chili,
    Color? chiliSoft,
    Color? chiliDeep,
    Color? herb,
    Color? herbInk,
    Color? herbSoft,
    Color? danger,
    Color? dangerInk,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
      outline: outline ?? this.outline,
      chili: chili ?? this.chili,
      chiliSoft: chiliSoft ?? this.chiliSoft,
      chiliDeep: chiliDeep ?? this.chiliDeep,
      herb: herb ?? this.herb,
      herbInk: herbInk ?? this.herbInk,
      herbSoft: herbSoft ?? this.herbSoft,
      danger: danger ?? this.danger,
      dangerInk: dangerInk ?? this.dangerInk,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      line: mix(line, other.line),
      outline: mix(outline, other.outline),
      chili: mix(chili, other.chili),
      chiliSoft: mix(chiliSoft, other.chiliSoft),
      chiliDeep: mix(chiliDeep, other.chiliDeep),
      herb: mix(herb, other.herb),
      herbInk: mix(herbInk, other.herbInk),
      herbSoft: mix(herbSoft, other.herbSoft),
      danger: mix(danger, other.danger),
      dangerInk: mix(dangerInk, other.dangerInk),
    );
  }
}
