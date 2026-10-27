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
  "prepMinutes": 5,
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
    { "text": "Rửa sạch hành lá, thái nhỏ.", "prep": [{ "id": "scallion", "action": "Rửa sạch, thái nhỏ" }] },
    { "text": "Đập trứng vào bát, thêm hành lá và nước mắm. Đánh tan.", "prep": [{ "id": "egg", "action": "Đập ra bát, thêm hành lá, nước mắm rồi đánh tan" }] },
    { "text": "Chiên trên chảo nóng đến khi vàng.", "timerSeconds": 180 }
  ],
  "notes": ["Ăn nóng với cơm hoặc kẹp bánh mì."]
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
- `steps[].prep`: việc sơ chế trong bước, tuỳ chọn, mặc định rỗng (chỉ ghi khi có việc). Bước có `prep`
  là bước sơ chế. Nấu cả bữa gom việc sơ chế của mọi món theo nguyên liệu thành chặng "Sơ chế cả bữa" làm
  trước, rồi mới tới bước đứng bếp; `text` của bước vẫn dùng khi nấu một món. Bước là bước sơ chế khi:
  - làm trước được: rửa, thái, gọt, ngâm, ướp, đánh trứng, vo gạo, trộn nước chấm;
  - không cần bếp, nước sôi, lò vi sóng hay hẹn giờ (bước sơ chế không có `timerSeconds`);
  - không phụ thuộc bước nấu trước nó.

  Mỗi việc là một nguyên liệu:
  - `id`: nguyên liệu được sơ chế, phải có trong `ingredients` của món.
  - `action`: cách làm, ngắn, viết hoa chữ đầu, không dấu chấm cuối ("Thái nhỏ", "Bổ múi cau", "Đập ra
    bát rồi đánh tan"). Hai món cùng cách làm thì viết y hệt để app gộp thành một việc.
  - `amount`: tuỳ chọn, lượng làm theo cách này, cùng đơn vị với nguyên liệu; bỏ trống = cả lượng của
    món. Dùng khi một nguyên liệu chia hai cách (1 nhánh hành cắt khúc, 1 nhánh thái nhỏ); tổng không
    vượt lượng nguyên liệu.

  Bước nhắc nhiều nguyên liệu ("Cà chua bổ múi cau. Hành lá thái nhỏ.") thì mỗi nguyên liệu một việc.
  Một bước vừa sơ chế vừa nấu ("Vo gạo, cho vào nồi…") thì tách làm hai: "Vo gạo." (có `prep`) và "Cho
  gạo vào nồi…". Việc chỉ là đặt đồ vào dụng cụ ngay trước khi nấu ("Đổ vào bát chịu nhiệt", "Bọc khoai
  bằng giấy ăn ẩm") để ở bước nấu. Bước sơ chế đứng trước mọi bước nấu của món, và món phải còn ít nhất
  một bước nấu. Món không có gì để sơ chế (bánh mì ốp trứng) thì không có `prep`.
- `prepMinutes`: phút sơ chế, đã tính trong `minutes`. Bắt buộc khi món có bước sơ chế,
  `0 < prepMinutes < minutes`; không có bước sơ chế thì bỏ trống. Nấu cả bữa cộng lại thành "sơ chế ~8
  phút, nấu ~27 phút".
- `notes`: lưu ý cách dùng (ăn nóng, ăn kèm gì, để được bao lâu), tuỳ chọn, mặc định rỗng. Mỗi mục một
  câu ngắn, viết hoa chữ đầu, có dấu chấm cuối, không ghi giá. Màn Nấu hiện ở trang "Lưu ý cách dùng" sau
  bước cuối (nấu cả bữa: chặng Lưu ý gom mọi món); bỏ trống thì hiện "Món ăn không có lưu ý nào."
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
- Bước sơ chế ghi `prep` và `prepMinutes` theo luật ở trên; viết sơ chế thành bước riêng ở đầu món
  (rửa, thái, đánh trứng…), không trộn vào bước nấu. Nguyên liệu nào cần thái/rửa thì ghi rõ ở bước đó.
  Test chặn: `prep[].id` không có trong `ingredients`, `action` rỗng, `amount` ≤ 0, tổng `amount` theo
  nguyên liệu vượt lượng của món, `prepMinutes` thiếu hoặc ngoài khoảng.
- `test/core/data/bundled_data_test.dart` chạy trên `assets/data/` thật và kiểm hết các quy tắc trên
  (kể cả không có key `price`/`gia`). CI đỏ thì sửa dữ liệu, không sửa test.
