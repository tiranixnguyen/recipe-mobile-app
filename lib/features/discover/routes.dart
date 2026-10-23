import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

const discoverLocation = '/';

/// Đường dẫn tới màn Tìm kiếm, có thể kèm từ khoá — feature khác dùng hàm này thay vì tự ghép chuỗi.
String searchLocation({String? query}) =>
    Uri(path: '/search', queryParameters: query == null ? null : {'q': query}).toString();

/// Tab Khám phá (prototype `Main`).
final discoverTabRoutes = <RouteBase>[
  GoRoute(
    path: discoverLocation,
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.title),
  ),
];

/// Tab Đã lưu (prototype `Saved`).
final savedTabRoutes = <RouteBase>[
  GoRoute(
    path: '/saved',
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.saved),
  ),
];

/// Màn toàn màn hình: Tìm kiếm (`Search`), Hôm nay ăn gì (`Today`).
final discoverRoutes = <RouteBase>[
  GoRoute(
    path: '/search',
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.search),
  ),
  GoRoute(
    path: '/today',
    builder: (_, _) => const ComingSoonScreen(title: DiscoverStrings.today),
  ),
];
