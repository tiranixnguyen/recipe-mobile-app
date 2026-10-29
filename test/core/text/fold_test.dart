import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';

void main() {
  test('bỏ dấu, cả "đ", chữ thường, cắt khoảng trắng', () {
    expect(normalizeSearch('Đậu đỏ'), 'dau do');
    expect(normalizeSearch('  TINH BỘT '), 'tinh bot');
    expect(normalizeSearch('Gia vị & khác'), 'gia vi & khac');
    expect(normalizeSearch(''), '');
  });

  test('chữ dạng NFD (dấu tổ hợp) cũng bỏ dấu', () {
    // 'trứng' viết bằng u + móc (U+031B) + sắc (U+0301).
    expect(normalizeSearch('trứng'), 'trung');
    expect(normalizeSearch('trứng'), 'trung');
    expect(normalizeSearch('Phở'), 'pho');
  });
}
