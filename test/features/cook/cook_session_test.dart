import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';

void main() {
  late ProviderContainer container;
  var now = DateTime(2026, 10, 26, 18);

  setUp(() {
    now = DateTime(2026, 10, 26, 18);
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        cookClockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() => container.dispose());

  CookSessionController controller() => container.read(cookSessionProvider.notifier);
  LocalStore store() => container.read(localStoreProvider);

  test('mặc định không có phiên', () {
    expect(container.read(cookSessionProvider), isNull);
  });

  test('nấu một món: bắt đầu ở bước đầu, qua bước, xong; dựng lại vẫn còn', () async {
    await controller().startRecipe('trung', 2);
    var session = container.read(cookSessionProvider)!;
    expect(session.dishes, [(recipeId: 'trung', servings: 2)]);
    expect(session.positions, [0]);
    expect((session.isMeal, session.isDone, session.startedAt), (false, false, now));

    await controller().goTo(0, 2);
    await controller().finishDish(0);
    session = container.read(cookSessionProvider)!;
    expect(session.positions, [2]);
    expect(session.isDone, isTrue);

    container.invalidate(cookSessionProvider);
    expect(container.read(cookSessionProvider), session);
  });

  test('nấu cả bữa: lưu bữa, bước từng món, món đang nấu', () async {
    await controller().startMeal(
      [(recipeId: 'dau', servings: 2), (recipeId: 'canh', servings: 2)],
      (day: DateTime(2026, 10, 27, 9), meal: Meal.dinner),
    );
    await controller().goTo(0, 1);
    await controller().goTo(1, 3);
    await controller().finishDish(0);
    final end = DateTime(2026, 10, 26, 18, 3);
    await controller().setTimerEnd(51, end);
    await controller().setTimerEnd(2, end);
    await controller().setTimerEnd(2, null);

    container.invalidate(cookSessionProvider);
    final session = container.read(cookSessionProvider)!;
    expect(session.isMeal, isTrue);
    expect(session.planned, (day: DateTime(2026, 10, 27), meal: Meal.dinner));
    expect(session.current, 1);
    expect(session.positions, [1, 3]);
    expect(session.finished, {0});
    expect(session.timerEnds, {51: end});
    expect(session.isDone, isFalse);
  });

  test('chặng Sơ chế: bắt đầu ở Sơ chế, tick lưu lại, sang bước thì rời Sơ chế', () async {
    await controller().startMeal(
      [(recipeId: 'dau', servings: 2), (recipeId: 'canh', servings: 2)],
      (day: DateTime(2026, 10, 27), meal: Meal.dinner),
      prep: true,
    );
    expect(container.read(cookSessionProvider)!.inPrep, isTrue);
    await controller().setPrepDone(['garlic', 'scallion/Thái nhỏ'], done: true);
    await controller().setPrepDone(['garlic'], done: false);

    container.invalidate(cookSessionProvider);
    var session = container.read(cookSessionProvider)!;
    expect(session.inPrep, isTrue);
    expect(session.prepDone, {'scallion/Thái nhỏ'});

    await controller().goTo(0, 0);
    expect(container.read(cookSessionProvider)!.inPrep, isFalse);
    await controller().showPrep();
    container.invalidate(cookSessionProvider);
    session = container.read(cookSessionProvider)!;
    expect(session.inPrep, isTrue);
    expect(session.prepDone, {'scallion/Thái nhỏ'});
  });

  test('trang Lưu ý: lưu qua JSON; sang bước hoặc về Sơ chế thì rời Lưu ý', () async {
    await controller().startMeal(
      [(recipeId: 'dau', servings: 2), (recipeId: 'canh', servings: 2)],
      (day: DateTime(2026, 10, 27), meal: Meal.dinner),
      prep: true,
    );
    await controller().showNotes();
    container.invalidate(cookSessionProvider);
    var session = container.read(cookSessionProvider)!;
    expect((session.inNotes, session.inPrep), (true, false));
    expect(session.toJson()['inNotes'], isTrue);
    expect(session.toString(), contains('inNotes'));

    await controller().goTo(1, 0);
    session = container.read(cookSessionProvider)!;
    expect((session.inNotes, session.current), (false, 1));
    expect(session.toJson().containsKey('inNotes'), isFalse);

    await controller().showNotes();
    await controller().showPrep();
    session = container.read(cookSessionProvider)!;
    expect((session.inNotes, session.inPrep), (false, true));
    expect(session, isNot(session.copyWith(inNotes: true)));

    // Xong hết món mà còn ở Lưu ý thì chưa xong phiên; Xong cả bữa rời Lưu ý.
    await controller().finishDish(0);
    await controller().finishDish(1);
    await controller().showNotes();
    session = container.read(cookSessionProvider)!;
    expect((session.inNotes, session.isDone), (true, false));
    await controller().finishDish(1);
    session = container.read(cookSessionProvider)!;
    expect((session.inNotes, session.isDone), (false, true));
  });

  test('phiên không có inPrep, prepDone, inNotes (lưu trước COOK-06) vẫn đọc được', () async {
    await store().writeString(
      'cook.session',
      jsonEncode({
        'dishes': [
          {'recipeId': 'trung', 'servings': 1},
        ],
        'current': 0,
        'positions': [1],
        'finished': <int>[],
        'startedAt': now.toIso8601String(),
      }),
    );
    container.invalidate(cookSessionProvider);
    final session = container.read(cookSessionProvider)!;
    expect((session.inPrep, session.prepDone.isEmpty, session.inNotes), (false, true, false));
    expect(session.positions, [1]);
    expect(session.toJson().containsKey('inPrep'), isFalse);
  });

  test('bắt đầu phiên mới thì thay phiên cũ; clear thì xoá', () async {
    await controller().startRecipe('trung', 1);
    await controller().startRecipe('mi', 3);
    expect(container.read(cookSessionProvider)!.currentDish, (recipeId: 'mi', servings: 3));

    await controller().clear();
    expect(container.read(cookSessionProvider), isNull);
    expect(store().readString('cook.session'), isNull);
  });

  test('chỉ số ngoài khoảng thì bỏ qua', () async {
    await controller().startRecipe('trung', 1);
    await controller().goTo(3, 1);
    await controller().goTo(0, -1);
    await controller().finishDish(5);
    final session = container.read(cookSessionProvider)!;
    expect(session.positions, [0]);
    expect(session.finished, isEmpty);
  });

  test('phiên bắt đầu quá 12 tiếng thì coi như bỏ', () async {
    await controller().startRecipe('trung', 1);
    now = now.add(const Duration(hours: 13));
    container.invalidate(cookSessionProvider);
    expect(container.read(cookSessionProvider), isNull);
  });

  test('dữ liệu hỏng thì bỏ, không lỗi', () async {
    for (final raw in [
      'không phải json',
      '[]',
      jsonEncode({'dishes': [], 'current': 0, 'positions': [], 'finished': [], 'startedAt': ''}),
      jsonEncode({
        'dishes': [
          {'recipeId': 'trung', 'servings': 1},
        ],
        'current': 2,
        'positions': [0],
        'finished': [],
        'startedAt': now.toIso8601String(),
      }),
    ]) {
      await store().writeString('cook.session', raw);
      container.invalidate(cookSessionProvider);
      expect(container.read(cookSessionProvider), isNull, reason: raw);
    }
  });
}
