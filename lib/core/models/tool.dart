/// Dụng cụ trong phòng — danh sách cố định theo màn Onboarding.
enum Tool {
  rice('rice', 'Nồi cơm điện'),
  stove('stove', 'Bếp từ / bếp ga'),
  micro('micro', 'Lò vi sóng'),
  kettle('kettle', 'Ấm siêu tốc');

  const Tool(this.id, this.label);

  /// Khóa dùng trong JSON và `kitchenProfileProvider`.
  final String id;

  /// Nhãn hiển thị tiếng Việt.
  final String label;

  /// Đọc id từ dữ liệu đóng gói; id lạ là lỗi nhập liệu nên ném [FormatException].
  static Tool fromId(String id) =>
      tryParse(id) ?? (throw FormatException('dụng cụ "$id" không có'));

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static Tool? tryParse(String value) {
    for (final tool in values) {
      if (tool.id == value || tool.name == value) return tool;
    }
    return null;
  }
}
