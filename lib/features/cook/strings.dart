abstract final class CookStrings {
  static const detail = 'Chi tiết món';
  static const prep = 'Chuẩn bị nấu';
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

  // Nấu từng bước (`CookStep`).
  static const exitCooking = 'Thoát chế độ nấu';
  static String stepOf(int step, int total) => 'Bước $step/$total';
  static String stepLabel(int step) => 'BƯỚC $step';
  static String timerLabel(int step) => 'Bước $step';
  static const keepScreenOn = 'Màn hình luôn sáng khi đang nấu';
  static const previousStep = 'Bước trước';
  static const nextStep = 'Bước tiếp';
  static const finish = 'Xong';
  static String sheetTitle(int servings) => 'Nguyên liệu · $servings người';
  static const close = 'Đóng';
  static const enough = 'Vừa đủ';
  static const timers = 'Hẹn giờ';

  // Hoàn thành (`CookDone`).
  static const doneTitle = 'Xong rồi! Ăn ngon nhé';
  static String doneMeta(String name, int servings, int steps) =>
      '$name · $servings người · $steps bước';
  static const updatePantry = 'Cập nhật Tủ đồ';
  static const updatePantryHint = 'Tick thứ đã dùng hết, app sẽ bỏ khỏi tủ. Còn dư thì bỏ tick.';
  static const usedUp = 'Hết';
  static String usedUpLabel(String name) => '$name: đã dùng hết';
  static const howWasIt = 'Món này thế nào?';
  static const rateGroup = 'Đánh giá món';
  static const saveForLater = 'Lưu món để nấu lại';
  static const saved = 'Đã lưu món';
  static const demotedNote = 'Món này sẽ tạm lùi trong gợi ý 3 ngày tới.';
  static const finishAndUpdate = 'Cập nhật tủ và xong';

  // Thanh "Đang nấu dở" ở Khám phá.
  static const resumeTitle = 'Đang nấu dở';
  static String resumeStep(String name, int step, int total) => '$name · bước $step/$total';
  static const resumeAction = 'Nấu tiếp';
}
