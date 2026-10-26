import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/presentation/step/step_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fakes.dart';
import 'fixtures.dart';

final _now = DateTime(2026, 10, 26, 18);

class _Env {
  _Env() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
        ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
        cookClockProvider.overrideWithValue(() => _now),
        wakelockProvider.overrideWithValue(wakelock),
        notificationServiceProvider.overrideWithValue(notifications),
        appInForegroundProvider.overrideWithValue(() => foreground),
      ],
    );
    addTearDown(container.dispose);
  }

  late final ProviderContainer container;
  final wakelock = FakeWakelock();
  final notifications = FakeNotificationService();
  bool foreground = true;

  final provider = stepViewModelProvider('trung');
  StepViewModel get viewModel => container.read(provider.notifier);
  CookStepState get state => container.read(provider).requireValue;

  Future<ProviderSubscription<Object?>> open() async {
    final sub = container.listen(provider, (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return sub;
  }
}

void main() {
  test('mở ở bước đang dở của phiên, khẩu phần theo phiên', () async {
    final env = _Env();
    final sessions = env.container.read(cookSessionProvider.notifier);
    await sessions.startRecipe('trung', 2);
    await sessions.goTo(0, 2);
    await env.open();

    expect((env.state.index, env.state.servings), (2, 2));
    expect(env.state.step.text, 'Chiên mặt dưới');
    expect(env.state.ingredients.first, (name: 'Trứng gà', amountText: '4 quả'));
    expect(env.state.basicSpices, ['Dầu ăn', 'tiêu']);
    expect(env.state.timedSteps, [1, 2]);
  });

  test('Bước tiếp / Bước trước lưu vào phiên, không ra ngoài khoảng', () async {
    final env = _Env();
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
    await env.open();

    await env.viewModel.previous();
    expect(env.state.isFirst, isTrue);
    for (var i = 0; i < 5; i++) {
      await env.viewModel.next();
    }
    expect((env.state.index, env.state.isLast), (3, true));
    expect(env.container.read(cookSessionProvider)!.positions, [3]);
    await env.viewModel.previous();
    expect(env.container.read(cookSessionProvider)!.positions, [2]);
  });

  test('mở thẳng không có phiên: bước đầu, qua bước thì mở phiên', () async {
    final env = _Env();
    await env.open();
    expect((env.state.index, env.state.servings), (0, 1));

    await env.viewModel.next();
    final session = env.container.read(cookSessionProvider)!;
    expect(session.currentDish, (recipeId: 'trung', servings: 1));
    expect(session.positions, [1]);
  });

  test('màn hình luôn sáng khi đang mở, rời màn thì tắt', () async {
    final env = _Env();
    final sub = await env.open();
    expect(env.wakelock.enabled, isTrue);
    await env.viewModel.next();
    expect(env.wakelock.enabled, isTrue);

    sub.close();
    await env.container.pump();
    expect(env.wakelock.enabled, isFalse);
  });

  test('hẹn giờ chạy thì hẹn báo; dừng thì huỷ; đồng hồ hiện ở mọi bước khi đang chạy', () async {
    final env = _Env();
    await env.open();
    final key = cookTimerKey(0, 1);

    expect((env.state.showsTimer(1), env.state.showsTimer(2)), (false, false));
    await env.viewModel.timerChanged(1, StepTimerStatus.running);
    expect(env.notifications.timers[key], (
      recipeTitle: 'Trứng chiên hành',
      at: _now.add(const Duration(seconds: 60)),
    ));
    expect(env.state.showsTimer(1), isTrue);
    await env.viewModel.next();
    await env.viewModel.next();
    expect((env.state.index, env.state.showsTimer(1)), (2, true));

    await env.viewModel.timerChanged(1, StepTimerStatus.idle);
    expect(env.notifications.timers, isEmpty);
    expect(env.state.showsTimer(1), isFalse);
  });

  test('hết giờ: đang mở app thì huỷ lịch, ở app khác thì để thông báo hiện', () async {
    final env = _Env();
    await env.open();
    await env.viewModel.timerChanged(1, StepTimerStatus.running);
    await env.viewModel.timerChanged(2, StepTimerStatus.running);

    env.foreground = false;
    await env.viewModel.timerChanged(1, StepTimerStatus.done);
    expect(env.notifications.timers.keys, [cookTimerKey(0, 1), cookTimerKey(0, 2)]);

    env.foreground = true;
    await env.viewModel.timerChanged(2, StepTimerStatus.done);
    expect(env.notifications.timers.keys, [cookTimerKey(0, 1)]);
  });

  test('Xong: món xong trong phiên, huỷ mọi lịch báo của món', () async {
    final env = _Env();
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
    await env.open();
    await env.viewModel.timerChanged(2, StepTimerStatus.running);

    await env.viewModel.finish();
    expect(env.container.read(cookSessionProvider)!.isDone, isTrue);
    expect(env.notifications.timers, isEmpty);
  });
}
