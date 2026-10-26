import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_screen.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

const shoppingLocation = '/shopping';

/// Tab Thực đơn; [day] (0 = Thứ Hai … 6 = Chủ Nhật, tuần này) mở sẵn ngày đó thay vì hôm nay.
String planLocation({int? day}) => Uri(
  path: '/plan',
  queryParameters: day == null ? null : {'day': '$day'},
).toString();

/// Sang tab Thực đơn và mở ngày [day], kể cả khi URL đang là ngày đó nhưng người dùng đã chọn ngày
/// khác: mỗi lần gọi gửi một `extra` mới để màn biết là lần mở mới.
void goToPlanDay(BuildContext context, int day) =>
    context.go(planLocation(day: day), extra: Object());

/// Tab Thực đơn (prototype `MealPlan`).
final planTabRoutes = <RouteBase>[
  GoRoute(
    path: '/plan',
    builder: (_, state) => PlanScreen(
      initialDay: int.tryParse(state.uri.queryParameters['day'] ?? ''),
      openRequest: state.extra,
    ),
  ),
];

/// Danh sách đi chợ (`Shopping`), mở từ Thực đơn.
final planRoutes = <RouteBase>[
  GoRoute(
    path: shoppingLocation,
    builder: (_, _) => const ComingSoonScreen(title: PlanStrings.shopping),
  ),
];
