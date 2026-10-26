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

/// Như [detailIngredientsFixture], thêm ớt (món tuỳ chọn của [cookRecipeFixture]).
const cookIngredientsFixture = [
  ...detailIngredientsFixture,
  Ingredient(id: 'chili', name: 'Ớt', group: IngredientGroup.vegetable),
  Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
];

/// Món để test chế độ nấu: có nguyên liệu tuỳ chọn kèm ghi chú thay thế, bước có hẹn giờ.
const cookRecipeFixture = Recipe(
  id: 'trung',
  name: 'Trứng chiên hành',
  description: '',
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
    RecipeIngredient(
      id: 'chili',
      amount: 0.5,
      unit: 'quả',
      optional: true,
      substituteNote: 'Không có cũng được, hoặc thay bằng chút ớt bột.',
    ),
  ],
  steps: [
    RecipeStep(
      text: 'Đánh trứng với hành',
      prep: [
        PrepTask(id: 'scallion', action: 'Thái nhỏ'),
        PrepTask(id: 'egg', action: 'Đập ra bát rồi đánh tan'),
      ],
    ),
    RecipeStep(text: 'Làm nóng dầu', timerSeconds: 60),
    RecipeStep(text: 'Chiên mặt dưới', timerSeconds: 180),
    RecipeStep(text: 'Lật trứng, xúc ra đĩa'),
  ],
  prepMinutes: 3,
);

/// Món thứ hai cho Nấu cả bữa: lâu hơn [cookRecipeFixture] nên được gợi ý nấu trước. Sơ chế chung
/// với món trứng: trứng cùng cách làm (một việc), hành lá khác cách (việc cha, hai việc con).
const soupRecipeFixture = Recipe(
  id: 'canh',
  name: 'Canh cà chua trứng',
  description: '',
  imageAsset: '',
  minutes: 20,
  servings: 2,
  tools: [Tool.stove],
  diets: [],
  meals: [],
  ingredients: [
    RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
    RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng cà phê'),
  ],
  prepMinutes: 5,
  steps: [
    RecipeStep(
      text: 'Cà chua bổ múi cau, hành cắt khúc, đánh trứng',
      prep: [
        PrepTask(id: 'tomato', action: 'Bổ múi cau'),
        PrepTask(id: 'scallion', action: 'Cắt khúc'),
        PrepTask(id: 'egg', action: 'Đập ra bát rồi đánh tan'),
      ],
    ),
    RecipeStep(text: 'Xào cà chua'),
    RecipeStep(text: 'Đổ nước, đun sôi', timerSeconds: 300),
    RecipeStep(text: 'Đổ trứng, tắt bếp'),
  ],
);
