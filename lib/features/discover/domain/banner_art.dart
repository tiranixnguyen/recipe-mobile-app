/// Chọn ảnh món cắt tròn cho banner Khám phá (prototype `Main.dc.html`, #143).
///
/// Hàm thuần, không import Flutter: cùng seed thì cùng kết quả, nên ảnh cố định trong ngày
/// và đổi sang ngày khác.
library;

import 'package:flutter/foundation.dart' show immutable, listEquals;

/// Các thẻ của banner có ảnh.
enum BannerCard { hot, rainy, weatherOptIn, breakfast, lunch, dinner, fridge, endOfMonth }

/// Kiểu bố cục ảnh trên thẻ (`LAYOUT_ONE`, `LAYOUT_TWO` trong prototype).
enum BannerArtLayout { oneBottom, oneTop, oneTilted, twoBottom, twoTop }

const _layoutOne = [BannerArtLayout.oneBottom, BannerArtLayout.oneTop, BannerArtLayout.oneTilted];
const _layoutTwo = [BannerArtLayout.twoBottom, BannerArtLayout.twoTop];

/// Nhóm món của từng thẻ theo id công thức. Phần tử có 1 id là món đơn, 2 id là cặp món chính + canh.
const bannerPools = <BannerCard, List<List<String>>>{
  BannerCard.hot: [
    ['mi-tron-xuc-xich'],
    ['mi-xao-rau-cai'],
    ['mi-trung-hanh'],
  ],
  BannerCard.rainy: [
    ['canh-rau-cai-thit-bam'],
    ['canh-ca-chua-trung'],
    ['chao-trung-hanh'],
  ],
  BannerCard.weatherOptIn: [
    ['chao-trung-hanh'],
    ['mi-trung-hanh'],
  ],
  BannerCard.breakfast: [
    ['banh-mi-trung-op'],
    ['chao-trung-hanh'],
    ['mi-trung-hanh'],
  ],
  BannerCard.lunch: [
    ['com-rang-dua-cai'],
    ['com-xuc-xich-noi-com'],
    ['khoai-tay-xao-thit-bam'],
  ],
  BannerCard.dinner: [
    ['dau-phu-sot-ca-chua', 'canh-ca-chua-trung'],
    ['xuc-xich-sot-ca-chua', 'canh-rau-cai-thit-bam'],
    ['trung-hap-thit-bam', 'canh-ca-chua-trung'],
  ],
  BannerCard.fridge: [
    ['trung-chien-hanh'],
    ['canh-ca-chua-trung'],
    ['trung-hap-thit-bam'],
  ],
  BannerCard.endOfMonth: [
    ['khoai-lang-vi-song'],
    ['com-xuc-xich-noi-com'],
    ['khoai-tay-xao-thit-bam'],
  ],
};

/// Ảnh của một thẻ: 1 hoặc 2 đường dẫn ảnh (ảnh đầu là ảnh chính) và kiểu bố cục.
@immutable
class BannerArt {
  const BannerArt({required this.imageAssets, required this.layout});

  final List<String> imageAssets;
  final BannerArtLayout layout;

  @override
  bool operator ==(Object other) =>
      other is BannerArt && other.layout == layout && listEquals(other.imageAssets, imageAssets);

  @override
  int get hashCode => Object.hash(layout, Object.hashAll(imageAssets));
}

/// Ngày thứ mấy trong năm, 1/1 là 1.
int dayOfYear(DateTime d) {
  return DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(d.year)).inDays + 1;
}

/// Chọn ảnh cho từng thẻ trong [cards] (theo thứ tự hiện), `null` nếu thẻ không có ảnh.
///
/// Thẻ thứ `i` lấy món `pool[(seed + i) % len]` và kiểu `(seed + i) % số kiểu`. Hai chỉ số liền nhau
/// luôn khác nhau theo mod 2 và mod 3, còn món đơn với cặp đã khác kiểu, nên hai thẻ liền nhau
/// không bao giờ trùng kiểu. [imageById] ánh xạ id công thức sang `Recipe.imageAsset`.
List<BannerArt?> pickBannerArt({
  required List<BannerCard> cards,
  required int seed,
  required Map<String, String> imageById,
  Map<BannerCard, List<List<String>>> pools = bannerPools,
}) {
  return [
    for (var i = 0; i < cards.length; i++) _pickOne(pools[cards[i]], seed + i, imageById),
  ];
}

BannerArt? _pickOne(List<List<String>>? pool, int n, Map<String, String> imageById) {
  if (pool == null || pool.isEmpty) return null;
  final ids = pool[n % pool.length];
  if (ids.isEmpty) return null;
  final assets = <String>[];
  for (final id in ids) {
    final path = imageById[id];
    if (path == null || path.isEmpty) return null;
    assets.add(path);
  }
  final layouts = assets.length == 1 ? _layoutOne : _layoutTwo;
  return BannerArt(imageAssets: assets, layout: layouts[n % layouts.length]);
}
