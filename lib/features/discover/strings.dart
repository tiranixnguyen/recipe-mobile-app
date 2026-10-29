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
