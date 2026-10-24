abstract final class PlanStrings {
  static const title = 'Thực đơn';
  static const shopping = 'Đi chợ';
  static String plannedCount(int count, int total) => 'Đã lên $count/$total bữa';
  static const today = 'Hôm nay';
  static const loadError = 'Không đọc được danh sách món. Thử mở lại app.';

  static String pickTitle(String meal) => 'Chọn món bữa ${meal.toLowerCase()}';
  static const pickSearch = 'Tìm món';
  static const pickSaved = 'Đã lưu';
  static const pickAll = 'Tất cả món';
  static const pickEmpty = 'Không thấy món nào. Thử từ khác.';

  static const viewRecipe = 'Xem món';
  static const changeRecipe = 'Đổi món';
  static const removeRecipe = 'Xoá khỏi bữa';
}
