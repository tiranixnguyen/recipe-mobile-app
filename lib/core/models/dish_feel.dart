/// Cảm giác của món, khớp lựa chọn "Cảm giác" ở prototype `TodayPrefs`. Món bình thường không gắn.
enum DishFeel {
  /// Hợp trời nóng: canh, món luộc, ít dầu mỡ.
  cooling('cooling', 'Giải nhiệt'),

  /// Hợp trời lạnh: cháo, món hấp, canh nóng, đậm đà.
  warming('warming', 'Ấm bụng');

  const DishFeel(this.id, this.label);

  final String id;
  final String label;

  /// Cảm giác ngược lại: bữa "Giải nhiệt" không chọn món "Ấm bụng" và ngược lại.
  DishFeel get opposite => this == cooling ? warming : cooling;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static DishFeel fromId(String id) =>
      tryParse(id) ?? (throw FormatException('cảm giác "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static DishFeel? tryParse(String value) {
    for (final feel in values) {
      if (feel.id == value || feel.name == value) return feel;
    }
    return null;
  }
}
