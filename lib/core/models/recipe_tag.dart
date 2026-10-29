/// Tiêu chí thêm của món, khớp nhóm "Tiết kiệm", "Khẩu vị", "Dịp" ở prototype `TodayPrefs`.
///
/// App không có giá: [cheap] là tag cho món rẻ, tận dụng đồ sẵn có, không phải mức ngân sách.
enum RecipeTag {
  /// Món rẻ, tận dụng đồ sẵn có ("Hệ cuối tháng"): trứng, mì, rau, đậu phụ.
  cheap('cheap', 'Tiết kiệm'),

  /// Ít dầu mỡ, nhiều rau ("Healthy · Eat clean").
  healthy('healthy', 'Healthy'),

  /// Thanh đạm, món chay. Chỉ gắn khi `diets` của món có `veg`.
  veg('veg', 'Thanh đạm'),

  /// Dịu nhẹ, không cay, dễ ăn.
  mild('mild', 'Dịu nhẹ'),

  /// Ăn chơi, lai rai ("Mồi bén").
  snack('snack', 'Mồi bén'),

  /// Nấu đãi bạn, cuối tuần.
  party('party', 'Đãi bạn');

  const RecipeTag(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static RecipeTag fromId(String id) =>
      tryParse(id) ?? (throw FormatException('tag "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static RecipeTag? tryParse(String value) {
    for (final tag in values) {
      if (tag.id == value || tag.name == value) return tag;
    }
    return null;
  }
}
