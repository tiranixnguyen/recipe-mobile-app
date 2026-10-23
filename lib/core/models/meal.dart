/// Bữa trong ngày — dùng cho thực đơn và gợi ý.
enum Meal {
  breakfast('breakfast', 'Sáng'),
  lunch('lunch', 'Trưa'),
  dinner('dinner', 'Tối');

  const Meal(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static Meal fromId(String id) => tryParse(id) ?? (throw FormatException('bữa "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static Meal? tryParse(String value) {
    for (final meal in values) {
      if (meal.id == value || meal.name == value) return meal;
    }
    return null;
  }
}
