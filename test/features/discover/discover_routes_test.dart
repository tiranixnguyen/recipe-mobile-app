import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';

void main() {
  test('searchLocation kèm từ khoá và bộ lọc', () {
    expect(searchLocation(), '/search');
    expect(searchLocation(query: 'trứng'), '/search?q=tr%E1%BB%A9ng');
    expect(searchLocation(maxMinutes: 15), '/search?maxMinutes=15');
    expect(searchLocation(tool: Tool.rice, diet: Diet.veg), '/search?tool=rice&diet=veg');
    expect(searchLocation(meal: Meal.dinner), '/search?meal=dinner');
  });
}
