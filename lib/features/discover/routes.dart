import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/search/search_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_screen.dart';

const discoverLocation = '/';
const todayLocation = '/today';
const todayPrefsLocation = '/today/prefs';

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
  GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
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
    builder: (_, _) => const TodayScreen(),
  ),
];
