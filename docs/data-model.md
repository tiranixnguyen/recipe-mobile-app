# Data model — Bếp Hoà Lạc

Công thức và nguyên liệu đóng gói sẵn trong `assets/data/`. App chạy offline. **Không có trường giá tiền ở bất kỳ đâu.**

## File

- `assets/data/ingredients.json` — mảng `Ingredient`.
- `assets/data/recipes.json` — mảng `Recipe`.
- Ảnh món đặt trong `assets/images/recipes/` (≤ 200KB, có thumbnail cho card).

## Kiểu dùng chung (`lib/core/models/`)

### `Tool` (dụng cụ)

| id | label |
|---|---|
| `rice` | Nồi cơm điện |
| `stove` | Bếp từ / bếp ga |
| `micro` | Lò vi sóng |
| `kettle` | Ấm siêu tốc |

### `Diet` (chế độ ăn)

| id | label |
|---|---|
| `veg` | Ăn chay |
| `nospicy` | Không ăn cay |
| `noseafood` | Dị ứng hải sản |
| `nopork` | Không ăn thịt lợn |
| `light` | Ăn nhẹ buổi tối |

### `Meal` (bữa)

| id | label |
|---|---|
| `breakfast` | Sáng |
| `lunch` | Trưa |
| `dinner` | Tối |

### `IngredientGroup` (nhóm nguyên liệu)

| id | label |
|---|---|
| `protein` | Đạm |
| `vegetable` | Rau củ |
| `starch` | Tinh bột |
| `spice` | Gia vị |
| `other` | Khác |

### `Ingredient`

```json
{ "id": "egg", "name": "Trứng", "group": "protein", "isBasicSpice": false }
```

- `id`: khóa duy nhất.
- `name`: tên hiển thị tiếng Việt.
- `group`: một trong `IngredientGroup.id`.
- `isBasicSpice`: gia vị cơ bản — app coi như luôn có sẵn trong bếp.

**Quy ước gia vị:** mọi nguyên liệu nhóm `spice` (muối, nước mắm, dầu ăn, tiêu, tỏi…) đều phải
`isBasicSpice: true`, tức luôn có sẵn. Tủ đồ không có chip gia vị nên người dùng không đánh dấu được;
test chặn nếu nhập sai.

### `Recipe`

```json
{
  "id": "trung-chien-hanh",
  "name": "Trứng chiên hành",
  "description": "Món nhanh cho bữa sáng hoặc bữa trưa.",
  "imageAsset": "assets/images/recipes/trung-chien-hanh.jpg",
  "minutes": 15,
  "servings": 2,
  "tools": ["stove"],
  "diets": ["nospicy", "nopork"],
  "meals": ["breakfast", "lunch"],
  "ingredients": [
    { "id": "egg", "amount": 3, "unit": "quả" },
    { "id": "scallion", "amount": 2, "unit": "nhánh" },
    { "id": "fishsauce", "amount": 1, "unit": "muỗng canh", "optional": true, "substituteNote": "Có thể dùng muối" },
    { "id": "oil", "amount": 1, "unit": "muỗng canh" }
  ],
  "steps": [
    { "text": "Đánh trứng với hành lá và nước mắm." },
    { "text": "Chiên trên chảo nóng đến khi vàng.", "timerSeconds": 180 }
  ]
}
```

- `imageAsset`: ảnh món. Chưa có ảnh thì vẫn ghi đường dẫn dự kiến; `RecipeCard` dùng ảnh thay thế
  (component `Cover`) khi file không tồn tại.
- `tools`: danh sách `Tool.id` cần có để nấu. Không rỗng.
- `diets`: các chế độ ăn món **thoả mãn**; rỗng = không hợp chế độ nào. Người chọn chế độ X chỉ được gợi
  ý món có X. Nhập thiếu tag thì món chỉ bị ẩn bớt, không bị gợi ý nhầm. Nghi ngờ thì không gắn:
  - `veg`: không gắn cho món có trứng, mì gói, nước mắm.
  - `noseafood`: không gắn cho món có nước mắm (kể cả tuỳ chọn), gói gia vị mì (thường có tôm).
  - `nopork`: không gắn cho món có gói gia vị mì (có thể có mỡ lợn).
- `meals`: bữa phù hợp; rỗng = mọi bữa.
- `ingredients[].id`: tham chiếu `Ingredient.id` (phải tồn tại).
- `ingredients[].amount`: lượng cho `servings` khẩu phần chuẩn.
- `ingredients[].optional`: nguyên liệu tuỳ chọn.
- `ingredients[].substituteNote`: cách thay thế khi thiếu.
- `steps[].timerSeconds`: thời gian hẹn giờ (giây) cho bước, tuỳ chọn; nếu có thì > 0.
- `steps[].prep`: bước sơ chế, tuỳ chọn, mặc định `false` (chỉ ghi khi `true`). Nấu cả bữa gom mọi bước
  `prep` của các món thành một bước "Sơ chế cả bữa" làm trước, rồi mới tới bước đứng bếp. Gắn khi bước:
  - làm trước được: rửa, thái, gọt, ngâm, ướp, đánh trứng, vo gạo, trộn nước chấm, bày ra bát/đĩa;
  - không cần bếp, nước sôi, lò vi sóng hay hẹn giờ (bước `prep` không có `timerSeconds`);
  - không phụ thuộc bước nấu trước nó.

  Một bước vừa sơ chế vừa nấu ("Vo gạo, cho vào nồi…") thì tách làm hai: "Vo gạo." (`prep`) và "Cho gạo
  vào nồi…". Bước `prep` đứng trước mọi bước nấu của món, và món phải còn ít nhất một bước không phải
  `prep` (test `bundled_data_test.dart` chặn). Món không có gì để sơ chế (bánh mì ốp trứng) thì không gắn.
- `servings`, `minutes`, `ingredients[].amount` > 0; `ingredients`, `steps` không rỗng.

Mọi id (`tools`, `diets`, `meals`, `group`) phải đúng danh sách trên. Id lạ không bị bỏ qua:
`fromJson` ném `FormatException` chỉ rõ món, ví dụ `Món "x": dụng cụ "stoev" không có`.
Riêng chỗ đọc `LocalStore` dùng `Tool.tryParse`… để bỏ qua dữ liệu cũ.

## Đọc dữ liệu trong app

Không gọi thẳng `RecipeRepository`. Đọc qua provider trong `lib/core/data/recipe_repository.dart`:

```dart
final recipes = await ref.watch(recipesProvider.future);       // List<Recipe>
final ingredients = await ref.watch(ingredientsProvider.future); // List<Ingredient>
```

Hai provider đọc asset một lần cho cả phiên và không retry khi lỗi. Test override
`recipesProvider`/`ingredientsProvider` bằng dữ liệu giả, hoặc `recipeRepositoryProvider` bằng
`RecipeRepository(bundle: ...)`.

### Hàm nhân lượng

`scaleAmount(amount, baseServings, targetServings)` trả về `amount * targetServings / baseServings`.
`scaleIngredients(recipe, targetServings)` nhân toàn bộ nguyên liệu.
`gatherIngredients(dishes, recipesById)` gom nguyên liệu nhiều món (mỗi món kèm số người): cộng lượng
theo (nguyên liệu, đơn vị), khác đơn vị tách dòng, giữ thứ tự gặp đầu. Danh sách đi chợ và "Lấy đồ ra ·
cả bữa" dùng chung hàm này.

### Hiển thị lượng

`formatAmount(amount)` trong `lib/core/format.dart`: `4` → `4`, `1.5` → `1,5`, `1/3` → `0,33`.
`ServingStepper`, màn Detail, danh sách đi chợ và Nấu cả bữa hiển thị lượng qua hàm này, không tự `toString()`.

## Dữ liệu trên máy (`LocalStore`)

- State đọc từ store phải `ref.watch(localStoreProvider)` trong `build`, không `ref.read`.
- Xoá dữ liệu (SYS-04): `await ref.read(clearLocalDataProvider)();` rồi `context.go` về Splash. Hàm này
  xoá store rồi invalidate `localStoreProvider`, nên mọi state đang watch dựng lại từ store rỗng.
- Override `localStoreProvider` bằng `overrideWith`, không `overrideWithValue` (giá trị cố định thì
  invalidate không báo cho provider phụ thuộc).

## Quy tắc nhập dữ liệu (CNT-01/02)

- Mỗi món phải có người nấu thử hoặc kiểm tra lại.
- Giọng văn: xưng "bạn", câu ngắn, không emoji.
- Không ghi giá tiền.
- Id không trùng; nguyên liệu tham chiếu phải tồn tại; dụng cụ/chế độ ăn/bữa thuộc danh sách cho phép.
- Bước sơ chế gắn `"prep": true` theo luật `steps[].prep` ở trên; viết sơ chế thành bước riêng ở đầu món
  (rửa, thái, đánh trứng…), không trộn vào bước nấu. Nguyên liệu nào cần thái/rửa thì ghi rõ ở bước đó.
- `test/core/data/bundled_data_test.dart` chạy trên `assets/data/` thật và kiểm hết các quy tắc trên
  (kể cả không có key `price`/`gia`). CI đỏ thì sửa dữ liệu, không sửa test.
