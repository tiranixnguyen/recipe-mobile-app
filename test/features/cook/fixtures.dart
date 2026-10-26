import 'package:recipe_mobile_app/core/models/models.dart';

/// Dữ liệu chung cho test Chi tiết món.
const detailIngredientsFixture = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
  Ingredient(id: 'pepper', name: 'Tiêu', group: IngredientGroup.spice, isBasicSpice: true),
];

const detailRecipeFixture = Recipe(
  id: 'trung',
  name: 'Trứng chiên hành',
  description: 'Món cứu đói kinh điển, chỉ cần chảo và một bếp điện từ.',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [
    RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
    RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
    RecipeIngredient(id: 'pepper', amount: 1, unit: 'nhúm'),
  ],
  steps: [
    RecipeStep(text: 'Đánh trứng với hành'),
    RecipeStep(text: 'Làm nóng dầu', timerSeconds: 60),
    RecipeStep(text: 'Chiên mặt dưới', timerSeconds: 180),
  ],
);
