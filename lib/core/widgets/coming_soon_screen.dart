import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Tạm: core không được phụ thuộc app/feature. Bỏ import `app/strings`, `app/theme_preview_screen` và
// `features/system` cùng nút Cài đặt, nút xem theme khi màn Khám phá (DSC-01) có nút Cài đặt.
import 'package:recipe_mobile_app/app/strings.dart';
import 'package:recipe_mobile_app/app/theme_preview_screen.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

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
