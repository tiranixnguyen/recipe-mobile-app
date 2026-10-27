import 'package:recipe_mobile_app/core/models/models.dart';

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

  // Sheet hỏi lại khi "Lấy đồ ra" chưa tick đủ (Chuẩn bị một món và cả bữa).
  static const gatherConfirmTitle = 'Chưa lấy đủ đồ';
  static String gatherConfirmBody(int done, int total) =>
      'Bạn mới lấy $done/$total thứ. Thiếu gì thì lấy nốt, đủ rồi thì cứ bắt đầu.';
  static const confirmStartCooking = 'Vẫn bắt đầu nấu';
  static const confirmStartPrep = 'Vẫn bắt đầu sơ chế';
  static const gatherConfirmBack = 'Lấy tiếp';

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

  // Nấu cả bữa (`MealCookPrep`, `MealCookStep`, `MealCookDone`).
  static String mealTitle(Meal meal) => 'Nấu bữa ${meal.label.toLowerCase()}';
  static String mealMeta(String dayName, int dishes, int minutes, String? tool) =>
      [dayName, '$dishes món', 'khoảng $minutes phút', ?tool].join(' · ');
  static String mealPrepMeta(String dayName, int dishes, int prepMinutes, int cookMinutes) =>
      '$dayName · $dishes món · sơ chế ~$prepMinutes phút, nấu ~$cookMinutes phút';
  static const backToPlan = 'Quay lại thực đơn';
  static const cookOrder = 'Thứ tự nấu';
  static const cookOrderHint = 'Giữ và kéo để đổi thứ tự';
  static const useSuggestedOrder = 'Dùng thứ tự gợi ý';
  static String reorderLabel(String name, int position) =>
      'Đổi thứ tự $name, đang ở vị trí $position. Dùng phím mũi tên lên xuống';
  static String movedTo(String name, int position) => '$name lên vị trí $position';
  static const mealServingsHint = 'Áp dụng cho cả bữa';
  static const mealGather = 'Lấy đồ ra · cả bữa';
  static String dishesTag(int count) => '$count món';
  static String startFirst(String name) => 'Bắt đầu: $name';
  static const startPrep = 'Bắt đầu sơ chế';
  static String mealStepTitle(Meal meal, int dish, int total) =>
      'Bữa ${meal.label.toLowerCase()} · món $dish/$total';
  static const mealDishes = 'Món trong bữa';
  static String dishTab(int number, String name) => '$number. $name';
  static String dishSteps(int total) => '$total bước';
  static String mealStepLabel(String name, int step, int total) =>
      '${name.toUpperCase()} · BƯỚC $step/$total';
  static String mealTimerLabel(String name, int step) => '$name · Bước $step';
  static String finishDish(int number) => 'Xong món $number';

  // Chặng "Sơ chế cả bữa" đầu `MealCookStep`.
  static String mealPrepStageTitle(Meal meal) => 'Bữa ${meal.label.toLowerCase()} · sơ chế';
  static const prepTab = 'Sơ chế';
  static String prepProgress(int done, int total) => '$done/$total việc';
  static String prepStageLabel(int minutes) => 'SƠ CHẾ CẢ BỮA · ~$minutes PHÚT';
  static const prepStageLabelNoTime = 'SƠ CHẾ CẢ BỮA';
  static const prepTipLead = 'Mẹo:';
  static const prepTip = ' Sơ chế sẵn mọi thứ tại đây để lúc đứng bếp chỉ việc nấu liền một mạch.';
  static const prepSkipHint = 'Đã sơ chế từ trước? Bấm nút bên dưới để vào nấu luôn.';
  static String prepShare(String amountText) => '~$amountText';
  static String prepTaskLabel(String ingredient, String action) =>
      action.isEmpty ? ingredient : '$ingredient: $action';
  static const finishPrep = 'Xong sơ chế';
  static const finishMeal = 'Xong cả bữa';

  // Sheet hỏi lại khi "Xong sơ chế" chưa tick đủ, "Xong cả bữa" còn món chưa xong.
  static const prepConfirmTitle = 'Chưa sơ chế xong';
  static String prepConfirmBody(int done, int total) =>
      'Bạn mới xong $done/$total việc.\nĐồng ý thì các việc còn lại tự động được đánh dấu và bắt đầu nấu món đầu tiên.';
  static const keepPrepping = 'Làm tiếp';
  static const mealConfirmTitle = 'Còn món chưa xong';
  static String mealConfirmBody(List<String> names) {
    final shown = names.take(2).join(', ');
    final more = names.length > 2 ? ' và ${names.length - 2} món khác' : '';
    return 'Chưa xong: $shown$more. Bạn vẫn muốn kết thúc bữa?';
  }

  // Trang "Lưu ý cách dùng" sau bước cuối, chặng Lưu ý cuối bữa.
  static const notesTab = 'Lưu ý';
  static const notesTabHint = 'Cuối bữa';
  static const notesLabel = 'LƯU Ý CÁCH DÙNG';
  static const notesTitle = 'Lưu ý cách dùng';
  static String mealNotesStageTitle(Meal meal) => 'Bữa ${meal.label.toLowerCase()} · lưu ý';
  static const noNotes = 'Món ăn không có lưu ý nào.';

  /// Câu chúc cuối trang Lưu ý, chọn ngẫu nhiên mỗi lần mở màn nấu.
  static const cheers = [
    'Con mời cả nhà ăn!',
    'Thơm ngon mời bạn ăn nha!',
    'Thưởng thức ngay thôi nào!',
    'Nóng hổi vừa thổi vừa ăn!',
    'Xong rồi, ăn cho no nha!',
    'Tự nấu tự khen: ngon quá trời!',
    'Bày ra bàn thôi nào!',
    'Ăn ngon miệng nhé bạn!',
    'Bếp hôm nay đỉnh ghê!',
    'Ngồi xuống ăn thôi, mệt rồi!',
  ];

  static const confirmFinishMeal = 'Vẫn xong cả bữa';
  static const keepCooking = 'Nấu tiếp';
  static String mealSheetTitle(String name, int servings) =>
      'Nguyên liệu · $name · $servings người';
  static String mealDoneTitle(Meal meal) => 'Xong bữa ${meal.label.toLowerCase()}! Ăn ngon nhé';
  static String mealDoneMeta(int dishes, int servings, int minutes) =>
      '$dishes món · $servings người · khoảng $minutes phút';
  static const rateEach = 'Từng món thế nào?';
  static String ratedAs(String label) => 'Bạn chấm: $label';
  static const notRated = 'Chưa chấm';
  static String rateDish(String label, String name) => '$label · $name';
  static const mealUpdatePantry = 'Cập nhật Tủ đồ · cả bữa';
  static const mealUpdatePantryHint = 'Tick thứ đã dùng hết, app bỏ khỏi tủ một lần cho cả bữa.';
  static String mealMarked(Meal meal, String dayName) =>
      'Bữa ${meal.label.toLowerCase()} ${dayName.toLowerCase()} được đánh dấu đã nấu trong Thực đơn.';
  static const noMealTitle = 'Không có bữa đang nấu';
  static const noMealBody = 'Mở Thực đơn, chọn bữa có nhiều món rồi bấm Nấu bữa này.';
  static const mealNotFoundBody = 'Bữa này chưa có món nào trong Thực đơn.';
  static const toPlan = 'Mở Thực đơn';

  // Thanh "Đang nấu dở" ở Khám phá.
  static const resumeTitle = 'Đang nấu dở';
  static String resumeStep(String name, int step, int total) => '$name · bước $step/$total';
  static String resumeNotes(String name) => '$name · lưu ý';
  static const resumeAction = 'Nấu tiếp';
}
