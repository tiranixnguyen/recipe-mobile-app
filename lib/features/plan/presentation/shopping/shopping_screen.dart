import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_view_model.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final value = ref.watch(shoppingViewModelProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s1),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại thực đơn',
                    onPressed: () => context.pop(),
                    icon: const Icon(AppIcons.back),
                    color: colors.ink,
                  ),
                  Expanded(
                    child: value.when(
                      loading: () => const _Header(title: PlanStrings.shopping, subtitle: null),
                      error: (_, _) => const _Header(title: PlanStrings.shopping, subtitle: null),
                      data: (state) => _Header(
                        title: PlanStrings.shopping,
                        subtitle: '${state.doneCount}/${state.total} đã mua',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: value.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorBody(error: error),
                data: (state) => _ShoppingBody(state: state),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: value is AsyncData<ShoppingState> && !value.value.isEmpty
          ? _ShoppingFooter(state: value.value)
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.title.copyWith(color: context.colors.ink)),
      if (subtitle != null)
        Text(subtitle!, style: AppTextStyles.caption.copyWith(color: context.colors.inkMuted)),
    ],
  );
}

class _ShoppingBody extends ConsumerWidget {
  const _ShoppingBody({required this.state});

  final ShoppingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: AppIcons.basket,
          title: 'Danh sách đi chợ đang trống',
          message: 'Thêm món vào thực đơn hoặc thêm nguyên liệu từ Tủ đồ.',
        ),
      );
    }
    final done = state.doneIds;
    final viewModel = ref.read(shoppingViewModelProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      children: [
        for (final group in state.groups) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s1, top: AppSpacing.s2),
            child: Text(
              group.label,
              style: AppTextStyles.label.copyWith(color: context.colors.inkMuted),
            ),
          ),
          Material(
            color: context.colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: context.colors.line),
              borderRadius: AppRadius.mdAll,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final item in group.items)
                  _ShoppingRow(
                    item: item,
                    checked: done.contains(item.id),
                    onChanged: (_) => viewModel.toggle(item.id),
                    isLast: item == group.items.last,
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
    required this.item,
    required this.checked,
    required this.onChanged,
    required this.isLast,
  });

  final ShoppingEntry item;
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
          item.name,
          style: AppTextStyles.body.copyWith(
            color: checked ? colors.inkMuted : colors.ink,
            decoration: checked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          item.subtitle,
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
    return Material(
      color: colors.surfaceRaised,
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
                'Thứ đã tick sẽ được cất vào Tủ đồ.',
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s2),
              AppButton(
                label: 'Xong, cất vào tủ',
                block: true,
                onPressed: state.doneCount == 0
                    ? null
                    : () async {
                        await ref.read(shoppingViewModelProvider.notifier).complete();
                        if (context.mounted) {
                          AppSnackbar.show(context, 'Đã cất đồ vào Tủ đồ');
                          context.pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: EmptyState(
      icon: AppIcons.alert,
      title: 'Không đọc được danh sách đi chợ',
      message: 'Thử mở lại màn này.',
    ),
  );
}
