import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history_entry/history_entry_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Màn chi tiết một lần nấu: xem, sửa đánh giá và ghi chú, xoá.
class HistoryEntryScreen extends ConsumerWidget {
  const HistoryEntryScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(historyEntryViewModelProvider(entryId));
    return switch (asyncState) {
      AsyncData(:final value) => _HistoryEntry(entry: value, entryId: entryId),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            title: CookStrings.historyEntryNotFound,
            icon: AppIcons.bowl,
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _HistoryEntry extends ConsumerWidget {
  const _HistoryEntry({required this.entry, required this.entryId});

  final CookHistoryEntry entry;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(historyEntryViewModelProvider(entryId).notifier);

    Future<void> delete() async {
      final deleted = await viewModel.deleteEntry();
      if (context.mounted) {
        context.pop();
        if (deleted != null) {
          AppSnackbar.show(
            context,
            CookStrings.historyDeleted,
            action: SnackAction(CookStrings.undo, () => viewModel.restore(deleted)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.isMeal
              ? CookStrings.historyEntryMealTitle(entry.meal?.label ?? '')
              : CookStrings.historyEntrySingleTitle,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') await delete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(CookStrings.historyDeleteAction),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s6,
        ),
        children: [
          // Meta
          Text(
            _metaLine(entry),
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s4),

          // Rating per dish
          if (entry.dishes.length == 1)
            _SingleDishSection(
              dish: entry.dishes.first,
              onRateChanged: (r) => viewModel.setDishRating(0, r),
              onNoteChanged: (n) => viewModel.setDishNote(0, n),
            )
          else ...[
            SectionHeader(title: CookStrings.rateEach),
            const SizedBox(height: AppSpacing.s2),
            for (final (i, dish) in entry.dishes.indexed) ...[
              _DishSection(
                dish: dish,
                onRateChanged: (r) => viewModel.setDishRating(i, r),
                onNoteChanged: (n) => viewModel.setDishNote(i, n),
              ),
              if (i < entry.dishes.length - 1) const Divider(height: AppSpacing.s4),
            ],
          ],

          // Meal note
          const SizedBox(height: AppSpacing.s4),
          SectionHeader(title: CookStrings.historyMealNote),
          const SizedBox(height: AppSpacing.s2),
          _NoteField(
            initial: entry.mealNote,
            hint: CookStrings.historyMealNoteHint,
            onChanged: viewModel.setMealNote,
          ),

          const SizedBox(height: AppSpacing.s4),

          // Nấu lại (chỉ hiện khi một món)
          if (!entry.isMeal && entry.dishes.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => context.push('/recipe/${entry.dishes.first.recipeId}'),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(CookStrings.historyReCook),
            ),
        ],
      ),
    );
  }
}

String _metaLine(CookHistoryEntry entry) {
  final parts = <String>[
    '${entry.dishes.length} món',
    '${entry.servings} người',
    if (entry.minutes case final m?) '~$m phút',
    _formatDate(entry.cookedAt),
  ];
  return parts.join(' · ');
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

class _SingleDishSection extends StatelessWidget {
  const _SingleDishSection({
    required this.dish,
    required this.onRateChanged,
    required this.onNoteChanged,
  });

  final CookSessionDish dish;
  final ValueChanged<CookRating?> onRateChanged;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: CookStrings.howWasIt),
        const SizedBox(height: AppSpacing.s2),
        RatingGrid(
          selected: dish.rating,
          onSelect: (r) => onRateChanged(dish.rating == r ? null : r),
        ),
        const SizedBox(height: AppSpacing.s3),
        SectionHeader(title: CookStrings.historyDishNote),
        const SizedBox(height: AppSpacing.s2),
        _NoteField(
          initial: dish.note,
          hint: CookStrings.historyDishNoteHint,
          onChanged: onNoteChanged,
        ),
      ],
    );
  }
}

class _DishSection extends StatelessWidget {
  const _DishSection({
    required this.dish,
    required this.onRateChanged,
    required this.onNoteChanged,
  });

  final CookSessionDish dish;
  final ValueChanged<CookRating?> onRateChanged;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          dish.recipeId,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s2),
        RatingGrid(
          selected: dish.rating,
          onSelect: (r) => onRateChanged(dish.rating == r ? null : r),
        ),
        const SizedBox(height: AppSpacing.s2),
        _NoteField(
          initial: dish.note,
          hint: CookStrings.historyDishNoteHint,
          onChanged: onNoteChanged,
        ),
      ],
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({required this.initial, required this.hint, required this.onChanged});

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _controller,
      maxLines: 3,
      maxLength: 300,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.body.copyWith(color: colors.inkMuted),
        counterStyle: AppTextStyles.caption.copyWith(color: colors.inkMuted),
      ),
    );
  }
}
