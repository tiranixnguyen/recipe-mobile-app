enum CupSize {
  m('M', 0),
  l('L', 5000);

  const CupSize(this.label, this.surcharge);

  final String label;
  final int surcharge;
}

const toppingPrice = 5000;

/// Giá một ly theo size và số topping thêm.
int priceFor({required int basePrice, required CupSize size, int toppings = 0}) {
  if (toppings < 0) throw ArgumentError.value(toppings, 'toppings', 'không được âm');
  return basePrice + size.surcharge + toppings * toppingPrice;
}
