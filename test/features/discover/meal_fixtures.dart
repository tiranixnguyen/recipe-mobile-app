import 'package:recipe_mobile_app/core/models/models.dart';

const mealIngredientsFixture = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
  Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
];

Recipe mealRecipe(
  String id,
  String name, {
  DishRole role = DishRole.main,
  int minutes = 15,
  List<Tool> tools = const [Tool.stove],
  List<RecipeIngredient> ingredients = const [],
}) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: 1,
  tools: tools,
  diets: const [],
  meals: const [],
  ingredients: ingredients,
  steps: const [],
  role: role,
);

final mealEgg = mealRecipe(
  'trung',
  'Trứng chiên hành',
  ingredients: const [
    RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
    RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
  ],
);
final mealSoup = mealRecipe(
  'canh',
  'Canh cà chua',
  role: DishRole.soup,
  minutes: 20,
  tools: const [Tool.rice],
  ingredients: const [
    RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
  ],
);
final mealTofu = mealRecipe(
  'dau',
  'Đậu phụ sốt cà chua',
  minutes: 25,
  ingredients: const [
    RecipeIngredient(id: 'tofu', amount: 2, unit: 'bìa'),
    RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả'),
  ],
);
final mealGreens = mealRecipe(
  'rau',
  'Rau muống xào tỏi',
  role: DishRole.side,
  minutes: 10,
);

final mealRecipes = [mealEgg, mealSoup, mealTofu, mealGreens];
