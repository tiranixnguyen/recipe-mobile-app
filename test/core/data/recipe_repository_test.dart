import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(files[key] ?? (throw StateError('Không có $key'))));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recipesProvider và ingredientsProvider đọc được dữ liệu đóng gói', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ingredients = await container.read(ingredientsProvider.future);
    expect(ingredients.map((e) => e.id), contains('egg'));

    final recipes = await container.read(recipesProvider.future);
    expect(recipes, isNotEmpty);
    expect(recipes.first.ingredients, isNotEmpty);
  });

  test('override recipeRepositoryProvider bằng bundle giả', () async {
    final bundle = _FakeBundle({
      'assets/data/recipes.json': jsonEncode([
        {
          'id': 'r1',
          'name': 'Món test',
          'imageAsset': 'assets/images/recipes/r1.jpg',
          'minutes': 5,
          'servings': 1,
          'tools': ['kettle'],
          'ingredients': [
            {'id': 'noodle', 'amount': 1, 'unit': 'gói'},
          ],
          'steps': [
            {'text': 'Đổ nước sôi.'},
          ],
        },
      ]),
    });
    final container = ProviderContainer(
      overrides: [recipeRepositoryProvider.overrideWith((ref) => RecipeRepository(bundle: bundle))],
    );
    addTearDown(container.dispose);

    final recipes = await container.read(recipesProvider.future);
    expect(recipes.single.id, 'r1');
    expect(recipes.single.tools, [Tool.kettle]);
  });

  test('id lạ làm provider lỗi, thông báo chỉ đúng món', () async {
    final bundle = _FakeBundle({
      'assets/data/recipes.json': jsonEncode([
        {
          'id': 'r1',
          'name': 'Món test',
          'imageAsset': 'assets/images/recipes/r1.jpg',
          'minutes': 5,
          'servings': 1,
          'tools': ['stoev'],
          'ingredients': <Object>[],
          'steps': <Object>[],
        },
      ]),
    });
    final container = ProviderContainer(
      overrides: [recipeRepositoryProvider.overrideWith((ref) => RecipeRepository(bundle: bundle))],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(recipesProvider.future),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Món "r1": dụng cụ "stoev" không có',
        ),
      ),
    );
  });
}
