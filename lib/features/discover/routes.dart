import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

const discoverLocation = '/';
const todayLocation = '/today';

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
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.search),
  ),
  GoRoute(
    path: todayLocation,
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.today),
  ),
];
