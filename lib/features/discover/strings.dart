abstract final class DiscoverStrings {
  static const title = 'Khám phá';
  static const saved = 'Đã lưu';
  static const search = 'Tìm kiếm';
  static const today = 'Hôm nay ăn gì?';
  static const save = 'Lưu món';
  static const unsave = 'Bỏ lưu món';
  static const appName = 'Bếp Hoà Lạc';
  static const settings = 'Cài đặt';
  static const heroTitle = 'Hôm nay ăn gì?';
  static const heroBody = 'Gợi ý theo đồ trong tủ, bếp của bạn và bữa sắp tới.';
  static const heroAction = 'Gợi ý cho mình';
  static const suggestionBannerAria = 'Gợi ý hôm nay';
  static const viewDish = 'Xem món';
  static String cardSemanticLabel(int current, int total) => 'Thẻ $current trên $total';
  static const searchPlaceholder = 'Tìm món hoặc nguyên liệu';
  static const quickUnder15 = 'Dưới 15 phút';
  static const quickRiceCooker = 'Nồi cơm điện';
  static const quickVeg = 'Chay';
  static const quickDinner = 'Bữa tối';
  static const cookable = 'Nấu được với đồ bạn có';
  static const openPantry = 'Mở tủ đồ';
  static const cookableEmpty = 'Bật vài thứ bạn đang có trong Tủ đồ, app tìm món nấu được.';
  static const quick = 'Nhanh sau giờ học';
  static const loadError = 'Không đọc được danh sách món. Thử mở lại app.';
  static const savedEmptyTitle = 'Chưa lưu món nào';
  static const savedEmptyBody =
      'Bấm biểu tượng lưu trên món bạn thích. Món đã lưu được ưu tiên khi gợi ý và lên thực đơn.';
  static const savedEmptyAction = 'Tìm món để lưu';

  // Khám phá v2 (DSC-11)
  static String upcomingTitle(String meal) => 'Sắp tới bữa $meal rồi';
  static const viewPlan = 'Xem thực đơn';
  static const cookMeal = 'Nấu bữa này';
  static const cookDish = 'Nấu món này';
  static String upcomingEmpty(String meal) =>
      'Bữa $meal nay chưa có món. Thử mấy món nấu được với đồ bạn có:';
  static const addDish = '+ Thêm';
  static String addDishAria(String name, String meal) => 'Thêm $name vào bữa $meal';
  static const readyToCook = 'Nấu được ngay';
  static const nearMissing = 'Thiếu 1–2 thứ';
  static const addToShopping = '+ Đi chợ';
  static const addedToShopping = '✓ Đã thêm';
  static String addToShoppingAria(String name) => 'Thêm vào danh sách đi chợ: $name';
  static String addedToShoppingAria(String name) => 'Đã thêm $name vào danh sách đi chợ';
  static const shoppingTitle = 'Đi chợ';
  static const openShoppingList = 'Mở danh sách';
  static String shoppingNeedBuy(int count) => 'Còn $count thứ cần mua';
  static const shoppingEmpty = 'Danh sách đi chợ đang trống';
  static const shoppingEmptySub = 'Lấy đồ còn thiếu từ thực đơn tuần này';
  static const shoppingEmptyPrompt = 'Bấm để mở danh sách';
  static String addedToShoppingSnack(String name) => 'Đã thêm $name vào danh sách đi chợ';
  static String nearMissingPrefix(List<String> missing) => 'Thiếu: ${missing.join(', ')}';
  static String upcomingMeta(int count, int totalMinutes) => '$count món · ~$totalMinutes phút';

  // Hôm nay ăn gì
  static String mealLabel(String meal) => 'Bữa $meal';
  static String todaySubtitle(String meal) => 'Bữa $meal · theo tủ đồ và bếp của bạn';
  static const todayUnder30 = 'Dưới 30 phút';
  static const todayAnyTime = 'Thoải mái';
  static const todayEmpty = 'Chưa có món hợp bữa này. Bạn thử chọn thời gian khác.';
  static const todayDislike = 'Không thích';
  static const todayShuffle = 'Đổi món';
  static const todayReasonsPrompt = 'Vì sao không hợp? App sẽ nhớ.';
  static const todayAlternatives = 'Hoặc thử';
  static const todayCook = 'Nấu món này';
  static const todayHasAll = 'Bạn có đủ đồ';
  static String todayMissing(List<String> missing) => 'Thiếu ${missing.join(', ')}';
  static String todayReason(String stock, String meal) => '$stock · hợp bữa $meal';
  static String todayFitsMealOnly(String meal) => 'Hợp bữa $meal';
  static String minutes(int minutes) => '$minutes phút';
  // Tìm kiếm
  static const clearQuery = 'Xoá từ khoá';
  static String searchHas(String query) => 'có $query';
  static String searchUnder(int minutes) => 'dưới $minutes phút';
  static String searchUses(String tool) => 'dùng $tool';
  static String searchForMeal(String meal) => 'cho bữa $meal';
  static String searchFits(String diet) => 'hợp $diet';

  /// "3 món có trứng, dưới 15 phút"; không có điều kiện thì "3 món phù hợp".
  static String searchSummary(int count, List<String> parts) =>
      '$count món ${parts.isEmpty ? 'phù hợp' : parts.join(', ')}';

  /// Dòng meta của món: "15 phút · 1 người · Bếp từ".
  static String recipeMeta(int minutes, int servings, String? tool) =>
      ['$minutes phút', '$servings người', ?tool].join(' · ');
}
