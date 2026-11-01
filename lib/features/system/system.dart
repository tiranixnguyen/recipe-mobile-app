/// Public API của feature Hệ thống — feature khác chỉ được import file này.
///
/// - [themeModeProvider]: Sáng / Tối / Theo hệ thống.
/// - [onboardingDoneProvider]: Splash đọc để chọn màn đầu tiên.
/// - [kitchenProfileProvider]: dụng cụ và chế độ ăn người dùng chọn (F3 gợi ý dùng).
/// - [notificationServiceProvider]: báo hẹn giờ nấu xong (F2), hẹn trước bằng `scheduleTimer` để
///   báo cả khi đang ở app khác. Nhắc bữa theo `plannedMealsProvider`
///   do [mealReminderSyncProvider] tự hẹn; `App` listen provider đó.
/// - [shouldAskNotificationPermissionProvider] + [notifPermissionLocation]: F2/F4 mở màn xin quyền
///   trước lần hẹn giờ / nhắc bữa đầu.
/// - [GettingStartedCard] + [StartHint]: checklist "Bắt đầu" ở Khám phá và gợi ý tại chỗ ở Tủ đồ,
///   Thực đơn, màn nấu xong; [startHintProvider] cho màn cần biết gợi ý có đang hiện.
/// - [feedbackForErrorLocation]: màn lỗi mở Góp ý kèm mã lỗi.
/// - [notificationPluginProvider]: `main.dart` override bằng [LocalNotificationPlugin].
library;

export 'data/getting_started.dart' show gettingStartedProvider, startHintProvider;
export 'data/kitchen_profile.dart'
    show KitchenProfile, KitchenProfileController, kitchenProfileProvider;
export 'data/meal_reminder_sync.dart' show mealReminderSyncProvider;
export 'data/notification_permission.dart' show shouldAskNotificationPermissionProvider;
export 'data/notification_plugin.dart' show LocalNotificationPlugin, notificationPluginProvider;
export 'data/notification_service.dart'
    show NotificationService, NoopNotificationService, maxTimerKey, notificationServiceProvider;
export 'data/preferences.dart'
    show OnboardingController, ThemeModeController, onboardingDoneProvider, themeModeProvider;
export 'domain/getting_started.dart' show StartHintSpot, StartStep;
export 'presentation/getting_started/getting_started_card.dart' show GettingStartedCard;
export 'presentation/getting_started/start_hint.dart' show StartHint;
export 'routes.dart'
    show
        feedbackForErrorLocation,
        notifPermissionLocation,
        onboardingLocation,
        settingsLocation,
        systemRoutes;
