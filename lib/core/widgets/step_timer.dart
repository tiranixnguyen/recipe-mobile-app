import 'dart:async';

import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

enum StepTimerStatus { idle, running, done }

/// Hẹn giờ cho một bước nấu (component `StepTimer`).
///
/// - Chờ: nút phụ "Hẹn 3 phút" / "Hẹn 45 giây".
/// - Đang chạy: thanh nền `ink`, tên việc ([label]) và số lớn `02:45`, nút "Dừng".
/// - Hết giờ: thanh nền `chili`, "Hết giờ · …" và "Xong!", nút "Tắt".
///
/// Thời gian tính theo giờ hệ thống (lưu mốc kết thúc), nên app bị tạm dừng hay timer vẽ trễ vẫn
/// đúng; timer bên trong chỉ để vẽ lại. Màn chủ dùng [onStatusChange] để giữ thanh đang chạy luôn
/// hiện khi người dùng sang bước khác, và [onDone] để rung, báo.
///
/// Mỗi bước một StepTimer riêng (đặt `key` theo bước); đổi [seconds] khi đang chạy không dời mốc
/// đã hẹn.
class StepTimer extends StatefulWidget {
  const StepTimer({
    super.key,
    required this.seconds,
    this.label = '',
    this.autoStart = false,
    this.onStatusChange,
    this.onDone,
    this.clock = DateTime.now,
  });

  /// Thời lượng của bước, tính bằng giây.
  final int seconds;

  /// Tên việc đang hẹn giờ, ví dụ "Chiên mặt dưới".
  final String label;

  /// Bắt đầu đếm ngay khi hiện.
  final bool autoStart;
  final ValueChanged<StepTimerStatus>? onStatusChange;
  final VoidCallback? onDone;

  /// Giờ hiện tại; test truyền đồng hồ giả.
  final DateTime Function() clock;

  /// "3 phút", "45 giây", "01:30".
  static String durationLabel(int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60} phút';
    if (seconds >= 60) return mmss(seconds);
    return '$seconds giây';
  }

  /// `165` → `02:45`.
  static String mmss(int seconds) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(seconds ~/ 60)}:${two(seconds % 60)}';
  }

  @override
  State<StepTimer> createState() => _StepTimerState();
}

class _StepTimerState extends State<StepTimer> {
  DateTime? _endAt;
  Timer? _ticker;
  StepTimerStatus _status = StepTimerStatus.idle;

  @override
  void initState() {
    super.initState();
    if (!widget.autoStart) return;
    _start(notify: false);
    // Báo sau frame đầu: màn cha có thể setState trong onStatusChange, không gọi được lúc đang build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _status == StepTimerStatus.running) {
        widget.onStatusChange?.call(StepTimerStatus.running);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Số giây còn lại, làm tròn lên để `00:00` chỉ hiện đúng lúc hết giờ.
  int get _remaining {
    final endAt = _endAt;
    if (endAt == null) return widget.seconds;
    final ms = endAt.difference(widget.clock()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _start({bool notify = true}) {
    _endAt = widget.clock().add(Duration(seconds: widget.seconds));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _setStatus(StepTimerStatus.running, notify: notify);
  }

  void _tick() {
    if (_remaining > 0) {
      setState(() {});
      return;
    }
    _ticker?.cancel();
    _setStatus(StepTimerStatus.done);
    widget.onDone?.call();
  }

  void _reset() {
    _ticker?.cancel();
    _endAt = null;
    _setStatus(StepTimerStatus.idle);
  }

  /// [notify] false chỉ dùng trong `initState`: chưa build nên không setState, chưa báo ra ngoài.
  void _setStatus(StepTimerStatus status, {bool notify = true}) {
    if (!notify) {
      _status = status;
      return;
    }
    setState(() => _status = status);
    widget.onStatusChange?.call(status);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == StepTimerStatus.idle) {
      return AppButton.secondary(
        label: 'Hẹn ${StepTimer.durationLabel(widget.seconds)}',
        icon: AppIcons.timer,
        onPressed: _start,
      );
    }

    final colors = context.colors;
    final done = _status == StepTimerStatus.done;
    // Hết giờ: chữ trắng trên `chili` như design. Đang chạy: chữ `surface` trên `ink`.
    final foreground = done ? Colors.white : colors.surface;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 10, AppSpacing.s2, 10),
        decoration: BoxDecoration(
          color: done ? colors.chili : colors.ink,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          spacing: AppSpacing.s3,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    done ? 'Hết giờ · ${widget.label}' : widget.label,
                    style: AppTextStyles.caption.copyWith(
                      color: foreground.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    done ? 'Xong!' : StepTimer.mmss(_remaining),
                    style: AppTextStyles.display.copyWith(
                      color: foreground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              ),
              child: Text(done ? 'Tắt' : 'Dừng'),
            ),
          ],
        ),
      ),
    );
  }
}
