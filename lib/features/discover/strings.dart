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
  static const searchPlaceholder = 'Tìm món';
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
      'Bấm biểu tượng lưu trên món bạn thích, hoặc Lưu lại cả bữa ở Hôm nay ăn gì.';
  static const savedEmptyAction = 'Tìm món để lưu';

  // Đã lưu v3: một danh sách món + bữa, nhóm theo thời gian như Lịch sử
  static String savedCount(int n) => '$n mục';
  static const savedSearchPlaceholder = 'Tìm trong đã lưu';
  static const savedSearchLabel = 'Tìm trong đã lưu';
  static const savedTrashHint = 'Kéo vào đây để bỏ lưu';
  static const savedTrashDanger = 'Thả để bỏ lưu';
  static String savedUnsaved(String name) => 'Đã bỏ lưu $name';
  static const savedUndo = 'Hoàn tác';
  static const savedUnsaveAction = 'Bỏ lưu';
  static String savedNoMatch(String q) => 'Không thấy "$q" trong đã lưu.';
  static const savedDragTipText = 'Nhấn giữ một mục rồi kéo vào thùng rác để bỏ lưu.';
  static const savedEmptyRecipesAction = 'Khám phá món';
  static const savedJustAdded = 'Mới thêm';
  static const savedGroupToday = 'Hôm nay';
  static const savedGroupYesterday = 'Hôm qua';
  static const savedGroupThisWeek = 'Tuần này';
  static const savedGroupEarlier = 'Trước đó';
  static String savedMealMeta(int dishes, int servings) => '$dishes món · $servings người';

  // Chi tiết bữa (`MealDetail`)
  static const savedMealTitle = 'Bữa của bạn';
  static const savedMealBackLabel = 'Quay lại Đã lưu';
  static const savedMealNotFound = 'Bữa này không còn trong Đã lưu';
  static const savedMealBack = 'Về Đã lưu';
  static const saveMeal = 'Lưu bữa';
  static const unsaveMeal = 'Bỏ lưu bữa';
  static String mealDetailMeta(int dishes, int minutes, String? tools) =>
      ['$dishes món', '~$minutes phút', ?tools].join(' · ');
  static String mealStatusMissing(int count) => 'Thiếu $count thứ';
  static String mealServingsTools(int servings, String? tools) =>
      ['$servings người', ?tools].join(' · ');
  static String mealDishesTitle(int count) => 'Các món trong bữa ($count)';
  static String dishRoleMeta(String role, int minutes) => '$role · $minutes phút';
  static String dishLinkLabel(String name, List<String> missing) =>
      '$name, ${missing.isEmpty ? 'đủ đồ' : 'thiếu ${missing.join(', ')}'}. Xem chi tiết món';
  static const swap = 'Đổi';
  static String swapLabel(String name) => 'Đổi $name';
  static String removeLabel(String name) => 'Bỏ $name khỏi bữa';
  static const mealAddDish = 'Thêm món';
  static const mealIngredients = 'Nguyên liệu cả bữa';
  static String mealServings(int servings) => '$servings người';
  static String missingTitle(int count) => 'Còn thiếu $count thứ';
  static const tagMissing = 'Thiếu';
  static const tagInShopping = 'Trong đi chợ';
  static String addMissing(int count) => 'Thêm $count thứ còn thiếu vào đi chợ';
  static const allMissingInShopping = 'Đã có hết trong đi chợ';
  static const haveTitle = 'Có trong tủ';
  static const optionalTitle = 'Tuỳ chọn';
  static const basicSpices = 'Gia vị cơ bản';
  static String dishAdded(String name) => 'Đã thêm ${name.toLowerCase()} vào bữa';
  static String dishRemoved(String name) => 'Đã bỏ ${name.toLowerCase()} khỏi bữa';
  static String dishSwapped(String from, String to) =>
      'Đã đổi ${from.toLowerCase()} thành ${to.toLowerCase()}';
  static String addedToShopping(int added, int skipped) =>
      'Đã thêm $added thứ vào đi chợ${skipped > 0 ? ', $skipped thứ đã có sẵn' : ''}';
  static const seeShopping = 'Xem';
  static const savedMealAddToPlan = 'Thêm vào thực đơn';
  static const startCooking = 'Bắt đầu nấu';

  // Sheet chọn món của Chi tiết bữa
  static const pickAddTitle = 'Thêm món vào bữa';
  static String pickSwapTitle(String name) => 'Đổi ${name.toLowerCase()} thành';
  static const pickClose = 'Đóng';
  static const pickSearch = 'Tìm món';
  static const pickFilterLabel = 'Lọc theo loại món';
  static const pickAll = 'Tất cả';
  static const pickGroupSaved = 'Món bạn đã lưu';
  static const pickGroupAll = 'Tất cả món';
  static const pickNone = 'Không thấy món nào khớp.';
  static const pickInMeal = 'Đã có trong bữa';
  static const pickReady = 'Đủ đồ';
  static String pickMissing(int count) => 'Thiếu $count';
  static String pickLabel(String name, bool inMeal, List<String> missing) =>
      name +
      (inMeal
          ? ', đã có trong bữa'
          : missing.isEmpty
          ? ', đủ đồ'
          : ', thiếu ${missing.join(', ')}');

  // Khám phá v2 (DSC-11)
  static String upcomingTitle(String meal) => 'Sắp tới bữa $meal rồi';
  static const cookMeal = 'Nấu bữa này';
  static const cookDish = 'Nấu món này';
  static String openUpcomingPlan(String meal) => 'Mở thực đơn bữa $meal';
  static String upcomingEmpty(String meal) =>
      'Bữa $meal nay chưa có món. Thử mấy món nấu được với đồ bạn có:';
  static const addDish = '+ Thêm';
  static String addDishAria(String name, String meal) => 'Thêm $name vào bữa $meal';
  static const readyToCook = 'Nấu được ngay';
  static const readyEmptyPantryTitle = 'Tủ đồ đang trống';
  static const readyEmptyPantryBody = 'Thêm đồ bạn có, app tìm món nấu được ngay.';
  static const readyEmptyNoMatchTitle = 'Chưa đủ đồ cho món nào';
  static const readyEmptyNoMatchBody = 'Thêm vài thứ nữa vào tủ để app gợi ý.';
  static const shoppingTitle = 'Đi chợ';
  static String shoppingNeedBuy(int count) => 'Còn $count thứ cần mua';
  static const shoppingEmpty = 'Danh sách đi chợ đang trống';
  static const shoppingEmptySub = 'Lấy đồ còn thiếu từ thực đơn tuần này';

  // Hôm nay ăn gì v2 (DSC-12)
  static String todayTitle(String meal) => 'Bữa $meal nay';
  static const todaySubtitle = 'Gợi ý theo tủ đồ, bếp và nhu cầu của bạn';
  static String todayCriteriaAria(List<String> criteria) =>
      'Tiêu chí: ${criteria.join(', ')}. Bấm để sửa';
  static const todayByHour = 'Theo giờ';
  static String todayUnderMinutes(int minutes) => 'Dưới $minutes phút';
  static String todayMoreDishes(String names, int more) => '$names +$more món';
  static const todayMealAria = 'Bữa gợi ý';
  static String todayMealMeta(int count, int minutes, List<String> tools) =>
      ['$count món', '~$minutes phút', ...tools].join(' · ');
  static String todayAltMeta(int count, int minutes, {required bool ready}) =>
      ['$count món', '~$minutes phút', if (ready) 'Đủ đồ'].join(' · ');
  static const todayHasAll = 'Đủ đồ';
  static String todayMissingCount(int count) => 'Thiếu $count thứ';
  static String todayAboutMinutes(int minutes) => '~$minutes phút';
  static const todaySwap = 'Đổi';
  static String todaySwapAria(String name) => 'Đổi $name';
  static const todayDislike = 'Không hợp';
  static const todayShuffle = 'Đổi cả bữa';
  static const todayReasonsPrompt = 'Vì sao không hợp? App sẽ nhớ.';
  static const todayAlternatives = 'Hoặc thử';
  static const todaySave = 'Lưu lại';
  static const todaySaved = 'Đã lưu';
  static const todayAddToPlan = 'Thêm vào thực đơn';
  static const todaySavedMeal = 'Đã lưu bữa vào Đã lưu';
  static const todaySavedDish = 'Đã lưu món vào Đã lưu';
  static const todayUnsaved = 'Đã bỏ lưu';
  static const todayView = 'Xem';
  static const todayEmpty =
      'Chưa có bữa hợp tiêu chí của bạn. Bạn thử sửa tiêu chí hoặc thêm đồ vào Tủ đồ.';
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

  // Gợi ý cho mình (DSC-12a)
  static const prefsTitle = 'Hôm nay bạn muốn ăn thế nào?';
  static const prefsSubtitle = 'Chọn nhanh, app lo phần còn lại';
  static const prefsScaleLabel = 'Quy mô bữa';
  static const prefsTimeLabel = 'Thời gian nấu';
  static const prefsFeel = 'Cảm giác';
  static const prefsFridge = 'Dọn tủ lạnh';
  static const prefsFridgeDesc = 'Ưu tiên món dùng đồ bạn đang có';

  // Quy mô
  static const prefsScaleOne = '1 món gọn lẹ';
  static const prefsScaleOneHint = 'Một món đơn giản, nhanh gọn';
  static const prefsScaleTwo = 'Cơm nhà 2 món';
  static const prefsScaleTwoHint = 'Món mặn kèm canh hoặc rau';
  static const prefsScaleTray = 'Mâm cơm (3+ món)';
  static const prefsScaleTrayHint = 'Món mặn, canh và rau đầy đủ';

  // Thời gian
  static const prefsTime15 = 'Siêu tốc';
  static const prefsTime15Hint = 'Dưới 15 phút';
  static const prefsTime30 = 'Nhanh gọn';
  static const prefsTime30Hint = 'Trong vòng 30 phút';
  static const prefsTimeNull = 'Thong thả';
  static const prefsTimeNullHint = 'Không giới hạn thời gian';

  // Cảm giác
  static const prefsFeelWeather = 'Theo thời tiết';
  static const prefsFeelWeatherHint = 'App chọn món hợp thời tiết hôm nay';
  static const prefsFeelWeatherDisabled = 'Chưa bật';
  static const prefsFeelCooling = 'Nóng bức · Giải nhiệt';
  static const prefsFeelCoolingHint = 'Món mát, thanh nhẹ, ít dầu mỡ';
  static const prefsFeelWarming = 'Mưa lạnh · Ấm bụng';
  static const prefsFeelWarmingHint = 'Cháo, canh nóng, đậm đà';
  static const prefsFeelAny = 'Tuỳ bạn';
  static const prefsFeelAnyHint = 'Không lọc theo cảm giác';
  static const prefsWeatherInvite =
      'Gợi ý theo thời tiết đang tắt. Bật trong Cài đặt để app chọn món hợp trời hôm nay.';
  static const prefsWeatherInviteAction = 'Mở Cài đặt';

  // Tags
  static const prefsTagsSectionCheap = 'Tiết kiệm';
  static const prefsTagCheap = 'Hệ cuối tháng';
  static const prefsTagsSectionTaste = 'Khẩu vị';
  static const prefsTagHealthy = 'Healthy · Eat clean';
  static const prefsTagVeg = 'Thanh đạm · Món chay';
  static const prefsTagMild = 'Dịu nhẹ, không cay';
  static const prefsTagsSectionOccasion = 'Dịp';
  static const prefsTagSnack = 'Mồi bén · Lai rai';
  static const prefsTagParty = 'Đãi bạn · Cuối tuần';

  static String prefsMore(int n) => n > 0 ? 'Thêm tiêu chí ($n)' : 'Thêm tiêu chí';
  static const prefsSkip = 'Bỏ qua';
  static String prefsCta(String scale) => 'Gợi ý $scale';
}
