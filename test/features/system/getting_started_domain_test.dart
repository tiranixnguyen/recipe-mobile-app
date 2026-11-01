import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/system/domain/getting_started.dart';

void main() {
  Set<StartStep> reached({
    int pantry = 0,
    int shopping = 0,
    int planned = 0,
    bool rated = false,
  }) => reachedSteps(
    pantryCount: pantry,
    shoppingCount: shopping,
    plannedCount: planned,
    hasRatedCook: rated,
  );

  group('reachedSteps', () {
    test('chưa có gì thì chưa bước nào', () => expect(reached(), isEmpty));

    test('mỗi dữ liệu tick đúng bước của nó', () {
      expect(reached(pantry: 2), {StartStep.pantry});
      expect(reached(shopping: 1), {StartStep.shopping});
      expect(reached(planned: 3), {StartStep.plan});
      expect(reached(rated: true), {StartStep.cook});
    });

    test('nấu xong mà chưa chấm món thì bước cook chưa xong', () {
      expect(reached(pantry: 1, shopping: 1, planned: 1), isNot(contains(StartStep.cook)));
    });
  });

  group('nextStep', () {
    test('bước đầu tiên chưa xong, không phụ thuộc thứ tự đã làm', () {
      expect(nextStep({}), StartStep.pantry);
      expect(nextStep({StartStep.pantry}), StartStep.shopping);
      expect(nextStep({StartStep.pantry, StartStep.plan}), StartStep.shopping);
      expect(nextStep({StartStep.shopping}), StartStep.pantry);
    });

    test('xong cả bốn thì null', () => expect(nextStep(StartStep.values.toSet()), isNull));
  });

  group('showsHint', () {
    const none = <StartStep>{};

    test('pantryAdd chỉ khi chưa có đồ trong tủ', () {
      expect(showsHint(StartHintSpot.pantryAdd, none), isTrue);
      expect(showsHint(StartHintSpot.pantryAdd, {StartStep.pantry}), isFalse);
    });

    test('pantryShop khi tủ có đồ mà đi chợ chưa xong', () {
      expect(showsHint(StartHintSpot.pantryShop, none), isFalse);
      expect(showsHint(StartHintSpot.pantryShop, {StartStep.pantry}), isTrue);
      expect(showsHint(StartHintSpot.pantryShop, {StartStep.pantry, StartStep.shopping}), isFalse);
    });

    test('planAdd chỉ khi chưa lên thực đơn', () {
      expect(showsHint(StartHintSpot.planAdd, none), isTrue);
      expect(showsHint(StartHintSpot.planAdd, {StartStep.plan}), isFalse);
    });

    test('planCook khi đã lên thực đơn mà chưa nấu xong', () {
      expect(showsHint(StartHintSpot.planCook, none), isFalse);
      expect(showsHint(StartHintSpot.planCook, {StartStep.plan}), isTrue);
      expect(showsHint(StartHintSpot.planCook, {StartStep.plan, StartStep.cook}), isFalse);
    });

    test('rate chỉ khi chưa chấm món nào', () {
      expect(showsHint(StartHintSpot.rate, none), isTrue);
      expect(showsHint(StartHintSpot.rate, {StartStep.cook}), isFalse);
    });
  });
}
