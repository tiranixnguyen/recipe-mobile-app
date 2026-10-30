import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/day_strip.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_done/meal_done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Nấu xong cả bữa: chấm từng món, ghi chú, rồi sang PantryUpdate.
class MealDoneScreen extends ConsumerWidget {
  const MealDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(mealDoneViewModelProvider)) {
      AsyncData(:final value) => _MealDone(state: value),
      AsyncError() => const NoMealScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _MealDone extends ConsumerWidget {
  const _MealDone({required this.state});

  final MealDoneState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(mealDoneViewModelProvider.notifier);
    final dayName = DayStrip.fullNames[state.slot.day.weekday - 1];

    Future<void> goToPantryUpdate() async {
      await viewModel.finish();
      if (context.mounted) context.push(pantryUpdateLocation);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s6,
                  AppSpacing.s4,
                  AppSpacing.s3,
                ),
                children: [
                  DoneHero(
                    title: CookStrings.mealDoneTitle(state.slot.meal),
                    meta: CookStrings.mealDoneMeta(
                      state.dishes.length,
                      state.servings,
                      state.minutes,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  const SectionHeader(title: CookStrings.rateEach),
                  const SizedBox(height: AppSpacing.s2),
                  RowsBox(
                    rows: [
                      for (final (i, d) in state.dishes.indexed)
                        _DishRow(
                          name: d.recipe.name,
                          selected: state.ratings[i],
                          note: state.dishNotes[i] ?? '',
                          onSelect: (rating) => viewModel.rate(i, rating),
                          onNoteChanged: (note) => viewModel.setDishNote(i, note),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  const SectionHeader(title: CookStrings.mealDoneNote),
                  const SizedBox(height: AppSpacing.s2),
                  _NoteField(
                    initial: state.mealNote,
                    hint: CookStrings.mealDoneNoteHint,
                    onChanged: viewModel.setMealNote,
                  ),
                ],
              ),
            ),
            CookFooter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.s2,
                children: [
                  Text(
                    CookStrings.mealMarked(state.slot.meal, dayName),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                  AppButton(
                    label: CookStrings.finishAndUpdate,
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: state.finishing ? null : goToPantryUpdate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({
    required this.name,
    required this.selected,
    required this.note,
    required this.onSelect,
    required this.onNoteChanged,
  });

  final String name;
  final CookRating? selected;
  final String note;
  final ValueChanged<CookRating> onSelect;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = this.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Row(
              spacing: AppSpacing.s2,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          selected == null
                              ? CookStrings.notRated
                              : CookStrings.ratedAs(selected.label),
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final rating in CookRating.values)
                  IconButton(
                    onPressed: () => onSelect(rating),
                    tooltip: CookStrings.rateDish(rating.label, name),
                    isSelected: rating == selected,
                    icon: Icon(ratingIcon(rating)),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(44),
                      minimumSize: const Size.square(44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                      backgroundColor: rating == selected ? colors.chiliSoft : colors.surfaceRaised,
                      foregroundColor: rating == selected ? colors.chiliDeep : colors.ink,
                      side: BorderSide(
                        color: rating == selected ? colors.chiliSoft : colors.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            controller: TextEditingController(text: note),
            maxLines: 2,
            maxLength: 300,
            onChanged: onNoteChanged,
            decoration: InputDecoration(
              hintText: CookStrings.mealDishNoteHint,
              hintStyle: AppTextStyles.body.copyWith(color: colors.inkMuted),
              counterStyle: AppTextStyles.caption.copyWith(color: colors.inkMuted),
              isDense: true,
            ),
          ),
        ],
      ),
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
