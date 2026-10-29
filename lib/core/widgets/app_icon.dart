import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Bộ icon của design (`docs/design/design-system/components/Icon/README.md`), map sang Material
/// Symbols Rounded. Tên hằng đúng tên trong design; dùng `Icon(AppIcons.search)`.
///
/// - Không truyền `color`: icon theo màu chữ xung quanh (`IconTheme`), tức `ink`, `inkMuted`, hoặc
///   `chili` khi đang chọn.
/// - Cỡ 24 (mặc định) cho tab, nút, hàng cài đặt; 20 trong dòng meta, chip.
/// - Trạng thái "đã chọn" tô đặc bằng `fill: 1`, ví dụ món đã lưu: `Icon(AppIcons.bookmark, fill: 1)`.
abstract final class AppIcons {
  static const search = Symbols.search_rounded;
  static const clock = Symbols.schedule_rounded;
  static const person = Symbols.person_rounded;
  static const heart = Symbols.favorite_rounded;
  static const home = Symbols.home_rounded;
  static const bowl = Symbols.rice_bowl_rounded;
  static const list = Symbols.list_rounded;
  static const plus = Symbols.add_rounded;
  static const check = Symbols.check_rounded;

  /// Tab Khám phá.
  static const compass = Symbols.explore_rounded;

  /// Tab Tủ đồ.
  static const fridge = Symbols.kitchen_rounded;

  /// Tab Thực đơn.
  static const calendar = Symbols.calendar_month_rounded;

  /// Tab Đã lưu và nút lưu món.
  static const bookmark = Symbols.bookmark_rounded;

  /// "Đổi món".
  static const shuffle = Symbols.shuffle_rounded;
  static const back = Symbols.arrow_back_rounded;

  /// Mở cài đặt dụng cụ và chế độ ăn.
  static const sliders = Symbols.tune_rounded;
  static const timer = Symbols.timer_rounded;
  static const minus = Symbols.remove_rounded;

  /// Thoát chế độ nấu.
  static const close = Symbols.close_rounded;

  /// Đánh giá món: Ngon.
  static const smile = Symbols.sentiment_satisfied_rounded;

  /// Đánh giá món: Tạm.
  static const meh = Symbols.sentiment_neutral_rounded;

  /// Đánh giá món: Chê.
  static const frown = Symbols.sentiment_dissatisfied_rounded;
  static const bell = Symbols.notifications_rounded;
  static const trash = Symbols.delete_rounded;

  /// Cuối hàng cài đặt.
  static const chevron = Symbols.chevron_right_rounded;
  static const alert = Symbols.error_rounded;
  static const info = Symbols.info_rounded;
  static const shield = Symbols.shield_rounded;
  static const mail = Symbols.mail_rounded;
  static const image = Symbols.image_rounded;

  /// Giao diện Sáng.
  static const sun = Symbols.light_mode_rounded;

  /// Giao diện Tối.
  static const moon = Symbols.dark_mode_rounded;

  /// Giao diện Theo hệ thống.
  static const device = Symbols.smartphone_rounded;

  /// Nút nổi Đi chợ (`ShoppingFab`). Prototype Pantry/MealPlan vẽ SVG riêng, README Icon chưa có.
  static const basket = Symbols.shopping_basket_rounded;

  /// Tên trong design → icon. Dùng cho test và trang xem theme.
  static const byName = <String, IconData>{
    'search': search,
    'clock': clock,
    'person': person,
    'heart': heart,
    'home': home,
    'bowl': bowl,
    'list': list,
    'plus': plus,
    'check': check,
    'compass': compass,
    'fridge': fridge,
    'calendar': calendar,
    'bookmark': bookmark,
    'shuffle': shuffle,
    'back': back,
    'sliders': sliders,
    'timer': timer,
    'minus': minus,
    'close': close,
    'smile': smile,
    'meh': meh,
    'frown': frown,
    'bell': bell,
    'trash': trash,
    'chevron': chevron,
    'alert': alert,
    'info': info,
    'shield': shield,
    'mail': mail,
    'image': image,
    'sun': sun,
    'moon': moon,
    'device': device,
    'basket': basket,
  };
}
