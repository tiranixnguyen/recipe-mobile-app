import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/preferences.dart';
import 'package:recipe_mobile_app/features/system/domain/getting_started.dart';

const _doneKey = 'system.startDone';
const _hiddenKey = 'system.startHidden';

/// Checklist "Bắt đầu": các bước đã xong và đã ẩn hay chưa.
@immutable
class GettingStarted {
  const GettingStarted({required this.done, required this.hidden});

  final Set<StartStep> done;
  final bool hidden;

  bool get allDone => done.length == StartStep.values.length;

  @override
  bool operator ==(Object other) =>
      other is GettingStarted && other.hidden == hidden && setEquals(other.done, done);

  @override
  int get hashCode => Object.hash(hidden, Object.hashAllUnordered(done));
}

/// Bước nào đã xong tự tính từ dữ liệu thật và lưu lại (`system.startDone`): đã tick thì không bỏ
/// tick, kể cả khi người dùng xoá hết đồ trong tủ. Ẩn thẻ lưu ở `system.startHidden`.
///
/// Lần đầu chạy (chưa có `system.startHidden`) mà đủ bốn bước thì coi là người dùng cũ và ẩn luôn.
class GettingStartedController extends Notifier<GettingStarted> {
  @override
  GettingStarted build() {
    final store = ref.watch(localStoreProvider);
    final saved = {
      for (final name in store.readList(_doneKey)) ?StartStep.values.asNameMap()[name],
    };
    final reached = reachedSteps(
      pantryCount: ref.watch(pantryItemsProvider).length,
      shoppingCount: ref.watch(shoppingItemsProvider).length + ref.watch(shoppingProvider).length,
      plannedCount: ref.watch(plannedMealsProvider).length,
      hasRatedCook: ref
          .watch(cookHistoryProvider)
          .any((entry) => entry.dishes.any((dish) => dish.rating != null)),
    );
    final done = {...saved, ...reached};

    final firstRun = store.readString(_hiddenKey) == null;
    final hidden = store.readString(_hiddenKey) == 'true' || (firstRun && done.length == 4);

    final fresh = done.difference(saved);
    if (fresh.isNotEmpty || firstRun) {
      store.writeList(_doneKey, [
        for (final step in StartStep.values)
          if (done.contains(step)) step.name,
      ]);
      if (firstRun) store.writeString(_hiddenKey, hidden.toString());
      // Người dùng cũ tự ẩn thì không có "bước vừa xong" nào để ghi.
      if (!hidden) {
        final analytics = ref.read(analyticsProvider);
        for (final step in fresh) {
          analytics.track('start_step_done', {'step': step.name});
        }
      }
    }
    return GettingStarted(done: Set.unmodifiable(done), hidden: hidden);
  }

  /// Ẩn thẻ và mọi gợi ý, vĩnh viễn.
  Future<void> hide() async {
    if (state.hidden) return;
    state = GettingStarted(done: state.done, hidden: true);
    await ref.read(localStoreProvider).writeString(_hiddenKey, 'true');
  }
}

final gettingStartedProvider = NotifierProvider<GettingStartedController, GettingStarted>(
  GettingStartedController.new,
);

/// Gợi ý tại chỗ ở [StartHintSpot] có hiện không: đã qua Onboarding, checklist còn mở và bước liên
/// quan chưa xong.
final startHintProvider = Provider.family<bool, StartHintSpot>((ref, spot) {
  if (!ref.watch(onboardingDoneProvider)) return false;
  final state = ref.watch(gettingStartedProvider);
  return !state.hidden && showsHint(spot, state.done);
});

/// Id lần nấu gần nhất khi đã nấu mà chưa chấm món nào; null khi bước cook xong hoặc chưa nấu.
final latestUnratedCookProvider = Provider<String?>((ref) {
  if (ref.watch(gettingStartedProvider).done.contains(StartStep.cook)) return null;
  return ref.watch(cookHistoryProvider).lastOrNull?.id;
});

/// "Hôm nay" cho thẻ Bắt đầu; test override để cố định.
final startClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
