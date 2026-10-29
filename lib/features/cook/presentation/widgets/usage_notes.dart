import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Lưu ý của một món; [dish] là tên món, chỉ có khi nấu cả bữa.
typedef NotesGroup = ({String? dish, List<String> notes});

/// Trang "Lưu ý cách dùng": nhãn, rồi từng nhóm (tên món khi nấu cả bữa) với mỗi lưu ý một dòng có
/// dấu chấm đầu dòng. Không có lưu ý nào thì hiện "Món ăn không có lưu ý nào.".
class UsageNotes extends StatelessWidget {
  const UsageNotes({super.key, required this.groups});

  final List<NotesGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.s2);
    final shown = [
      for (final g in groups)
        if (g.notes.isNotEmpty) g,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s3,
      children: [
        Padding(
          padding: inset,
          child: Semantics(
            header: true,
            child: Text(
              CookStrings.notesLabel,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 13 * 0.04,
                color: colors.chiliDeep,
              ),
            ),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: inset,
            child: Text(
              CookStrings.noNotes,
              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
            ),
          ),
        for (final group in shown) ...[
          if (group.dish case final dish?)
            Padding(
              padding: inset.copyWith(top: AppSpacing.s1),
              child: Text(
                dish,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: colors.ink),
              ),
            ),
          RowsBox(rows: [for (final note in group.notes) _NoteRow(text: note)]),
        ],
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = AppTextStyles.body.copyWith(color: colors.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s2,
        children: [
          ExcludeSemantics(child: Text('•', style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// Câu chúc cuối trang Lưu ý, sát trên hàng nút: căn giữa, chữ `title` màu `chiliDeep`, tối đa 2
/// dòng.
class CheerLine extends StatelessWidget {
  const CheerLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s3,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.title.copyWith(color: context.colors.chiliDeep),
      ),
    );
  }
}
