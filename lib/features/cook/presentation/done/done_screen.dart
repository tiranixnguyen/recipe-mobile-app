import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/done/done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Nấu xong (prototype `CookDone`): đánh giá, ghi chú, rồi sang PantryUpdate.
class DoneScreen extends ConsumerWidget {
  const DoneScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(doneViewModelProvider(recipeId))) {
      AsyncData(:final value) => _Done(state: value),
      AsyncError(error: RecipeNotFound()) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            title: CookStrings.notFoundTitle,
            message: CookStrings.notFoundBody,
            actionLabel: CookStrings.notFoundAction,
            onAction: () => context.go(planLocation()),
          ),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            CookStrings.loadError,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Done extends ConsumerStatefulWidget {
  const _Done({required this.state});

  final DoneState state;

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.state.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(doneViewModelProvider(widget.state.recipe.id)).value ?? widget.state;
    final recipe = state.recipe;
    final viewModel = ref.read(doneViewModelProvider(recipe.id).notifier);

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
                  40,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                children: [
                  DoneHero(
                    meta: CookStrings.doneMeta(recipe.name, state.servings, recipe.steps.length),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  const SectionHeader(title: CookStrings.howWasIt),
                  const SizedBox(height: AppSpacing.s2),
                  RatingGrid(selected: state.rating, onSelect: viewModel.rate),
                  const SizedBox(height: AppSpacing.s4),
                  const SectionHeader(title: CookStrings.doneNote),
                  const SizedBox(height: AppSpacing.s2),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: 300,
                    onChanged: viewModel.setNote,
                    decoration: InputDecoration(
                      hintText: CookStrings.doneNoteHint,
                      hintStyle: AppTextStyles.body.copyWith(color: colors.inkMuted),
                      counterStyle: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                  ),
                  if (state.rating == CookRating.bad) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      CookStrings.demotedNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: context.colors.inkMuted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      toggled: state.saved,
                      child: TextButton.icon(
                        onPressed: viewModel.toggleSaved,
                        icon: Icon(AppIcons.bookmark, size: 20, fill: state.saved ? 1 : 0),
                        label: Text(state.saved ? CookStrings.saved : CookStrings.saveForLater),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.chiliDeep,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CookFooter(
              child: AppButton(
                label: CookStrings.doneNoteToPantry,
                size: AppButtonSize.lg,
                block: true,
                onPressed: state.finishing ? null : goToPantryUpdate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
