import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Tên icon chép tay từ README component Icon; test này đỏ khi sync lại `docs/design/` mà thêm/bớt tên.
void main() {
  test('AppIcons có đúng các tên trong README Icon', () {
    final readme = File('docs/design/design-system/components/Icon/README.md').readAsStringSync();
    final available = RegExp(r'Tên có sẵn: ([^.]+)\.').firstMatch(readme)!.group(1)!;
    final theme = RegExp(r'; (\w+), (\w+), (\w+) cho lựa chọn giao diện').firstMatch(readme)!;
    final names = {
      ...available.split(',').map((name) => name.trim()),
      theme.group(1)!,
      theme.group(2)!,
      theme.group(3)!,
    };

    // Icon prototype vẽ SVG riêng, README Icon chưa có: giỏ của nút nổi Đi chợ (Pantry, MealPlan).
    const prototypeOnly = {'basket'};

    expect(names, hasLength(33));
    expect(AppIcons.byName.keys.toSet(), {...names, ...prototypeOnly});
  });

  test('mỗi tên một icon riêng', () {
    expect(AppIcons.byName.values.toSet(), hasLength(AppIcons.byName.length));
  });
}
