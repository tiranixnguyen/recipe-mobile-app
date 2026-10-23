/// Nhóm nguyên liệu trong Tủ đồ — dùng để gom chip theo nhóm.
enum IngredientGroup {
  protein('protein', 'Đạm'),
  vegetable('vegetable', 'Rau củ'),
  starch('starch', 'Tinh bột'),
  spice('spice', 'Gia vị'),
  other('other', 'Khác');

  const IngredientGroup(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static IngredientGroup fromId(String id) =>
      tryParse(id) ?? (throw FormatException('nhóm nguyên liệu "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static IngredientGroup? tryParse(String value) {
    for (final group in values) {
      if (group.id == value || group.name == value) return group;
    }
    return null;
  }
}
