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

  // Giới thiệu (`About`).
  static String aboutVersion(String version) => 'Phiên bản $version';
  static const aboutIntro =
      'App gợi ý món từ đồ bạn có và lên thực đơn cho sinh viên khu Hoà Lạc. Không cần tài khoản, '
      'mọi thứ lưu ngay trên máy bạn.';
  static const aboutTeam = 'Nhóm phát triển';
  static const aboutContact = 'Liên hệ';
  static const aboutLicenses = 'Giấy phép mã nguồn mở';
  static const aboutFooter = 'Làm ở Hoà Lạc, cho bếp ký túc xá.';
  static const aboutEmailCopied = 'Đã chép địa chỉ email.';

  // TODO(REL): điền tên nhóm và email liên hệ thật trước khi phát hành.
  static const teamName = '[TÊN NHÓM]';
  static const contactEmail = '[EMAIL]';

  // Chính sách (`Policy`).
  static const policySummary =
      'Nói ngắn gọn: app không có tài khoản, dữ liệu của bạn nằm trên máy bạn. Chỉ khi bạn tự gửi '
      'góp ý thì nội dung đó mới rời khỏi máy.';
  static const policySections = <(String, List<String>)>[
    (
      '1. App lưu gì trên máy bạn',
      [
        'Nguyên liệu trong Tủ đồ, thực đơn ngày và tuần, món đã lưu, lịch sử món đã nấu và đánh giá '
            'Ngon / Tạm / Chê, dụng cụ và chế độ ăn bạn chọn, cùng lựa chọn giao diện. Những thứ này '
            'chỉ dùng để gợi ý món cho bạn.',
      ],
    ),
    (
      '2. Không cần tài khoản',
      ['Bạn không phải đăng ký, không cần email hay số điện thoại để dùng app.'],
    ),
    (
      '3. Khi nào dữ liệu được gửi đi',
      [
        'Chỉ khi bạn bấm Gửi trong màn Góp ý: nội dung bạn viết, ảnh chụp màn hình nếu bạn đính kèm, '
            'email nếu bạn điền, và thông tin máy (phiên bản app, phiên bản Android) nếu bạn đồng ý. '
            'Các thông tin này được gửi tới nhóm phát triển qua Firebase của Google và chỉ dùng để '
            'sửa lỗi, cải thiện app.',
        // TODO(SET-16): thêm đoạn Crashlytics khi bật — dữ liệu gửi đi khi app gặp lỗi và cách tắt.
      ],
    ),
    (
      '4. Thông báo',
      [
        'App chỉ xin quyền thông báo để báo hết giờ hẹn nấu và nhắc bữa trong thực đơn. Bạn tắt được '
            'trong Cài đặt của app hoặc của điện thoại.',
      ],
    ),
    (
      '5. Xoá dữ liệu',
      [
        'Vào Cài đặt › Xoá dữ liệu trên máy, gõ $clearDataPhrase để xác nhận, hoặc gỡ app. Vì không '
            'có tài khoản, dữ liệu đã xoá không khôi phục được.',
      ],
    ),
    ('6. Liên hệ', ['Có câu hỏi về chính sách này, gửi về $contactEmail.']),
  ];
  static const policyUpdated = 'Cập nhật lần cuối: 25/10/2026';

  // Xoá dữ liệu (`ClearData`).
  static const clearDataPhrase = 'CONFIRM DELETE';
  static const clearDataTitle = 'Xoá toàn bộ dữ liệu?';
  static const clearDataIntro = 'Những thứ sau sẽ bị xoá khỏi máy:';
  static const clearDataItems = [
    'Tủ đồ và danh sách đi chợ',
    'Thực đơn ngày và tuần',
    'Món đã lưu',
    'Lịch sử nấu và đánh giá',
    'Dụng cụ, chế độ ăn, giao diện đã chọn',
  ];
  static const clearDataWarning = 'Không có tài khoản nên không khôi phục được.';
  static const clearDataPrompt = ('Gõ ', ' để mở nút xoá');
  static const clearDataLocked = 'Nút Xoá hết đang khoá để tránh bấm nhầm.';
  static const clearDataMismatch = 'Chưa khớp, gõ đúng chữ in hoa và dấu cách.';
  static const clearDataMatched = 'Đã khớp. Giờ bạn có thể bấm Xoá hết.';
  static const cancel = 'Huỷ';
  static const clearDataConfirm = 'Xoá hết';
}
