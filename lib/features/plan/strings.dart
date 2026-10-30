import 'package:recipe_mobile_app/core/models/models.dart';

abstract final class PlanStrings {
  static const title = 'Thực đơn';
  static const shopping = 'Đi chợ';
  static const loadError = 'Không đọc được danh sách món. Thử mở lại app.';

  static const modeGroup = 'Chế độ xem';
  static const modeDay = 'Ngày';
  static const modeWeek = 'Tuần';
  static const weekComingSoon = 'Xem cả tuần sắp có. Tạm thời bạn xem từng ngày nhé.';
  static String calendarLabel(String title) => 'Chọn ngày, đang xem $title';
  static const previousDay = 'Ngày trước';
  static const nextDay = 'Ngày sau';
  static const previousWeek = 'Tuần trước';
  static const nextWeek = 'Tuần sau';

  static const suggestDay = 'Gợi ý cho ngày này';
  static const suggestMeal = 'Gợi ý món';
  static const suggestNone = 'Chưa có món hợp để gợi ý. Thử thêm đồ vào tủ.';
  static const addDish = 'Thêm món';
  static String openMeal(String meal, String summary) => '$meal: $summary. Mở bữa này';
  static String mealSection(Meal meal, String dayWord) => '${meal.label} $dayWord';
  static String emptyMeal(Meal meal, String dayWord) =>
      'Bữa ${meal.label.toLowerCase()} $dayWord còn trống. Thêm món bạn muốn ăn, hoặc để app gợi '
      'ý theo tủ đồ.';

  static const cookDish = 'Nấu món này';
  static const cookMeal = 'Nấu bữa này';
  static const cookedConfirmTitle = 'Đã nấu bữa này';
  static const confirmCookWhenCooked = 'Bạn đã nấu bữa này rồi. Tiếp tục nấu lại?';
  static const confirmCookLabel = 'Tiếp tục nấu';
  static const confirmAddWhenCooked = 'Bạn đã nấu bữa này rồi. Tiếp tục thêm món?';
  static const confirmAddLabel = 'Tiếp tục thêm';
  static String cookDishLabel(Meal meal, String name) =>
      'Nấu món ${meal.label.toLowerCase()}: $name';
  static String cookMealLabel(Meal meal, List<String> names) =>
      'Nấu cả bữa ${meal.label.toLowerCase()}: ${names.join(', ')}';
  static const cooked = 'Đã nấu';
  static String cookAgainLabel(Meal meal) => 'Đã nấu bữa ${meal.label.toLowerCase()}, nấu lại';

  static String dishMenu(String name) => 'Tuỳ chọn cho $name';
  static const swapDish = 'Đổi món';
  static const removeDish = 'Bỏ khỏi bữa';
  static String removed(String name, Meal meal) =>
      'Đã bỏ $name khỏi bữa ${meal.label.toLowerCase()}';
  static const undo = 'Hoàn tác';

  static const calendarTitle = 'Chọn ngày';
  static const previousMonth = 'Tháng trước';
  static const nextMonth = 'Tháng sau';
  static String monthLabel(int month, int year) => 'Tháng $month, $year';
  static const today = 'Hôm nay';
  static const close = 'Đóng';

  static String pickTitle(String meal) => 'Chọn món bữa ${meal.toLowerCase()}';
  static const pickSearch = 'Tìm món';
  static const pickSaved = 'Đã lưu';
  static const pickAll = 'Tất cả món';
  static const pickEmpty = 'Không thấy món nào. Thử từ khác.';

  static const addTitle = 'Thêm vào thực đơn';
  static const addDays = 'Các ngày tới';
  static const addMeal = 'Bữa';
  static const addServings = 'Khẩu phần';
  static const addEmptyMeal = 'Trống';
  static String addMealSubline(List<String> names) => '${names.join(' + ')} · ${names.length} món';
  static const cancel = 'Huỷ';
  static String addConfirm(String when) => 'Thêm vào $when';
  static const addNotFound = 'Không tìm thấy món này.';
}
