import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/prep/prep_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Chuẩn bị nấu (prototype `CookPrep`): khẩu phần, checklist "Lấy đồ ra", đồ còn thiếu; dưới cùng
/// "Bắt đầu nấu" sang Từng bước.
class PrepScreen extends ConsumerWidget {
  const PrepScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(prepViewModelProvider(recipeId))) {
      AsyncData(:final value) => _Prep(state: value),
      AsyncError(error: RecipeNotFound()) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            title: CookStrings.notFoundTitle,
            message: CookStrings.notFoundBody,
            actionLabel: CookStrings.notFoundAction,
            onAction: () => context.go(discoverLocation),
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

class _Prep extends ConsumerWidget {
  const _Prep({required this.state});

  final PrepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = state.recipe;
    final viewModel = ref.read(prepViewModelProvider(recipe.id).notifier);

    Future<void> start() async {
      final router = GoRouter.of(context);
      if (await viewModel.shouldAskNotificationPermission()) {
        await router.push<bool>(notifPermissionLocation);
      }
      await viewModel.start();
      // Thay màn Chuẩn bị: thoát chế độ nấu thì về Chi tiết món.
      router.pushReplacement(cookStepLocation(recipe.id));
    }

    Future<void> addToShopping() async {
      final router = GoRouter.of(context);
      await viewModel.addToShopping();
      router.push(shoppingLocation);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CookHeader(
              title: CookStrings.prepTitle,
              subtitle: recipe.name,
              icon: AppIcons.back,
              tooltip: CookStrings.backToDetail,
              onPressed: () => context.canPop() ? context.pop() : context.go(discoverLocation),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s3,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                children: [
                  ServingsBox(value: state.servings, onChanged: viewModel.setServings),
                  const SizedBox(height: AppSpacing.s5),
                  Wrap(
                    spacing: AppSpacing.s2,
                    runSpacing: AppSpacing.s2,
                    children: [
                      CookInfoChip(
                        icon: AppIcons.clock,
                        text: CookStrings.timeAndSteps(recipe.minutes, recipe.steps.length),
                      ),
                      if (recipe.tools.isNotEmpty)
                        CookInfoChip(text: recipe.tools.map((t) => t.shortLabel).join(' · ')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _Gather(state: state, onToggle: viewModel.toggle),
                  if (state.missing.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s5),
                    MissingBox(
                      missing: [for (final m in state.missing) m.name],
                      notes: state.notes,
                      onAddToShopping: addToShopping,
                    ),
                  ],
                ],
              ),
            ),
            CookFooter(
              child: AppButton(
                label: CookStrings.startCooking,
                size: AppButtonSize.lg,
                block: true,
                onPressed: start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Lấy đồ ra" kèm "Đã lấy x/y": mỗi đồ một dòng tick được, gia vị cơ bản gom dòng cuối.
class _Gather extends StatelessWidget {
  const _Gather({required this.state, required this.onToggle});

  final PrepState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final spices = state.basicSpices;
    final rows = [
      for (final item in state.gather)
        GatherRow(
          label: item.label,
          status: CookStrings.inPantry,
          checked: state.checked.contains(item.ingredientId),
          onChanged: () => onToggle(item.ingredientId),
        ),
      if (spices.isNotEmpty)
        GatherRow(
          label: spices.join(', '),
          status: CookStrings.basicSpices,
          muted: true,
          checked: state.checked.contains(PrepViewModel.spicesKey),
          onChanged: () => onToggle(PrepViewModel.spicesKey),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        SectionHeader(
          title: CookStrings.gather,
          trailing: rows.isEmpty ? null : CookStrings.gathered(state.checkedCount, state.total),
        ),
        if (rows.isNotEmpty) RowsBox(rows: rows),
      ],
    );
  }
}
