import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';

const _tipsSeenKey = 'app.tipsSeen';

/// Id các [TipBubble] người dùng đã ẩn hoặc đã làm đúng thao tác; mỗi mẹo chỉ hiện một lần.
class TipsSeenController extends Notifier<Set<String>> {
  @override
  Set<String> build() => Set.unmodifiable(ref.watch(localStoreProvider).readList(_tipsSeenKey));

  /// Gọi khi bấm ✕ hoặc khi người dùng vừa làm đúng thao tác mẹo chỉ (ví dụ kéo thả vào giỏ).
  Future<void> markSeen(String id) async {
    if (state.contains(id)) return;
    final seen = {...state, id};
    state = Set.unmodifiable(seen);
    await ref.read(localStoreProvider).writeList(_tipsSeenKey, seen.toList());
  }
}

/// Đọc: `ref.watch(tipsSeenProvider)`. Ẩn mẹo: `ref.read(tipsSeenProvider.notifier).markSeen(id)`.
final tipsSeenProvider = NotifierProvider<TipsSeenController, Set<String>>(TipsSeenController.new);

enum TipAnchor {
  /// Không mũi tên, mẹo đứng riêng trong nội dung.
  none,

  /// Mũi tên 6px ở cạnh phải trỏ vào nút bên cạnh (Tủ đồ → nút Đi chợ).
  right,
}

/// Mẹo chỉ cách dùng một thao tác ẩn (nhấn giữ, kéo thả), theo board `Toasts`.
///
/// Mỗi [id] chỉ hiện một lần (lưu ở `app.tipsSeen`). Ẩn khi bấm ✕, khi feature gọi
/// `markSeen(id)` vì người dùng đã làm đúng thao tác, và tạm ẩn khi đang có snackbar. [text] là một câu,
/// widget tự thêm "**Mẹo:**" ở đầu.
class TipBubble extends ConsumerWidget {
  const TipBubble({super.key, required this.id, required this.text, this.anchor = TipAnchor.none});

  final String id;
  final String text;
  final TipAnchor anchor;

  static const prefix = 'Mẹo:';
  static const dismissLabel = 'Ẩn mẹo';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tipsSeenProvider).contains(id)) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: AppSnackbar.visible,
      builder: (context, snackVisible, child) => snackVisible ? const SizedBox.shrink() : child!,
      child: _Bubble(
        text: text,
        anchor: anchor,
        onDismiss: () => ref.read(tipsSeenProvider.notifier).markSeen(id),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.anchor, required this.onDismiss});

  final String text;
  final TipAnchor anchor;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = AppTextStyles.caption.copyWith(color: colors.surface);
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: AppRadius.mdAll,
        boxShadow: const [
          // Bóng nhẹ `0 6px 16px rgba(20,14,10,.2)` như board, giống nhau ở hai theme.
          BoxShadow(color: Color(0x33140E0A), offset: Offset(0, 6), blurRadius: 16),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '${TipBubble.prefix} ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: text),
                  ],
                ),
                style: style,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onDismiss,
              tooltip: TipBubble.dismissLabel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: ExcludeSemantics(
                child: Text('✕', style: AppTextStyles.label.copyWith(color: colors.surface)),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      child: switch (anchor) {
        TipAnchor.none => bubble,
        TipAnchor.right => Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            Positioned(
              right: -6,
              top: 22,
              child: CustomPaint(
                key: const ValueKey('tip-arrow'),
                size: const Size(6, 12),
                painter: _ArrowPainter(colors.ink),
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// Tam giác trỏ sang phải, như `.tip.arrow:after` trong board.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => color != oldDelegate.color;
}
