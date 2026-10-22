import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Tạm: core không được phụ thuộc app/feature, bỏ ba import này cùng nút đổi theme và nút xem theme
// khi có màn Cài đặt (SYS-02).
import '../../app/strings.dart';
import '../../app/theme_preview_screen.dart';
import '../../features/system/system.dart';
import '../theme/theme.dart';

/// Màn tạm Lead tạo sẵn cho mỗi feature; chủ feature thay bằng màn thật.
class ComingSoonScreen extends ConsumerWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đang làm…'),
            const SizedBox(height: AppSpacing.s4),
            // Tạm để xem màn ở chế độ sáng / tối; bỏ khi có màn Cài đặt.
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Theo máy')),
                ButtonSegment(value: ThemeMode.light, label: Text('Sáng')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Tối')),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (modes) => ref.read(themeModeProvider.notifier).set(modes.single),
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
