import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Tạm: core không được phụ thuộc app/feature, bỏ ba import này cùng nút Cài đặt và nút xem theme
// khi màn Khám phá (DSC-01) có nút Cài đặt trên header.
import '../../app/strings.dart';
import '../../app/theme_preview_screen.dart';
import '../../features/system/system.dart';
import '../theme/theme.dart';

/// Màn tạm Lead tạo sẵn cho mỗi feature; chủ feature thay bằng màn thật.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đang làm…'),
            const SizedBox(height: AppSpacing.s4),
            // Tạm để vào Cài đặt khi chưa có màn Khám phá.
            OutlinedButton(
              onPressed: () => context.push(settingsLocation),
              child: const Text('Cài đặt'),
            ),
            if (kDebugMode)
              TextButton(
                onPressed: () => context.push(themePreviewLocation),
                child: const Text(AppStrings.themePreview),
              ),
          ],
        ),
      ),
    );
  }
}
