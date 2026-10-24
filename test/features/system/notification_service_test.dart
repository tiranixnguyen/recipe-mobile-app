import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  test('stub gọi được, không ném', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(notificationServiceProvider);

    await expectLater(service.timerDone(recipeTitle: 'Trứng rán'), completes);
    await expectLater(
      service.mealReminder(
        meal: Meal.dinner,
        at: DateTime(2026, 10, 24, 18),
        recipeTitle: 'Canh rau',
      ),
      completes,
    );
  });
}
