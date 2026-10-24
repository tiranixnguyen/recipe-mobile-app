import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Ô tìm món hoặc nguyên liệu (component `SearchField`), đầu màn Khám phá và Tìm kiếm.
///
/// Cao 48, viền `outline`, bo `radius-md`; focus có viền `chili` 2px (từ `inputDecorationTheme`).
/// Ở màn Khám phá, đặt [readOnly] và [onTap] để bấm vào thì mở màn Tìm kiếm.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder = 'Tìm món, nguyên liệu…',
    this.label = 'Tìm công thức',
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String placeholder;

  /// Nhãn cho trình đọc màn hình.
  final String label;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        readOnly: readOnly,
        onTap: onTap,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.body.copyWith(color: colors.ink),
        decoration: InputDecoration(
          hintText: placeholder,
          constraints: const BoxConstraints.tightFor(height: 48),
          contentPadding: const EdgeInsets.only(right: AppSpacing.s4),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s4, right: AppSpacing.s2),
            child: Icon(AppIcons.search, size: 20, color: colors.inkMuted),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
