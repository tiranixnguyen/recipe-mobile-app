import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/getting_started.dart';
import 'package:recipe_mobile_app/features/system/data/preferences.dart';
import 'package:recipe_mobile_app/features/system/domain/getting_started.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Nơi một dòng dẫn tới. [tab] là tab của thanh dưới (đi bằng `go`), không thì `push`.
@immutable
class StartTarget {
  const StartTarget(this.location, {this.tab = false});

  final String location;
  final bool tab;

  @override
  bool operator ==(Object other) =>
      other is StartTarget && other.location == location && other.tab == tab;

  @override
  int get hashCode => Object.hash(location, tab);
}

/// Một dòng của thẻ. [target] và [action] null khi dòng đã xong.
@immutable
class StartRow {
  const StartRow({
    required this.step,
    required this.title,
    required this.done,
    required this.next,
    this.action,
    this.target,
  });

  final StartStep step;
  final String title;
  final bool done;

  /// Bước kế tiếp: được làm nổi và có nút.
  final bool next;
  final String? action;
  final StartTarget? target;
}

@immutable
class GettingStartedCardState {
  const GettingStartedCardState({required this.visible, required this.rows});

  /// Đã qua Onboarding và chưa ẩn.
  final bool visible;
  final List<StartRow> rows;

  int get doneCount => rows.where((r) => r.done).length;
  int get total => rows.length;
  bool get allDone => rows.isNotEmpty && doneCount == total;
}

class GettingStartedViewModel extends Notifier<GettingStartedCardState> {
  @override
  GettingStartedCardState build() {
    final started = ref.watch(gettingStartedProvider);
    final visible = ref.watch(onboardingDoneProvider) && !started.hidden;
    if (!visible) return const GettingStartedCardState(visible: false, rows: []);

    final next = nextStep(started.done);
    final unrated = ref.watch(latestUnratedCookProvider);
    final today = dateOnly(ref.watch(startClockProvider)());
    final pending =
        ref
            .watch(plannedMealsProvider)
            .where((p) => p.day == today && !p.cooked)
            .map((p) => p.meal)
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));

    StartRow row(StartStep step, String title, String action, StartTarget target) {
      final done = started.done.contains(step);
      return StartRow(
        step: step,
        title: title,
        done: done,
        next: step == next,
        action: done ? null : action,
        target: done ? null : target,
      );
    }

    return GettingStartedCardState(
      visible: true,
      rows: [
        row(
          StartStep.pantry,
          SystemStrings.startPantry,
          SystemStrings.startPantryAction,
          const StartTarget(pantryLocation, tab: true),
        ),
        row(
          StartStep.shopping,
          SystemStrings.startShopping,
          SystemStrings.startShoppingAction,
          const StartTarget(pantryLocation, tab: true),
        ),
        row(
          StartStep.plan,
          SystemStrings.startPlan,
          SystemStrings.startPlanAction,
          StartTarget(planLocation(date: today), tab: true),
        ),
        if (unrated != null)
          row(
            StartStep.cook,
            SystemStrings.startCookUnrated,
            SystemStrings.startCookUnratedAction,
            StartTarget(historyEntryLocation(unrated)),
          )
        else
          row(
            StartStep.cook,
            SystemStrings.startCook,
            SystemStrings.startCookAction,
            pending.isEmpty
                ? const StartTarget(todayLocation)
                : StartTarget(planLocation(date: today, meal: pending.first), tab: true),
          ),
      ],
    );
  }

  void open(StartStep step) =>
      ref.read(analyticsProvider).track('start_step_open', {'step': step.name});

  /// Nút "Ẩn" và "Đóng" (khi xong cả bốn bước): ẩn vĩnh viễn.
  Future<void> hide() async {
    final done = ref.read(gettingStartedProvider).done.length;
    ref.read(analyticsProvider).track('start_hide', {'done': done});
    await ref.read(gettingStartedProvider.notifier).hide();
  }
}

final gettingStartedViewModelProvider =
    NotifierProvider.autoDispose<GettingStartedViewModel, GettingStartedCardState>(
      GettingStartedViewModel.new,
    );
