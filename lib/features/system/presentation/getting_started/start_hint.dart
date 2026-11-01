import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';
import 'package:recipe_mobile_app/features/system/data/getting_started.dart';
import 'package:recipe_mobile_app/features/system/domain/getting_started.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

String _text(StartHintSpot spot) => switch (spot) {
  StartHintSpot.pantryAdd => SystemStrings.hintPantryAdd,
  StartHintSpot.pantryShop => SystemStrings.hintPantryShop,
  StartHintSpot.planAdd => SystemStrings.hintPlanAdd,
  StartHintSpot.planCook => SystemStrings.hintPlanCook,
  StartHintSpot.rate => SystemStrings.hintRate,
};

/// Gợi ý tại chỗ của checklist "Bắt đầu" ([InlineBanner] info). Không hiện gì khi checklist đã ẩn
/// hoặc bước liên quan đã xong. Tự lo khoảng cách bên dưới.
class StartHint extends ConsumerWidget {
  const StartHint(
    this.spot, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.s3),
  });

  final StartHintSpot spot;

  /// Khoảng cách quanh banner; màn đã tự đặt khoảng cách giữa các phần tử (`Column.spacing`) thì
  /// truyền `EdgeInsets.zero`.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(startHintProvider(spot))) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: InlineBanner(text: _text(spot)),
    );
  }
}
