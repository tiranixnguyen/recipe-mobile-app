import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('0.##', 'vi');

/// Hiển thị lượng nguyên liệu kiểu Việt Nam: bỏ số 0 thừa, dấu phẩy thập phân, tối đa 2 chữ số lẻ.
///
/// `4.0` → `4`, `1.5` → `1,5`, `1 / 3` → `0,33`.
String formatAmount(double amount) => _amountFormat.format(amount);
