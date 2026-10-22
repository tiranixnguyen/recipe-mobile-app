import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';

/// Token trong Dart chép tay từ `tokens.json`; test này đỏ khi sync lại `docs/design/` mà giá trị lệch.
void main() {
  final tokens = jsonDecode(
    File('docs/design/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  double px(Object value) => double.parse((value as String).replaceAll('px', ''));

  group('màu', () {
    final colorTokens = (tokens['color'] as Map)['tokens'] as List;

    for (final (theme, colors) in [('light', AppColors.light), ('dark', AppColors.dark)]) {
      test('$theme: đủ token, đúng thứ tự và giá trị', () {
        final expected = {
          for (final token in colorTokens)
            token['name'] as String: Color(
              0xFF000000 | int.parse((token['value'][theme] as String).substring(1), radix: 16),
            ),
        };
        final actual = colors.byToken;

        expect(actual.keys.toList(), expected.keys.toList());
        for (final MapEntry(:key, :value) in expected.entries) {
          expect(actual[key]!.toARGB32(), value.toARGB32(), reason: '$theme/$key');
        }
      });
    }
  });

  test('font chính là Be Vietnam Pro', () {
    final families = (tokens['type'] as Map)['families'] as Map;
    expect(families['sans'], startsWith('"${AppFonts.sans}"'));
  });

  test('kiểu chữ: đủ style, đúng cỡ/dòng/đậm', () {
    final styles = [
      for (final group in (tokens['type'] as Map)['groups'] as List) ...group['styles'] as List,
    ];

    expect(AppTextStyles.byToken.keys.toList(), [for (final s in styles) s['name']]);
    for (final s in styles) {
      final name = s['name'] as String;
      final style = AppTextStyles.byToken[name]!;
      expect(style.fontFamily, AppFonts.sans, reason: name);
      expect(style.fontSize, px(s['fontSize']), reason: name);
      expect(style.fontSize! * style.height!, closeTo(px(s['lineHeight']), 1e-9), reason: name);
      expect(style.fontWeight!.value, s['fontWeight'], reason: name);
    }
  });

  test('khoảng cách: đủ token space-N, đúng giá trị', () {
    final spacing = (tokens['spacing'] as Map)['tokens'] as List;
    expect(AppSpacing.byToken, {for (final t in spacing) t['name']: px(t['value'])});
  });

  test('bo góc: đủ token radius-*, đúng giá trị', () {
    final radius = (tokens['radius'] as Map)['tokens'] as List;
    expect(AppRadius.byToken, {for (final t in radius) t['name']: px(t['value'])});
  });
}
