import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/pantry/domain/pantry_list.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Tủ đồ (prototype `Pantry`): đánh dấu đồ đang có, kéo đồ cần mua vào nút Đi chợ.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  PantryViewModel get _viewModel => ref.read(pantryViewModelProvider.notifier);

  Future<void> _addToShopping(Ingredient ingredient) async {
    _report(await _viewModel.addToShopping(ingredient));
  }

  Future<void> _addQuery() async {
    if (await _viewModel.addQueryToShopping() case final outcome?) _report(outcome);
  }

  void _report(PantryShopOutcome outcome) {
    if (!mounted) return;
    final viewModel = _viewModel;
    final (:result, :name, :item) = outcome;
    switch (result) {
      case PantryShopResult.added:
        AppSnackbar.show(
          context,
          PantryStrings.added(name),
          action: SnackAction(PantryStrings.undo, () => viewModel.undoAdd(item)),
          besideFab: true,
        );
      case PantryShopResult.alreadyThere:
        AppSnackbar.show(
          context,
          PantryStrings.alreadyInShopping(name),
          kind: SnackKind.info,
          action: SnackAction(PantryStrings.see, () => context.push(shoppingLocation)),
          besideFab: true,
        );
      case PantryShopResult.inPantry:
        AppSnackbar.show(
          context,
          PantryStrings.inPantry(name),
          kind: SnackKind.info,
          besideFab: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(pantryViewModelProvider);
    // Từ khoá bị ViewModel xoá (sau khi thêm vào đi chợ) thì ô tìm cũng xoá theo.
    ref.listen(pantryViewModelProvider.select((s) => s.value?.query), (_, query) {
      if (query != null && query != _query.text) _query.text = query;
    });
    final value = state.value;

    return Scaffold(
      floatingActionButton: value == null
          ? null
          : ShoppingFab<Ingredient>(
              count: value.shoppingCount,
              onPressed: () => context.push(shoppingLocation),
              onAccept: _addToShopping,
            ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(state: value, query: _query),
                Expanded(
                  child: switch (state) {
                    AsyncData(:final value) => _Groups(
                      state: value,
                      onAddToShopping: _addToShopping,
                      onAddQuery: _addQuery,
                    ),
                    AsyncError() => Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: Text(
                        PantryStrings.loadError,
                        style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                      ),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
            if (value != null) ...[
              // Cạnh nút Đi chợ (FAB 56 cách lề 16), mũi tên trỏ sang nút.
              Positioned(
                left: AppSpacing.s4,
                right: 88,
                bottom: 20,
                child: ValueListenableBuilder<Object?>(
                  valueListenable: AppDrag.active,
                  builder: (context, dragging, child) =>
                      dragging == null ? child! : const SizedBox.shrink(),
                  child: const TipBubble(
                    id: pantryDragTip,
                    text: PantryStrings.dragTip,
                    anchor: TipAnchor.right,
                  ),
                ),
              ),
              const Positioned(right: 12, bottom: 84, child: _DropHint()),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state, required this.query});

  final PantryState? state;
  final TextEditingController query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = this.state;
    final viewModel = ref.read(pantryViewModelProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  PantryStrings.title,
                  style: AppTextStyles.title.copyWith(color: colors.ink),
                ),
              ),
              if (state != null)
                Text(
                  PantryStrings.summary(state.summary.have, state.summary.needed),
                  style: AppTextStyles.meta.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.inkMuted,
                  ),
                ),
            ],
          ),
          if (state != null) ...[
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: query,
                    placeholder: PantryStrings.searchPlaceholder,
                    label: PantryStrings.searchLabel,
                    onChanged: viewModel.setQuery,
                  ),
                ),
                if (state.query.isNotEmpty)
                  IconButton(
                    tooltip: PantryStrings.clearQuery,
                    onPressed: () {
                      query.clear();
                      viewModel.clearQuery();
                    },
                    icon: Icon(AppIcons.close, color: colors.inkMuted),
                  ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.s2,
                children: [
                  for (final (filter, label) in [
                    (PantryFilter.all, PantryStrings.filterAll),
                    (PantryFilter.have, PantryStrings.filterHave(state.counts.have)),
                    (PantryFilter.needed, PantryStrings.filterNeeded(state.counts.needed)),
                  ])
                    AppChip(
                      label: label,
                      selected: state.filter == filter,
                      onTap: () => viewModel.setFilter(filter),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Groups extends ConsumerWidget {
  const _Groups({required this.state, required this.onAddToShopping, required this.onAddQuery});

  final PantryState state;
  final ValueChanged<Ingredient> onAddToShopping;
  final VoidCallback onAddQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(pantryViewModelProvider.notifier);
    final query = state.query.trim();
    return ListView(
      // Chừa chỗ dưới cho nút Đi chợ và mẹo.
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, 96),
      children: [
        for (final (i, group) in state.groups.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s5),
          _GroupHeader(
            group: group,
            collapsed: state.isCollapsed(group.key),
            onToggle: state.searching ? null : () => viewModel.toggleGroup(group.key),
          ),
          if (!state.isCollapsed(group.key)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final ingredient in group.items)
                  _PantryChip(
                    ingredient: ingredient,
                    status: state.statusOf(ingredient.id),
                    onTap: () => viewModel.tap(ingredient.id),
                    onAddToShopping: () => onAddToShopping(ingredient),
                  ),
              ],
            ),
          ],
        ],
        if (state.noResult)
          if (query.isEmpty)
            Text(
              PantryStrings.emptyFilter,
              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(
                      PantryStrings.noMatch(query),
                      style: AppTextStyles.body.copyWith(color: colors.ink),
                    ),
                    AppButton.secondary(
                      label: PantryStrings.addQuery(query),
                      onPressed: onAddQuery,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// Tên nhóm bên trái, "đang có x, cần mua y" bên phải; bấm để mở/đóng (khi không tìm).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.collapsed, required this.onToggle});

  final PantryGroupView group;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onToggle = this.onToggle;
    return Semantics(
      header: true,
      button: onToggle != null,
      expanded: onToggle == null ? null : !collapsed,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            spacing: AppSpacing.s1,
            children: [
              Expanded(
                child: Text(
                  group.key.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              Text(
                PantryStrings.groupCount(group.haveCount, group.neededCount),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.inkMuted,
                ),
              ),
              if (onToggle != null)
                ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: collapsed ? 0 : .25,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(AppIcons.chevron, size: 20, color: colors.inkMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip nguyên liệu 3 trạng thái theo prototype: chưa có (viền `outline`), đang có (nền `chiliSoft`,
/// dấu tích), đang cần mua (viền đứt `chili`, icon giỏ). Nhấn giữ để kéo vào nút Đi chợ.
class _PantryChip extends StatelessWidget {
  const _PantryChip({
    required this.ingredient,
    required this.status,
    required this.onTap,
    required this.onAddToShopping,
  });

  final Ingredient ingredient;
  final ChipStatus status;
  final VoidCallback onTap;
  final VoidCallback onAddToShopping;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = ingredient.name;
    final (
      Color background,
      Color foreground,
      BorderSide side,
      IconData? icon,
      Color? iconColor,
    ) = switch (status) {
      ChipStatus.have => (
        colors.chiliSoft,
        colors.chiliDeep,
        BorderSide(color: colors.chiliSoft),
        AppIcons.check,
        colors.chiliDeep,
      ),
      // Viền đứt vẽ riêng bằng _DashedStadiumPainter.
      ChipStatus.needed => (
        colors.surfaceRaised,
        colors.ink,
        BorderSide.none,
        AppIcons.basket,
        colors.chili,
      ),
      ChipStatus.none => (
        Colors.transparent,
        colors.ink,
        BorderSide(color: colors.outline),
        null,
        null,
      ),
    };

    Widget chip = Material(
      color: background,
      shape: StadiumBorder(side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s1,
              children: [
                if (icon != null) Icon(icon, size: 16, color: iconColor),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (status == ChipStatus.needed) {
      chip = CustomPaint(foregroundPainter: _DashedStadiumPainter(colors.chili), child: chip);
    }

    return MergeSemantics(
      child: HoldDraggable<Ingredient>(
        data: ingredient,
        semanticsActionLabel: PantryStrings.addToShoppingAction,
        onSemanticsAction: onAddToShopping,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, shift: true): onAddToShopping,
          },
          child: Semantics(
            button: true,
            label: switch (status) {
              ChipStatus.have => PantryStrings.chipHave(name),
              ChipStatus.needed => PantryStrings.chipNeeded(name),
              ChipStatus.none => PantryStrings.chipNone(name),
            },
            onTap: onTap,
            excludeSemantics: true,
            child: chip,
          ),
        ),
      ),
    );
  }
}

/// Viền đứt 1.5px quanh chip đang cần mua (`border: 1.5px dashed var(--chili)`).
class _DashedStadiumPainter extends CustomPainter {
  const _DashedStadiumPainter(this.color);

  final Color color;

  static const _width = 1.5;
  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    final radius = Radius.circular(math.min(rect.width, rect.height) / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, math.min(d + _dash, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter oldDelegate) => color != oldDelegate.color;
}

/// Nhãn "Thả vào đây…" trên nút Đi chợ khi đang kéo một nguyên liệu.
class _DropHint extends StatelessWidget {
  const _DropHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: ValueListenableBuilder<Object?>(
        valueListenable: AppDrag.active,
        builder: (context, dragging, _) => dragging is! Ingredient
            ? const SizedBox.shrink()
            : DecoratedBox(
                decoration: BoxDecoration(color: colors.ink, borderRadius: AppRadius.smAll),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    PantryStrings.dropHint,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.surface,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
