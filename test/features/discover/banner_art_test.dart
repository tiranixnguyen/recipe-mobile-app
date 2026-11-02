import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/discover/domain/banner_art.dart';

void main() {
  final ids = {
    for (final pool in bannerPools.values)
      for (final g in pool) ...g,
  };
  final images = {for (final id in ids) id: 'assets/images/recipes/$id.jpg'};
  const allCards = BannerCard.values;

  List<BannerArt?> pick(int seed, {List<BannerCard> cards = allCards}) =>
      pickBannerArt(cards: cards, seed: seed, imageById: images);

  test('cùng seed thì cùng kết quả', () {
    expect(pick(100), pick(100));
  });

  test('sang ngày khác thì đổi ảnh hoặc kiểu', () {
    expect(pick(100), isNot(pick(101)));
    expect(pick(100), isNot(pick(102)));
  });

  test('hai thẻ liền nhau khác kiểu, mọi seed 1..366 với đủ 8 thẻ', () {
    for (var seed = 1; seed <= 366; seed++) {
      final arts = pick(seed);
      expect(arts, everyElement(isNotNull));
      for (var i = 0; i + 1 < arts.length; i++) {
        expect(arts[i]!.layout, isNot(arts[i + 1]!.layout), reason: 'seed $seed, thẻ $i');
      }
    }
  });

  test('thẻ tối luôn có 2 ảnh và kiểu two*', () {
    for (var seed = 1; seed <= 366; seed++) {
      final art = pick(seed, cards: [BannerCard.dinner]).single!;
      expect(art.imageAssets, hasLength(2));
      expect(art.layout, anyOf(BannerArtLayout.twoBottom, BannerArtLayout.twoTop));
    }
  });

  test('thẻ món đơn có 1 ảnh và kiểu one*', () {
    final art = pick(5, cards: [BannerCard.fridge]).single!;
    expect(art.imageAssets, hasLength(1));
    expect(
      art.layout,
      anyOf(BannerArtLayout.oneBottom, BannerArtLayout.oneTop, BannerArtLayout.oneTilted),
    );
  });

  test('pool rỗng hoặc không khai báo thì ra null', () {
    expect(
      pickBannerArt(
        cards: [BannerCard.hot, BannerCard.rainy],
        seed: 1,
        imageById: images,
        pools: const {BannerCard.hot: []},
      ),
      [null, null],
    );
  });

  test('id không tồn tại hoặc đường dẫn rỗng thì ra null', () {
    expect(pickBannerArt(cards: [BannerCard.fridge], seed: 1, imageById: const {}), [null]);
    expect(
      pickBannerArt(
        cards: [BannerCard.dinner],
        seed: 1,
        imageById: {...images, 'canh-ca-chua-trung': ''},
      ).single,
      anyOf(isNull, isA<BannerArt>()),
    );
    // Cặp thiếu một ảnh thì bỏ cả thẻ.
    final missingOne = Map.of(images)..remove('canh-ca-chua-trung');
    for (var seed = 1; seed <= 3; seed++) {
      final art = pickBannerArt(cards: [BannerCard.dinner], seed: seed, imageById: missingOne);
      final ids = bannerPools[BannerCard.dinner]![seed % 3];
      expect(art.single == null, ids.contains('canh-ca-chua-trung'));
    }
  });

  test('dayOfYear', () {
    expect(dayOfYear(DateTime(2026, 1, 1)), 1);
    expect(dayOfYear(DateTime(2026, 12, 31)), 365);
    expect(dayOfYear(DateTime(2028, 12, 31, 23, 59)), 366);
  });
}
