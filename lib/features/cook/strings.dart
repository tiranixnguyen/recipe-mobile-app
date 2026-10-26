abstract final class CookStrings {
  static const detail = 'Chi tiết món';
  static const prep = 'Chuẩn bị nấu';
  static const cookStep = 'Nấu từng bước';
  static const cookDone = 'Nấu xong';
  static const back = 'Quay lại';
  static const ingredients = 'Nguyên liệu';
  static String steps(int count) => 'Cách làm · $count bước';
  static const inPantry = 'Có trong tủ';
  static const missing = 'Thiếu';
  static const optional = 'Tuỳ chọn';
  static const basicSpices = 'Gia vị cơ bản';
  static const addToPlan = 'Thêm vào thực đơn';
  static const startCooking = 'Bắt đầu nấu';
  static const notFoundTitle = 'Không tìm thấy món này';
  static const notFoundBody = 'Món có thể đã bị bỏ khỏi app. Xem món khác ở Khám phá.';
  static const notFoundAction = 'Về Khám phá';
  static const loadError = 'Không đọc được danh sách món. Thử mở lại app.';

  // Chuẩn bị nấu (`CookPrep`).
  static const prepTitle = 'Chuẩn bị';
  static const backToDetail = 'Quay lại chi tiết món';
  static const servings = 'Khẩu phần';
  static const servingsHint = 'Nguyên liệu tự nhân theo';
  static String timeAndSteps(int minutes, int steps) => '$minutes phút · $steps bước';
  static const gather = 'Lấy đồ ra';
  static String gathered(int done, int total) => 'Đã lấy $done/$total';
  static const addToShopping = 'Thêm vào đi chợ';
}
