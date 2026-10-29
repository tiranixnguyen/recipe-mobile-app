abstract final class PantryStrings {
  static const title = 'Tủ đồ';
  static String summary(int have, int needed) => 'Có $have thứ · $needed thứ đang cần mua';

  static const searchPlaceholder = 'Tìm nguyên liệu hoặc nhóm…';
  static const searchLabel = 'Tìm nguyên liệu hoặc nhóm';
  static const clearQuery = 'Xoá từ khoá';

  static const filterAll = 'Tất cả';
  static String filterHave(int count) => 'Đang có ($count)';
  static String filterNeeded(int count) => 'Cần mua ($count)';

  static String groupCount(int have, int needed) => 'đang có $have, cần mua $needed';

  static String chipHave(String name) => '$name, có trong tủ';
  static String chipNeeded(String name) => '$name, đang cần mua';
  static String chipNone(String name) => '$name, chưa có';
  static const addToShoppingAction = 'Thêm vào đi chợ';

  static String noMatch(String query) => 'Chưa có "$query" trong danh sách.';
  static String addQuery(String query) => '+ Thêm "$query" vào đi chợ';
  static const emptyFilter = 'Chưa có nguyên liệu nào ở mục này.';

  static String added(String name) => 'Đã thêm ${name.toLowerCase()} vào đi chợ';
  static String alreadyInShopping(String name) => '$name đã có trong đi chợ';
  static String inPantry(String name) => '$name đang có trong tủ';
  static const undo = 'Hoàn tác';
  static const see = 'Xem';

  static const dropHint = 'Thả vào đây để thêm vào đi chợ';
  static const dragTip = 'Nhấn giữ một nguyên liệu rồi kéo thả vào giỏ để thêm vào đi chợ.';

  static const loadError = 'Không đọc được danh sách nguyên liệu. Thử mở lại app.';
}
