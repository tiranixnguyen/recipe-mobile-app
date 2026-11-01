import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved_meal/saved_meal_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/search/search_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today_prefs/today_prefs_screen.dart';

const discoverLocation = '/';
const todayLocation = '/today';
const todayPrefsLocation = '/today/prefs';

/// Gợi ý cho mình mở từ dải tiêu chí của Hôm nay ăn gì: xong thì quay lại màn đó.
const todayPrefsEditLocation = '$todayPrefsLocation?from=today';

const _savedPath = '/saved';

/// Đường dẫn tab Đã lưu; [highlightMeal] là `SavedMeal.key` của bữa vừa lưu, thẻ đó hiện "Mới thêm".
String savedLocation({String? highlightMeal}) => Uri(
  path: _savedPath,
  queryParameters: highlightMeal == null ? null : {'new': highlightMeal},
).toString();

/// Chi tiết một bữa đã lưu, [key] là `SavedMeal.key`.
String savedMealLocation(String key) => '$_savedPath/meal/${Uri.encodeComponent(key)}';

/// Đường dẫn tới màn Tìm kiếm — feature khác dùng hàm này thay vì tự ghép chuỗi.
///
/// Có thể kèm từ khoá và bộ lọc mở sẵn: `q`, `maxMinutes`, `tool`, `diet`, `meal` (id của enum).
String searchLocation({String? query, int? maxMinutes, Tool? tool, Diet? diet, Meal? meal}) {
  final params = {
    'q': ?query,
    'maxMinutes': ?maxMinutes?.toString(),
    'tool': ?tool?.id,
    'diet': ?diet?.id,
    'meal': ?meal?.id,
  };
  return Uri(path: '/search', queryParameters: params.isEmpty ? null : params).toString();
}

/// Tab Khám phá (prototype `Main`).
final discoverTabRoutes = <RouteBase>[
  GoRoute(path: discoverLocation, builder: (_, _) => const DiscoverScreen()),
];

/// Tab Đã lưu (prototype `Saved`).
final savedTabRoutes = <RouteBase>[
  GoRoute(
    path: _savedPath,
    builder: (_, state) => SavedScreen(highlightMeal: state.uri.queryParameters['new']),
    routes: [
      // Con của `/saved` để giữ thanh tab bên dưới.
      GoRoute(
        path: 'meal/:key',
        builder: (_, state) => SavedMealScreen(mealKey: state.pathParameters['key']!),
      ),
    ],
  ),
];

/// Màn toàn màn hình: Tìm kiếm (`Search`), Hôm nay ăn gì (`Today`).
final discoverRoutes = <RouteBase>[
  GoRoute(
    path: '/search',
    builder: (_, state) => SearchScreen(
      query: state.uri.queryParameters['q'],
      maxMinutes: int.tryParse(state.uri.queryParameters['maxMinutes'] ?? ''),
      tool: Tool.tryParse(state.uri.queryParameters['tool'] ?? ''),
      diet: Diet.tryParse(state.uri.queryParameters['diet'] ?? ''),
      meal: Meal.tryParse(state.uri.queryParameters['meal'] ?? ''),
    ),
  ),
  GoRoute(
    path: todayLocation,
    builder: (_, _) => const TodayScreen(),
  ),
  GoRoute(
    path: todayPrefsLocation,
    builder: (_, state) =>
        TodayPrefsScreen(fromToday: state.uri.queryParameters['from'] == 'today'),
  ),
];
