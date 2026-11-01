import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_view_model.dart';
import 'package:recipe_mobile_app/features/plan/routes.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Danh sách đi chợ (prototype `Shopping`): nguyên liệu của thực đơn tuần này cộng đồ tự thêm, đã
/// trừ Tủ đồ, nhóm theo loại; tick đã mua rồi "Xong, cất vào tủ".
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final value = ref.watch(shoppingViewModelProvider);
    final state = value.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s1),
              child: Row(
                children: [
                  IconButton(
                    tooltip: PlanStrings.backToPlan,
                    onPressed: () => context.canPop() ? context.pop() : context.go(planLocation()),
                    icon: const Icon(AppIcons.back),
                    color: colors.ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            PlanStrings.shoppingTitle,
                            style: AppTextStyles.title.copyWith(color: colors.ink),
                          ),
                        ),
                        if (state != null)
                          Text(
                            PlanStrings.shoppingProgress(state.doneCount, state.total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (value) {
                AsyncData(value: final state) => _ShoppingBody(state: state),
                AsyncError() => const Center(
                  child: EmptyState(
                    icon: AppIcons.alert,
                    title: PlanStrings.shoppingLoadError,
                    message: PlanStrings.shoppingLoadErrorBody,
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: state == null || state.isEmpty ? null : _ShoppingFooter(state: state),
    );
  }
}

class _ShoppingBody extends ConsumerWidget {
  const _ShoppingBody({required this.state});

  final ShoppingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final inPantry = state.inPantry.isEmpty
        ? null
        : InlineBanner(text: PlanStrings.shoppingInPantry(state.inPantry));
    if (state.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          ?inPantry,
          const SizedBox(height: AppSpacing.s6),
          const EmptyState(
            icon: AppIcons.basket,
            title: PlanStrings.shoppingEmptyTitle,
            message: PlanStrings.shoppingEmptyBody,
          ),
        ],
      );
    }
    final viewModel = ref.read(shoppingViewModelProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      children: [
        if (inPantry != null) ...[inPantry, const SizedBox(height: AppSpacing.s2)],
        for (final group in state.groups) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s1, top: AppSpacing.s2),
            child: Semantics(
              header: true,
              child: Text(
                group.group.label,
                style: AppTextStyles.label.copyWith(color: colors.inkMuted),
              ),
            ),
          ),
          Material(
            color: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colors.line),
              borderRadius: AppRadius.mdAll,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, row) in group.rows.indexed)
                  _ShoppingRow(
                    row: row,
                    checked: state.done.contains(row.id),
                    onChanged: (_) => viewModel.toggle(row.id),
                    isLast: i == group.rows.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.row,
    required this.checked,
    required this.onChanged,
    required this.isLast,
  });

  final ShoppingRow row;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colors.line)),
      ),
      child: CheckboxListTile(
        value: checked,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        title: Text(
          row.name,
          style: AppTextStyles.body.copyWith(
            color: checked ? colors.inkMuted : colors.ink,
            decoration: checked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          row.uses ?? PlanStrings.shoppingSelfAdded,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
        ),
        activeColor: colors.herb,
      ),
    );
  }
}

class _ShoppingFooter extends ConsumerWidget {
  const _ShoppingFooter({required this.state});

  final ShoppingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    Future<void> finish() async {
      final router = GoRouter.of(context);
      final stored = await ref.read(shoppingViewModelProvider.notifier).complete();
      if (!context.mounted || stored == 0) return;
      AppSnackbar.show(context, PlanStrings.shoppingStored(stored));
      router.go(pantryLocation);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PlanStrings.shoppingFooterHint,
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s2),
              AppButton(
                label: PlanStrings.shoppingFinish,
                block: true,
                onPressed: state.doneCount == 0 ? null : finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
