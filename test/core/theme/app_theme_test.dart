import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';

void main() {
  for (final (name, theme, colors, brightness) in [
    ('sáng', AppTheme.light, AppColors.light, Brightness.light),
    ('tối', AppTheme.dark, AppColors.dark, Brightness.dark),
  ]) {
    test('$name: ColorScheme lấy từ token', () {
      final scheme = theme.colorScheme;
      expect(scheme.brightness, brightness);
      expect(scheme.primary, colors.chili);
      expect(scheme.primaryContainer, colors.chiliSoft);
      expect(scheme.onPrimaryContainer, colors.chiliDeep);
      expect(scheme.secondary, colors.herb);
      expect(scheme.secondaryContainer, colors.herbSoft);
      expect(scheme.error, colors.danger);
      expect(scheme.surface, colors.surface);
      expect(scheme.onSurface, colors.ink);
      expect(scheme.onSurfaceVariant, colors.inkMuted);
      expect(scheme.surfaceContainer, colors.surfaceRaised);
      expect(scheme.outline, colors.outline);
      expect(scheme.outlineVariant, colors.line);
      expect(theme.scaffoldBackgroundColor, colors.surface);
      expect(theme.extension<AppColors>(), same(colors));
      expect(theme.textTheme.bodyMedium!.color, colors.ink);
      expect(theme.textTheme.bodyMedium!.fontFamily, AppFonts.sans);
    });
  }

  test('AppColors.lerp: t=0 ra màu đầu, t=1 ra màu cuối', () {
    const light = AppColors.light;
    const dark = AppColors.dark;
    expect(light.lerp(dark, 0).byToken, light.byToken);
    expect(light.lerp(dark, 1).byToken, dark.byToken);
    expect(light.lerp(null, 0.5), same(light));
  });

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    testWidgets('context.colors trong theme $name', (tester) async {
      late AppColors found;
      await tester.pumpWidget(
        Theme(
          data: theme,
          child: Builder(
            builder: (context) {
              found = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, same(colors));
    });
  }
}
