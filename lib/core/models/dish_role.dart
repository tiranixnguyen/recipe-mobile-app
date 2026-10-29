/// Vai của món trong một bữa, để ghép "Cơm nhà 2 món", "Mâm cơm" (prototype `TodayPrefs`, `Today`).
enum DishRole {
  /// Món mặn ăn với cơm: trứng chiên, đậu phụ sốt, thịt băm xào.
  main('main', 'Món mặn'),

  /// Canh ăn kèm cơm.
  soup('soup', 'Canh'),

  /// Rau, món thêm nhỏ ăn kèm.
  side('side', 'Rau/món thêm'),

  /// Món ăn riêng một mình là đủ bữa: mì, cháo, cơm rang, bánh mì ("1 món gọn lẹ").
  single('single', 'Món một mình');

  const DishRole(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static DishRole fromId(String id) =>
      tryParse(id) ?? (throw FormatException('vai món "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static DishRole? tryParse(String value) {
    for (final role in values) {
      if (role.id == value || role.name == value) return role;
    }
    return null;
  }
}
