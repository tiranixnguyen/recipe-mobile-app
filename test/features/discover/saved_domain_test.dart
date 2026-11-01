import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/discover/domain/saved.dart';

void main() {
  group('savedGroupOf', () {
    // Chủ nhật 2/11/2026, 0:30 — gần nửa đêm để thử theo ngày lịch, không theo 24 giờ.
    final now = DateTime(2026, 11, 2, 0, 30);

    test('theo ngày lịch', () {
      expect(savedGroupOf(DateTime(2026, 11, 2), now), SavedGroup.today);
      expect(savedGroupOf(DateTime(2026, 11, 1, 23, 59), now), SavedGroup.yesterday);
      expect(savedGroupOf(DateTime(2026, 10, 27), now), SavedGroup.thisWeek);
      expect(savedGroupOf(DateTime(2026, 10, 26), now), SavedGroup.earlier);
    });

    test('giờ ở tương lai (đổi giờ máy) tính là hôm nay', () {
      expect(savedGroupOf(DateTime(2026, 11, 5), now), SavedGroup.today);
    });

    test('không có giờ lưu thì Trước đó', () {
      expect(savedGroupOf(null, now), SavedGroup.earlier);
    });
  });
}
