/// Public API của feature Hệ thống — feature khác chỉ được import file này.
///
/// - [themeModeProvider]: Sáng / Tối / Theo hệ thống.
/// - [onboardingDoneProvider]: Splash đọc để chọn màn đầu tiên.
/// - [kitchenProfileProvider]: dụng cụ và chế độ ăn người dùng chọn (F3 gợi ý dùng).
/// - [notificationServiceProvider]: hẹn giờ xong (F2), nhắc bữa (F4); hiện là stub, SYS-03 làm thật.
library;

export 'data/kitchen_profile.dart'
    show KitchenProfile, KitchenProfileController, kitchenProfileProvider;
export 'data/notification_service.dart'
    show NotificationService, NoopNotificationService, notificationServiceProvider;
export 'data/preferences.dart'
    show OnboardingController, ThemeModeController, onboardingDoneProvider, themeModeProvider;
export 'routes.dart' show onboardingLocation, settingsLocation, systemRoutes;
