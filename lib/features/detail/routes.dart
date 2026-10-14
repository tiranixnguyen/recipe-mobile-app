import 'package:go_router/go_router.dart';

import 'presentation/detail_screen.dart';

/// Đường dẫn tới màn chi tiết — feature khác dùng hàm này thay vì tự ghép chuỗi.
String drinkLocation(String id) => '/drink/$id';

final detailRoutes = <RouteBase>[
  GoRoute(
    path: '/drink/:id',
    builder: (_, state) => DetailScreen(drinkId: state.pathParameters['id']!),
  ),
];
