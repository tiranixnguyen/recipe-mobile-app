/// Khoảng cách theo lưới 4px.
///
/// [s1], [s2], [s4], [s6] là token `space-N` trong `tokens.json`: lề màn hai bên và padding thẻ là
/// [s4], giữa các section là [s6]. Số còn lại là bội 4 mà prototype dùng nhiều (12px gặp ~80 lần).
abstract final class AppSpacing {
  /// `space-1`: icon với chữ trong dòng meta, chip, tab.
  static const s1 = 4.0;

  /// `space-2`: giữa các chip lọc, padding badge.
  static const s2 = 8.0;

  static const s3 = 12.0;

  /// `space-4`: lề màn hình hai bên, padding thẻ công thức.
  static const s4 = 16.0;

  static const s5 = 20.0;

  /// `space-6`: giữa các section trên màn hình.
  static const s6 = 24.0;

  static const s8 = 32.0;

  /// Tên token trong `tokens.json` → giá trị. Dùng cho test và trang xem theme.
  static const byToken = {'space-1': s1, 'space-2': s2, 'space-4': s4, 'space-6': s6};
}
