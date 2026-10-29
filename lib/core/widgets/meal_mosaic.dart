import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Một món trong [MealMosaic]: tên để đọc cho trình đọc màn hình, ảnh như `Recipe.imageAsset`.
class MosaicDish {
  const MosaicDish(this.name, [this.imageAsset]);

  final String name;
  final String? imageAsset;
}

/// Ghép ảnh một bữa nhiều món (hàm `mosaic()` trong prototype `Today`, `Saved`).
///
/// 1 món đầy khung; 2 món chia đôi dọc; 3 món ô trái 60% và hai ô chồng bên phải; từ 4 món lưới 2×2,
/// quá 4 món thì ô cuối phủ mờ ghi "+N món" (N = số món − 3). Khe giữa các ô 2px.
///
/// Không truyền [size] thì lấp đầy chỗ cha cho (Hôm nay ăn gì: cao 168); truyền [size] cho ô vuông
/// ("Hoặc thử" 48, Đã lưu tab Bữa ăn 96).
class MealMosaic extends StatelessWidget {
  const MealMosaic({super.key, required this.dishes, this.size, this.radius});

  final List<MosaicDish> dishes;
  final double? size;

  /// Bo góc theo thẻ chứa mosaic; mặc định không bo.
  final BorderRadius? radius;

  /// Ô nhỏ hơn cỡ này chỉ ghi "+N" chữ 12, như Đã lưu; không đủ chỗ cho chữ "món".
  static const _compactTile = 64.0;

  /// Vị trí từng ô theo tỉ lệ khung (trái, trên, rộng, cao), như `boxes` trong prototype.
  static List<Rect> boxes(int count) => switch (count) {
    <= 1 => const [Rect.fromLTWH(0, 0, 1, 1)],
    2 => const [Rect.fromLTWH(0, 0, .5, 1), Rect.fromLTWH(.5, 0, .5, 1)],
    3 => const [
      Rect.fromLTWH(0, 0, .6, 1),
      Rect.fromLTWH(.6, 0, .4, .5),
      Rect.fromLTWH(.6, .5, .4, .5),
    ],
    _ => const [
      Rect.fromLTWH(0, 0, .5, .5),
      Rect.fromLTWH(.5, 0, .5, .5),
      Rect.fromLTWH(0, .5, .5, .5),
      Rect.fromLTWH(.5, .5, .5, .5),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final more = dishes.length > 4 ? dishes.length - 3 : 0;

    final mosaic = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final rects = boxes(dishes.length);
        return Stack(
          children: [
            for (final (i, box) in rects.indexed)
              Positioned(
                left: box.left * width,
                top: box.top * height,
                width: box.width * width,
                height: box.height * height,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: i == 3 && more > 0
                      ? _Tile(
                          dish: dishes[i],
                          label: dishes.skip(3).map((d) => d.name).join(', '),
                          more: '+$more',
                          compact: box.width * width < _compactTile,
                        )
                      : _Tile(
                          dish: i < dishes.length ? dishes[i] : null,
                          label: i < dishes.length ? dishes[i].name : '',
                        ),
                ),
              ),
          ],
        );
      },
    );

    final framed = ColoredBox(
      color: colors.surfaceRaised,
      child: radius == null ? mosaic : ClipRRect(borderRadius: radius!, child: mosaic),
    );
    final size = this.size;
    return size == null ? framed : SizedBox.square(dimension: size, child: framed);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.dish, required this.label, this.more, this.compact = false});

  final MosaicDish? dish;
  final String label;
  final String? more;

  /// Ô nhỏ (Đã lưu 96, "Hoặc thử" 48) ghi "+N" chữ 12; ô lớn (Hôm nay ăn gì) ghi "+N món" chữ 17.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final asset = dish?.imageAsset;
    final more = this.more;
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset == null || asset.isEmpty)
            const _Placeholder()
          else
            Image.asset(
              asset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const _Placeholder(),
            ),
          if (more != null)
            ColoredBox(
              // Lớp phủ `rgba(20,14,10,.55)` chữ trắng như prototype, giống nhau ở hai theme.
              color: const Color(0x8C140E0A),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    compact ? more : '$more món',
                    style: (compact ? AppTextStyles.caption : AppTextStyles.subtitle).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chưa có ảnh: bát `chili` trên nền `chiliSoft` như `RecipeCover`, icon co theo cỡ ô.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.chiliSoft,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: Icon(
            AppIcons.bowl,
            size: (constraints.biggest.shortestSide * .4).clamp(12, 48),
            color: colors.chili,
          ),
        ),
      ),
    );
  }
}
