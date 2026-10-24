import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/app_colors.dart';
import 'package:recipe_mobile_app/core/theme/app_radius.dart';
import 'package:recipe_mobile_app/core/theme/app_typography.dart';

/// Theme sáng/tối dựng từ [AppColors]; `App` gắn vào `MaterialApp.theme`/`darkTheme`.
///
/// `ColorScheme` ánh xạ token sang vai trò Material để widget mặc định (nút, ô nhập, thanh điều hướng…)
/// ra đúng màu thiết kế thay vì tím M3. Màu không có vai trò Material (`herbInk`, `dangerInk`…) lấy qua
/// `context.colors`.
abstract final class AppTheme {
  static final light = _build(AppColors.light, Brightness.light);
  static final dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    const onFilled = Colors.white;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.chili,
      onPrimary: onFilled,
      primaryContainer: c.chiliSoft,
      onPrimaryContainer: c.chiliDeep,
      secondary: c.herb,
      onSecondary: onFilled,
      secondaryContainer: c.herbSoft,
      onSecondaryContainer: c.ink,
      error: c.danger,
      onError: onFilled,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.outline,
      outlineVariant: c.line,
      // Thiết kế phẳng: không phủ màu primary lên bề mặt nổi.
      surfaceTint: Colors.transparent,
      inverseSurface: c.ink,
      onInverseSurface: c.surface,
    );

    final textTheme = const TextTheme(
      headlineMedium: AppTextStyles.display,
      headlineSmall: AppTextStyles.step,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.subtitle,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.label,
      labelSmall: AppTextStyles.caption,
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    const buttonSize = Size(64, 48);
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      fontFamily: AppFonts.sans,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarThemeData(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.title.copyWith(color: c.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.chiliSoft,
        // Tab cao 56 + padding `space-1` trên dưới, như BottomNav trong bundle.css.
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.chili : c.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          // Nhãn tab 12/16·600 (bundle.css), không phải token `label`.
          (states) => AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? c.chili : c.inkMuted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.chili,
          foregroundColor: onFilled,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.outline),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.chiliDeep,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surfaceRaised,
        hintStyle: AppTextStyles.body.copyWith(color: c.inkMuted),
        border: inputBorder(c.outline),
        enabledBorder: inputBorder(c.outline),
        focusedBorder: inputBorder(c.chili, 2),
        errorBorder: inputBorder(c.dangerInk),
        focusedErrorBorder: inputBorder(c.dangerInk, 2),
        errorStyle: AppTextStyles.caption.copyWith(color: c.dangerInk),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1),
      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: c.line),
        ),
      ),
    );
  }
}
