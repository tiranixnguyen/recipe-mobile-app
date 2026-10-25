import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ghi sự kiện sử dụng (không có dữ liệu cá nhân). Danh sách sự kiện ở mục *Analytics* trong
/// `AGENTS.md`; tên snake_case, tham số chỉ là số, bool hoặc chuỗi ngắn cố định.
///
/// Hiện là stub ([DebugAnalytics]). TODO(SET-16): bản Firebase Analytics, chữ ký giữ nguyên.
abstract interface class Analytics {
  void track(String event, [Map<String, Object>? params]);
}

/// In sự kiện ra log khi chạy debug.
class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void track(String event, [Map<String, Object>? params]) =>
      debugPrint('analytics: $event ${params ?? const {}}');
}

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());
