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
  static const removeRecipe = 'Xoá khỏi bữa';

  static const addTitle = 'Thêm vào thực đơn';
  static const addDay = 'Ngày';
  static const addMeal = 'Bữa';
  static const addServings = 'Khẩu phần';
  static const addEmptyMeal = 'Trống';
  static const addTodayShort = 'Nay';
  static const addQuickGroup = 'Chọn nhanh';
  static const cancel = 'Huỷ';
  static String addConfirm(String when) => 'Thêm vào $when';
  static const addNotFound = 'Không tìm thấy món này.';
}
