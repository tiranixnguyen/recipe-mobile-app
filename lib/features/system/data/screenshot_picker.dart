import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Chọn một ảnh trong thư viện (ảnh chụp màn hình để đính kèm góp ý); null khi người dùng huỷ.
/// Test override để khỏi gọi platform.
final pickScreenshotProvider = Provider<Future<Uint8List?> Function()>(
  (ref) => () async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Thu nhỏ ảnh chụp màn hình cho nhẹ mà vẫn đọc được chữ.
      maxWidth: 1200,
      maxHeight: 2600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file?.readAsBytes();
  },
);
