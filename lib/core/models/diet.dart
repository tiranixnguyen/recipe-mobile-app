/// Chế độ ăn / hạn chế — danh sách cố định theo màn Onboarding.
enum Diet {
  veg('veg', 'Ăn chay'),
  nospicy('nospicy', 'Không ăn cay'),
  noseafood('noseafood', 'Dị ứng hải sản'),
  nopork('nopork', 'Không ăn thịt lợn'),
  light('light', 'Ăn nhẹ buổi tối');

  const Diet(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static Diet fromId(String id) =>
      tryParse(id) ?? (throw FormatException('chế độ ăn "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static Diet? tryParse(String value) {
    for (final diet in values) {
      if (diet.id == value || diet.name == value) return diet;
    }
    return null;
  }
}
