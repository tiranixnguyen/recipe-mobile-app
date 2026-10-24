import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Phiên bản app (Cài đặt, Giới thiệu), ví dụ `0.1.0`. Test override để khỏi gọi platform.
final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);
