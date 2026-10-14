import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/format.dart';

void main() {
  test('formatVnd nhóm hàng nghìn bằng dấu chấm', () {
    expect(formatVnd(0), '0đ');
    expect(formatVnd(500), '500đ');
    expect(formatVnd(25000), '25.000đ');
    expect(formatVnd(1250000), '1.250.000đ');
    expect(formatVnd(-3000), '-3.000đ');
  });
}
