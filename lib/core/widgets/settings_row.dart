import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_icon.dart';

/// Một nhóm hàng cài đặt theo prototype `Settings`: tiêu đề nhỏ màu `inkMuted` phía trên, khung
/// `surfaceRaised` viền `line`, đường kẻ giữa các hàng.
///
/// ```dart
/// SettingsGroup(title: 'Dữ liệu', children: [
///   SettingsRow(icon: AppIcons.trash, title: 'Xoá dữ liệu trên máy', danger: true, onTap: …),
/// ])
/// ```
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;

  /// Thường là [SettingsRow].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = this.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.label.copyWith(color: colors.inkMuted)),
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
        Material(
          color: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.line),
            borderRadius: AppRadius.mdAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Một hàng trong [SettingsGroup]: icon, tiêu đề, ghi chú tuỳ chọn, rồi chevron (khi bấm được) hoặc
/// công tắc ([SettingsRow.toggle]).
///
/// [danger] cho hành động không hoàn tác được (Xoá dữ liệu): chữ và icon `dangerInk`, không chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    required this.title,
    this.note,
    this.onTap,
    this.danger = false,
  }) : value = null,
       onChanged = null;

  /// Hàng có công tắc bật/tắt; bấm cả hàng là đổi.
  const SettingsRow.toggle({
    super.key,
    this.icon,
    required this.title,
    this.note,
    required bool this.value,
    required ValueChanged<bool> this.onChanged,
  }) : onTap = null,
       danger = false;

  final IconData? icon;
  final String title;

  /// Dòng phụ dưới tiêu đề, cỡ `caption` màu `inkMuted`.
  final String? note;
  final VoidCallback? onTap;
  final bool danger;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = danger ? colors.dangerInk : colors.ink;
    final icon = this.icon;
    final note = this.note;
    final value = this.value;
    final onChanged = this.onChanged;

    final row = InkWell(
      onTap: value != null ? () => onChanged!(!value) : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: IconTheme.merge(
          data: IconThemeData(color: color, size: 24),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: AppSpacing.s3)],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: color,
                          fontWeight: danger ? FontWeight.w600 : null,
                        ),
                      ),
                      if (note != null)
                        Text(note, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),
                    ],
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.s3),
                ExcludeSemantics(
                  child: _Switch(value: value, onChanged: onChanged!),
                ),
              ] else if (onTap != null && !danger) ...[
                const SizedBox(width: AppSpacing.s3),
                Icon(AppIcons.chevron, color: colors.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );

    if (value == null) return Semantics(button: onTap != null, child: row);
    return MergeSemantics(
      child: Semantics(toggled: value, child: row),
    );
  }
}

/// Công tắc theo prototype: track `herb` khi bật, `outline` khi tắt, nút tròn trắng không viền.
class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: colors.herb,
      inactiveTrackColor: colors.outline,
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
