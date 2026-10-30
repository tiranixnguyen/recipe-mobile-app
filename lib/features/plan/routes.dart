import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_screen.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

const shoppingLocation = '/shopping';

/// Tab Thực đơn; [date] mở sẵn ngày đó thay vì hôm nay, [meal] mở sẵn bữa đó:
/// `/plan?date=2026-10-30&meal=dinner`.
String planLocation({DateTime? date, Meal? meal}) {
  final query = {
    if (date != null)
      'date': '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}',
    if (meal != null) 'meal': meal.id,
  };
  return Uri(path: '/plan', queryParameters: query.isEmpty ? null : query).toString();
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Sang tab Thực đơn và mở ngày [date] (và bữa [meal]), kể cả khi URL đang là ngày đó nhưng người
/// dùng đã chọn ngày khác: mỗi lần gọi gửi một `extra` mới để màn biết là lần mở mới.
void goToPlanDay(BuildContext context, DateTime date, {Meal? meal}) => context.go(
  planLocation(date: date, meal: meal),
  extra: Object(),
);

/// Tab Thực đơn (prototype `MealPlan`).
final planTabRoutes = <RouteBase>[
  GoRoute(
    path: '/plan',
    builder: (_, state) {
      final query = state.uri.queryParameters;
      return PlanScreen(
        initialDate: DateTime.tryParse(query['date'] ?? ''),
        initialMeal: switch (query['meal']) {
          final id? => Meal.tryParse(id),
          null => null,
        },
        openRequest: state.extra,
      );
    },
  ),
];

/// Danh sách đi chợ (`Shopping`), mở từ Thực đơn.
final planRoutes = <RouteBase>[
  GoRoute(
    path: shoppingLocation,
    builder: (_, _) => const ComingSoonScreen(title: PlanStrings.shopping),
  ),
];
