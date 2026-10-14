import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/detail/domain/pricing.dart';

void main() {
  test('size M giữ nguyên giá gốc', () {
    expect(priceFor(basePrice: 20000, size: CupSize.m), 20000);
  });

  test('size L cộng phụ thu, mỗi topping cộng 5.000đ', () {
    expect(priceFor(basePrice: 20000, size: CupSize.l, toppings: 2), 35000);
  });

  test('số topping âm là lỗi', () {
    expect(() => priceFor(basePrice: 20000, size: CupSize.m, toppings: -1), throwsArgumentError);
  });
}
