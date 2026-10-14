# Demo flow làm việc — "Trà sữa Hoà Lạc"

Nhánh `demo` là một app thu nhỏ, làm **đúng theo cách cả nhóm sẽ làm trong 4 tuần**: mỗi feature một
chủ, gọi nhau qua public API, mỗi việc đi từ issue → branch → agent → PR → review → merge.
Nhánh này **không bao giờ merge vào `main`**.

```bash
git fetch && git switch demo
fvm flutter pub get && fvm flutter run   # chạy trên emulator/máy Android
```

## App demo ↔ app thật

| Demo | App thật | Thấy được gì |
|---|---|---|
| `features/menu` — danh sách món | F1 Trang chủ | Dùng `DrinkCard` của `core/`, đặt `FavoriteButton` của feature khác vào card |
| `features/detail` — size, topping, thành tiền | F2 Chi tiết | Route của feature tự khai báo, logic giá là hàm thuần trong `domain/` có unit test |
| `features/favorites` — tim + tab Yêu thích | F5 Của tôi | Công bố **stub** trước, bản thật sau; lưu trên máy qua `LocalStore` |
| `app/`, `core/` | Phần của Lead | Router chỉ gộp routes; model, repository, LocalStore, widget dùng chung |

## Lịch sử PR trên nhánh `demo`

Xem tab **Pull requests** (filter `label:demo is:closed`) hoặc
[Project Demo flow](https://github.com/users/tiranixnguyen/projects/1).

| Issue | PR | Việc | Chủ (giả lập) | Điểm cần để ý |
|---|---|---|---|---|
| #1 | #7 | Skeleton, `AGENTS.md`, templates, CI | Lead | Mỗi feature đã có sẵn thư mục, `<f>.dart`, `routes.dart` → không ai phải sửa file chung |
| #2 | #8 | Stub `FavoriteButton` | Chủ Yêu thích | 20 dòng, merge trong ngày → Menu và Chi tiết dùng được ngay |
| #3 | #9 | Màn Menu | Chủ Menu | Mở **cùng lúc** với #10, merge **không conflict** |
| #4 | #10 | Màn Chi tiết | Chủ Chi tiết | `priceFor()` trong `domain/` + unit test |
| #5 | #11 | Yêu thích bản thật | Chủ Yêu thích | Diff chỉ nằm trong `features/favorites` — Menu/Chi tiết không sửa dòng nào |
| #6 | #12 | Tài liệu này | Lead | |

Có một chi tiết thật xảy ra khi làm demo: test của shell (Lead viết) tìm tab bằng icon ♡, nhưng Menu cũng
có icon ♡ nên test hỏng. Cách xử lý đúng: **chủ Menu không tự sửa test của Lead** mà báo Lead; Lead sửa
test để tìm tab theo nhãn trong `NavigationBar`. Đây chính là quy tắc "cần sửa `core/`/`app/` → báo Lead".

## Một vòng làm việc của thành viên

1. **Nhận việc.** Mở Project → cột Todo → chọn issue có label `feature:<của mình>` → assign mình →
   kéo sang In progress. `#dev` sẽ hiện thông báo.
2. **Tạo branch** từ nhánh mới nhất:
   ```bash
   git switch main && git pull          # demo: thay main bằng demo
   git switch -c feat/<số issue>-<mô-tả-ngắn>
   ```
3. **Giao cho agent.**
   - **Antigravity:** chạy workflow `/implement-issue` (file `.agent/workflows/implement-issue.md`),
     hoặc nhắn: *"Làm issue #N. Đọc AGENTS.md trước, chỉ sửa trong lib/features/&lt;f&gt;/. Lập plan rồi chờ
     mình duyệt."*
   - **Zed + Claude / Claude Code:** *"Đọc `gh issue view N` và làm theo AGENTS.md. Plan trước, chờ duyệt."*
   - **Đọc plan kỹ trước khi duyệt**: plan đụng tới `core/`, `app/`, `pubspec.yaml` hay thư mục feature
     khác → từ chối, hỏi Lead.
4. **Tự kiểm tra** trước khi đẩy:
   ```bash
   fvm dart format lib test && fvm flutter analyze && fvm flutter test
   fvm flutter run    # tự bấm thử trên Android, quay màn hình cho PR
   ```
5. **Mở PR** (template tự điền): `Closes #N`, ảnh/quay màn hình, tick checklist.
   ```bash
   git push -u origin HEAD
   gh pr create --fill --base main   # demo: --base demo
   ```
6. **CI** chạy format/analyze/test → kết quả hiện ở PR và `#ci`. Đỏ thì sửa, đẩy lại.
7. **Review.** CODEOWNERS tự yêu cầu đúng người. Reviewer có thể Approve/Comment ngay trong Slack.
8. **Merge** → issue tự đóng (nhờ `Closes #N`) → Project tự chuyển Done → Slack báo.
   Riêng nhánh `demo`: GitHub chỉ tự đóng issue khi PR merge vào nhánh mặc định (`main`), nên issue demo
   được đóng bằng tay kèm link PR. App thật merge vào `main` nên không gặp chuyện này.
9. **Standup** sáng hôm sau trong `#standup`: hôm qua / hôm nay / vướng gì + link issue.

## Bài tập khởi động (mỗi người 1 việc, trên nhánh `demo`)

Làm trọn một vòng ở trên với một issue nhỏ, base là `demo`:

| Bài | Feature | Việc |
|---|---|---|
| A | menu | Sắp xếp menu theo giá tăng dần |
| B | detail | Chọn mức đá (100% / 50% / không đá) |
| C | detail | Chọn mức đường, hiển thị dưới thành tiền |
| D | favorites | Nút "Xoá hết" trên màn Yêu thích (có hỏi xác nhận) |
| E | menu | Ô tìm món theo tên trên Menu |

Bài B và C cùng sửa màn Chi tiết: hai người làm thì sẽ gặp conflict — chủ đích để tập xử lý
(`git pull --rebase`, sửa, chạy lại test) và để thấy vì sao app thật chia mỗi feature một chủ.

## Sau buổi demo

Giữ nhánh `demo` làm tài liệu tham khảo. `AGENTS.md`, `.github/` và `.agent/` sẽ được Lead đưa sang
`main` (đã chỉnh cho app thật) trong issue SET-05/SET-06.
