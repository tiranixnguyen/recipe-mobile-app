import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/format.dart';

void main() {
  test('formatAmount bỏ số 0 thừa, dùng dấu phẩy, tối đa 2 chữ số lẻ', () {
    expect(formatAmount(4), '4');
    expect(formatAmount(1.5), '1,5');
    expect(formatAmount(1 / 3), '0,33');
    expect(formatAmount(100), '100');
  });
}
