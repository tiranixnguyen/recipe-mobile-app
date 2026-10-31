import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/presentation/pantry_update/pantry_update_view_model.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Màn cập nhật tủ đồ sau khi nấu xong: tick nguyên liệu còn dư, xoá những thứ đã hết.
class PantryUpdateScreen extends ConsumerWidget {
  const PantryUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pantryUpdateViewModelProvider);
    if (state == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(CookStrings.pantryUpdateTitle)),
        body: const SizedBox.shrink(),
      );
    }
    return _PantryUpdate(state: state);
  }
}

class _PantryUpdate extends ConsumerWidget {
  const _PantryUpdate({required this.state});

  final PantryUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(pantryUpdateViewModelProvider.notifier);
    final toRemove = state.toRemove;

    Future<void> finish() async {
      final router = GoRouter.of(context);
      final entryId = await viewModel.finish();
      if (entryId != null) router.go(historyHighlightLocation(entryId));
    }

    return Scaffold(
      appBar: AppBar(title: const Text(CookStrings.pantryUpdateTitle)),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s3,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                children: [
                  Text(
                    CookStrings.pantryUpdateHint,
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  for (final item in state.items)
                    _IngredientRow(
                      item: item,
                      kept: state.kept.contains(item.ingredientId),
                      onToggle: () => viewModel.toggleKeep(item.ingredientId),
                    ),
                  const SizedBox(height: AppSpacing.s3),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      toRemove.isEmpty
                          ? CookStrings.pantryWillRemoveNothing
                          : CookStrings.pantryWillRemove(
                              toRemove.map((i) => i.name.toLowerCase()).join(', '),
                            ),
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s4 + MediaQuery.paddingOf(context).bottom,
              ),
              child: AppButton(
                label: CookStrings.pantryUpdateFinish,
                size: AppButtonSize.lg,
                block: true,
                onPressed: state.finishing ? null : finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    required this.kept,
    required this.onToggle,
  });

  final UsedItem item;
  final bool kept;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: CookStrings.pantryStillHaveLabel(item.name),
      toggled: kept,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.body.copyWith(color: colors.ink)),
                      Text(
                        item.note,
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              ExcludeSemantics(
                child: Text(
                  CookStrings.pantryStillHave,
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ),
              ExcludeSemantics(
                child: Checkbox(
                  value: kept,
                  onChanged: (_) => onToggle(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
