import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/features/system/data/app_info.dart';

/// Thông tin máy gửi kèm góp ý khi người dùng đồng ý. Test override để khỏi gọi platform.
final deviceInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final version = await ref.watch(appVersionProvider.future);
  final android = await DeviceInfoPlugin().androidInfo;
  return {
    'app': version,
    'android': android.version.release,
    'sdk': '${android.version.sdkInt}',
    'device': '${android.manufacturer} ${android.model}',
  };
});
