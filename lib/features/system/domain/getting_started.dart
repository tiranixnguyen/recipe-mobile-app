/// Bốn bước làm quen với vòng dùng chính của app, theo thứ tự gợi ý (không khoá).
enum StartStep { pantry, shopping, plan, cook }

/// Vị trí đặt gợi ý tại chỗ.
enum StartHintSpot { pantryAdd, pantryShop, planAdd, planCook, rate }

/// Các bước đã đạt theo dữ liệu hiện có. Bước cook chỉ xong khi có món được chấm: nấu xong mà
/// chưa chấm thì chưa tính.
Set<StartStep> reachedSteps({
  required int pantryCount,
  required int shoppingCount,
  required int plannedCount,
  required bool hasRatedCook,
}) => {
  if (pantryCount > 0) StartStep.pantry,
  if (shoppingCount > 0) StartStep.shopping,
  if (plannedCount > 0) StartStep.plan,
  if (hasRatedCook) StartStep.cook,
};

/// Bước làm nổi: bước đầu tiên chưa xong; null khi xong cả bốn.
StartStep? nextStep(Set<StartStep> done) {
  for (final step in StartStep.values) {
    if (!done.contains(step)) return step;
  }
  return null;
}

/// Gợi ý ở [spot] có hiện không, khi checklist còn mở.
bool showsHint(StartHintSpot spot, Set<StartStep> done) => switch (spot) {
  StartHintSpot.pantryAdd => !done.contains(StartStep.pantry),
  StartHintSpot.pantryShop => done.contains(StartStep.pantry) && !done.contains(StartStep.shopping),
  StartHintSpot.planAdd => !done.contains(StartStep.plan),
  StartHintSpot.planCook => done.contains(StartStep.plan) && !done.contains(StartStep.cook),
  StartHintSpot.rate => !done.contains(StartStep.cook),
};
