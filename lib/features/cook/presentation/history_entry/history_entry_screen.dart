import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history_entry/history_entry_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Màn chi tiết một lần nấu: xem/sửa đánh giá và ghi chú (tự lưu), xoá kèm Hoàn tác.
class HistoryEntryScreen extends ConsumerWidget {
  const HistoryEntryScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyEntryViewModelProvider(entryId));
    final entry = state.entry;
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(icon: AppIcons.bowl, title: CookStrings.historyEntryNotFound),
        ),
      );
    }
    return _HistoryEntry(
      entryId: entryId,
      entry: entry,
      nameOf: state.nameOf,
      recipes: state.recipes,
    );
  }
}

class _HistoryEntry extends ConsumerWidget {
  const _HistoryEntry({
    required this.entryId,
    required this.entry,
    required this.nameOf,
    required this.recipes,
  });

  final String entryId;
  final CookHistoryEntry entry;
  final String Function(String) nameOf;
  final Map<String, Recipe> recipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(historyEntryViewModelProvider(entryId).notifier);
    final one = entry.dishes.length == 1;
    final title = one ? nameOf(entry.dishes.first.recipeId) : entry.meal.label;

    Future<void> delete() async {
      final router = GoRouter.of(context);
      // `cookHistoryProvider` không autoDispose nên còn sống sau khi màn này đóng; dùng nó (không
      // phải viewModel riêng theo id) cho Hoàn tác, tránh gọi vào provider đã bị huỷ.
      final history = ref.read(cookHistoryProvider.notifier);
      final analytics = ref.read(analyticsProvider);
      final removed = await viewModel.delete();
      if (removed == null) return;
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(historyLocation);
      }
      if (context.mounted) {
        AppSnackbar.show(
          context,
          CookStrings.historyDeleted,
          action: SnackAction(CookStrings.undo, () {
            history.restore(removed);
            analytics.track('history_delete', {'undo': true});
          }),
        );
      }
    }

    void addToPlan() {
      final dishes = [for (final d in entry.dishes) ?recipes[d.recipeId]];
      if (dishes.isNotEmpty) showAddMealToPlanSheet(context, dishes);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: CookStrings.optional,
            onSelected: (value) {
              if (value == 'delete') delete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'delete', child: Text(CookStrings.historyDeleteAction)),
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
          SizedBox(
            height: 168,
            child: MealMosaic(
              radius: AppRadius.mdAll,
              dishes: [for (final d in entry.dishes) MosaicDish(nameOf(d.recipeId))],
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            one
                ? CookStrings.historyMetaOne(entry.servings, entry.minutes)
                : CookStrings.historyMetaMeal(entry.dishes.length, entry.servings, entry.minutes),
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s5),
          SectionHeader(
            title: one ? CookStrings.historyDishTitleOne : CookStrings.historyDishTitleMany,
          ),
          const SizedBox(height: AppSpacing.s2),
          RowsBox(
            rows: [
              for (final (i, dish) in entry.dishes.indexed)
                _DishRow(
                  name: nameOf(dish.recipeId),
                  dish: dish,
                  // Một món: chỉ chấm điểm, ghi chú dùng ô "Ghi chú" chung bên dưới.
                  showNote: !one,
                  onRate: (r) => viewModel.setDishRating(i, dish.rating == r ? null : r),
                  onNote: (n) => viewModel.setDishNote(i, n),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          SectionHeader(title: one ? CookStrings.historyNote : CookStrings.historyMealNote),
          const SizedBox(height: AppSpacing.s2),
          _NoteField(
            key: ValueKey('meal-note-$entryId'),
            initial: entry.mealNote,
            hint: CookStrings.historyNoteHint,
            onChanged: viewModel.setMealNote,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            CookStrings.historySavedHint,
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              Expanded(
                child: AppButton.secondary(label: CookStrings.addToPlan, onPressed: addToPlan),
              ),
              Expanded(
                child: AppButton(
                  label: one ? CookStrings.historyRecookOne : CookStrings.historyRecookMeal,
                  onPressed: one
                      ? () => context.push(cookPrepLocation(entry.dishes.first.recipeId))
                      : addToPlan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tên món + 3 nút chấm nhỏ trên cùng hàng; một món thì chỉ vậy (ghi chú dùng ô chung bên dưới),
/// cả bữa thì thêm ghi chú gấp lại cho từng món — theo prototype `HistoryEntry`.
class _DishRow extends StatefulWidget {
  const _DishRow({
    required this.name,
    required this.dish,
    required this.showNote,
    required this.onRate,
    required this.onNote,
  });

  final String name;
  final CookedDish dish;
  final bool showNote;
  final ValueChanged<CookRating> onRate;
  final ValueChanged<String> onNote;

  @override
  State<_DishRow> createState() => _DishRowState();
}

class _DishRowState extends State<_DishRow> {
  late final TextEditingController _controller = TextEditingController(text: widget.dish.note);
  late bool _open = widget.dish.note.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dish = widget.dish;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s2,
        children: [
          Row(
            spacing: AppSpacing.s2,
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
              ),
              for (final rating in CookRating.values)
                IconButton(
                  onPressed: () => widget.onRate(rating),
                  tooltip: CookStrings.rateDish(rating.label, widget.name),
                  isSelected: rating == dish.rating,
                  icon: Icon(ratingIcon(rating)),
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(40),
                    minimumSize: const Size.square(40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                    backgroundColor: rating == dish.rating
                        ? colors.chiliSoft
                        : colors.surfaceRaised,
                    foregroundColor: rating == dish.rating ? colors.chiliDeep : colors.ink,
                    side: BorderSide(
                      color: rating == dish.rating ? colors.chiliSoft : colors.outline,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.showNote)
            if (_open)
              TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 2,
                maxLength: 300,
                onChanged: widget.onNote,
                decoration: InputDecoration(
                  hintText: CookStrings.historyDishNoteHint,
                  hintStyle: AppTextStyles.body.copyWith(color: colors.inkMuted),
                  counterStyle: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  isDense: true,
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _open = true),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colors.chiliDeep,
                    textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: Text(CookStrings.historyAddDishNote),
                ),
              ),
        ],
      ),
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({super.key, required this.initial, required this.hint, required this.onChanged});

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
      minLines: 2,
      maxLines: 4,
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
