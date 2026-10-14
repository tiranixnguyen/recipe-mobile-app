const _currency = 'đ';

/// `25000` → `25.000đ`.
String formatVnd(int amount) {
  final sign = amount < 0 ? '-' : '';
  final grouped = amount.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.');
  return '$sign$grouped$_currency';
}
