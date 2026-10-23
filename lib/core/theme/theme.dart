/// Token thiết kế và theme của app — widget chỉ import file này.
///
/// Màu: `context.colors.chiliSoft`. Chữ: `AppTextStyles.body` (hoặc `Theme.of(context).textTheme`
/// khi muốn sẵn màu `ink`). Khoảng cách: `AppSpacing.s4`. Bo góc: `AppRadius.mdAll`.
library;

import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/app_colors.dart';

export 'app_colors.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';

extension AppThemeContext on BuildContext {
  /// Bảng màu của theme đang dùng (sáng hoặc tối).
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
