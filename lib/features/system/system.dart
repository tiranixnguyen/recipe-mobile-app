/// Public API của feature Hệ thống — feature khác chỉ được import file này.
///
/// Lead dựng sẵn [themeModeProvider], [onboardingDoneProvider] và route Onboarding tạm để app chạy
/// được; chủ feature thay phần ruột, giữ nguyên chữ ký.
library;

export 'data/preferences.dart'
    show OnboardingController, ThemeModeController, onboardingDoneProvider, themeModeProvider;
export 'routes.dart' show onboardingLocation, settingsLocation, systemRoutes;
