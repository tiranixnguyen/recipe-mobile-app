import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_screen.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_screen.dart';

const shoppingLocation = '/shopping';

/// Gửi kèm [goToPlanDay] (`extra` của route `/plan`): đánh dấu lần mở mới (luôn là instance mới,
/// Thực đơn so bằng identity để biết mở lại), kèm thông báo hiện ngay khi tới nếu có.
class PlanArrival {
  PlanArrival({this.snackText, this.snackKind = SnackKind.success});

  final String? snackText;
  final SnackKind snackKind;
}

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
/// dùng đã chọn ngày khác: mỗi lần gọi gửi một [PlanArrival] mới để màn biết là lần mở mới. Có
/// [arrival] với `snackText` thì Thực đơn báo kết quả ngay khi tới (sheet Thêm vào thực đơn).
void goToPlanDay(BuildContext context, DateTime date, {Meal? meal, PlanArrival? arrival}) =>
    context.go(
      planLocation(date: date, meal: meal),
      extra: arrival ?? PlanArrival(),
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
        arrival: state.extra is PlanArrival ? state.extra as PlanArrival : null,
      );
    },
  ),
];

/// Danh sách đi chợ (`Shopping`), mở từ Thực đơn.
final planRoutes = <RouteBase>[
  GoRoute(
    path: shoppingLocation,
    builder: (_, _) => const ShoppingScreen(),
  ),
];
