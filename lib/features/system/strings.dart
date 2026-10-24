abstract final class SystemStrings {
  static const onboardingStep = 'Bước 1/1 · Bếp của bạn';
  static const onboardingTitle = 'Phòng bạn có gì để nấu?';
  static const onboardingIntro = 'App chỉ gợi ý món bạn nấu được. Đổi lại lúc nào cũng được.';
  static const onboardingTools = 'Dụng cụ';
  static const onboardingDiets = 'Chế độ ăn';
  static const onboardingSkip = 'Bỏ qua';
  static const onboardingDone = 'Xong, gợi ý món cho mình';
  static const kitchenEditSave = 'Lưu';
  static const back = 'Quay lại';
  static const settings = 'Cài đặt';

  static const themeSection = 'Giao diện';
  static const themeLight = 'Sáng';
  static const themeDark = 'Tối';
  static const themeSystem = 'Theo hệ thống';
  static String themeHint({required bool followSystem, required bool dark}) => followSystem
      ? 'Đang theo máy: ${dark ? themeDark : themeLight}. Đổi theme của điện thoại là app đổi theo.'
      : 'App luôn dùng giao diện ${dark ? themeDark : themeLight}.';

  static const kitchenSection = 'Bếp của bạn';
  static const kitchenEdit = 'Dụng cụ & chế độ ăn';

  static const notifSection = 'Thông báo';
  static const notifTimer = 'Nhắc khi hẹn giờ xong';
  static const notifTimerNote = 'Rung và báo khi đồng hồ nấu hết giờ';
  static const notifMeal = 'Nhắc bữa theo thực đơn';
  static const notifMealNote = 'Trước bữa 30 phút';

  static const supportSection = 'Hỗ trợ & thông tin';
  static const feedback = 'Góp ý & báo lỗi';
  static const rateApp = 'Đánh giá trên Google Play';
  static const policy = 'Chính sách quyền riêng tư';
  static const about = 'Giới thiệu';

  static const dataSection = 'Dữ liệu';
  static const clearData = 'Xoá dữ liệu trên máy';

  static String version(String version) => 'Bếp Hoà Lạc · phiên bản $version';
}
