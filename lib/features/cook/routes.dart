import 'package:go_router/go_router.dart';

import '../../core/widgets/coming_soon_screen.dart';
import 'strings.dart';

/// Đường dẫn tới màn Chi tiết món — feature khác dùng hàm này thay vì tự ghép chuỗi.
String recipeLocation(String id) => '/recipe/$id';

/// Chi tiết món (`Detail`); chế độ nấu (`CookPrep` → `CookStep` → `CookDone`) thêm dưới route này.
final cookRoutes = <RouteBase>[
  GoRoute(
    path: '/recipe/:id',
    builder: (_, _) => const ComingSoonScreen(title: CookStrings.detail),
  ),
];
