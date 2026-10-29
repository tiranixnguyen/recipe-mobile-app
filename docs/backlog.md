# Backlog MVP — Bếp Hoà Lạc

Timebox: **4 tuần, 19/10 → 15/11/2026**. Phạm vi và giao diện bám theo `docs/design/` (PR #18): 4 tab,
23 màn prototype, design system *Bếp Hoà Lạc*. Chi tiết từng issue nằm trong `scripts/backlog.sh` — script
là nguồn gốc, file này là bản tổng quan.

## Luật sản phẩm

- **Không hiển thị giá tiền ở bất kỳ đâu.** Không thu thập giá, không có trường giá trong dữ liệu. App
  gợi ý theo *đồ có sẵn*, *dụng cụ trong phòng* và *thời gian*, không theo ngân sách.
- **Chỉ Android.** Không task, CI hay QA cho iOS.
- **Không tài khoản.** Mọi dữ liệu cá nhân (tủ đồ, thực đơn, món đã lưu, lịch sử nấu và đánh giá, dụng
  cụ, chế độ ăn, giao diện) chỉ lưu trên máy qua `LocalStore`. Chỉ nội dung góp ý người dùng tự gửi mới
  rời khỏi máy.
- **Công thức đóng gói sẵn trong app** (`assets/data/`), chạy offline hoàn toàn. Firebase chỉ dùng cho
  Crashlytics/Analytics và nhận góp ý.
- Giọng văn, màu, chữ, component: theo `docs/design/design-system/README.md` và `tokens.json`; hai theme
  sáng/tối, mặc định theo hệ thống.

## v2 — thiết kế mới (từ 29/10)

Thiết kế đổi nhiều sau vòng v1, nên phần còn lại của MVP làm theo **v2**: issue gắn label `v2`, milestone W3/W4 giữ
nguyên hạn 15/11. Màn v1 đã làm mà thiết kế đổi thì **dựng lại theo prototype v2**, không sửa dần bản cũ; việc v1
còn sót gộp vào issue v2. Prototype: `docs/design/prototype/` (sync 29/10, 29 màn).

| Issue | Việc | Chủ | Ưu tiên |
|---|---|---|---|
| #112 UI-01 | Thông báo dùng chung: `AppSnackbar`, `TipBubble`, `InlineBanner`, `ConfirmDialog` (board `Toasts`) | Lead | P0, làm trước |
| #113 CORE-01 | `MealMosaic`, `ShoppingFab` (nút Đi chợ tròn có badge), quy ước kéo thả nhấn giữ | Lead | P0 |
| #114 CORE-02 | Tag công thức (`role`, `feel`, `tags`), `suggestMeal()` gợi ý cả bữa | Lead | P0 |
| #115 CORE-03 | Gợi ý theo thời tiết, tuỳ chọn, mặc định tắt | Lead | P1 |
| #116 DSC-11 | Khám phá v2: banner, "Sắp tới bữa … rồi", Nấu được ngay, Thiếu 1–2 thứ, Đi chợ | Lead + Claude | P0 |
| #117 DSC-12 | Gợi ý cho mình (`TodayPrefs`) + Hôm nay ăn gì theo bữa, Lưu lại / Thêm vào thực đơn | Lead + Claude | P0 |
| #118 DSC-13 | Đã lưu: tab Món ăn / Bữa ăn, kéo vào thùng rác, `savedMealsProvider` | Lead + Claude | P0 |
| #119 PAN-11 | Tủ đồ v2: nhóm, tìm, chip 3 trạng thái, kéo vào Đi chợ | Lead + Claude | P0 |
| #120 PLAN-11 | Thực đơn v2 chế độ Ngày: bữa tâm điểm, lịch tháng, thêm cả bữa | Lead + Claude | P0 |
| #48 PLAN-02 | Thực đơn v2 chế độ Tuần: lưới tuần, Gợi ý cả tuần | Lead + Claude | P0 |
| #49 SHP-01 | Danh sách đi chợ, nhận đồ từ Tủ đồ / Khám phá / Chuẩn bị nấu | Lead + Claude | P0 |
| #35, #45, #50 | Polish & test theo màn v2 | Cline | P1 |

Thứ tự: #112, #113, #114 (Lead) → #120, #119, #118 → #116, #117, #48, #49 → polish. Màn Nấu (F2) và Hệ thống
(F5) không đổi thiết kế ở v2, chỉ chuyển snackbar sang widget chung (#112).

Từ 30/10 Lead nhận lại toàn bộ issue đang mở (các thành viên bận). Mọi issue assign cho Lead, label cho biết
ai làm: `agent:claude` (Lead + Claude Code: việc sâu, chặn issue khác), `agent:cline` (Cline chạy model free:
#24, #27, #35, #45, #50, #59, spec rõ, phạm vi nhỏ, PR để Lead review). #60, #61, #83 Lead tự làm.

Luật mới ở v2: thời tiết là ngoại lệ duy nhất của luật offline, chỉ chạy khi người dùng bật (#115); vẫn không có
giá tiền ("Tiết kiệm" là tag món, không phải ngân sách).

## 5 feature — mỗi người một feature

| Feature | Chủ | Thư mục | Màn (prototype) | Khối lượng |
|---|---|---|---|---|
| F1 · Khám phá | TV1 | `features/discover` | Main, Search, Today, Saved | ~8 ngày |
| F2 · Nấu | TV2 | `features/cook` | Detail, CookPrep, CookStep, CookDone, RateApp | ~8 ngày |
| F3 · Tủ đồ & gợi ý | **Lead** | `features/pantry` | Pantry + bộ gợi ý dùng chung | ~5,5 ngày + setup |
| F4 · Thực đơn & đi chợ | TV3 | `features/plan` | MealPlan (ngày/tuần), Shopping | ~8 ngày |
| F5 · Hệ thống | TV4 | `features/system` | Onboarding, Settings, NotifPermission, Feedback, About, Policy, ClearData | ~8 ngày |

Lead còn làm `app/` + `core/` (Splash, Error, theme, dữ liệu) và toàn bộ setup. Ai cũng góp phần như nhau
vào việc chung: 8 công thức/người, mời 2 người test, bug bash.

### Điểm nối giữa các feature (public API `lib/features/<f>/<f>.dart`)

| Cung cấp | API | Dùng bởi |
|---|---|---|
| F3 Tủ đồ & gợi ý | `availabilityFor(recipe)`, `suggest(meal, count)`, `suggestMeal(prefs)`/`mealSuggesterProvider`, `dislike()`, `pantryItemsProvider`, `addToPantry`, `removeFromPantry` | F1, F2, F4 |
| F1 Khám phá | `SaveButton`, `savedIdsProvider`, route `/search?…` | F2, F3 |
| F2 Nấu | route `/recipe/:id`, `ResumeCookingBanner`, `cookHistoryProvider` | tất cả, F1, F3 |
| F4 Thực đơn | `addToPlan`, `addToShopping`, `plannedMealsProvider`, route `/shopping` | F2, F5 |
| F5 Hệ thống | `kitchenProfileProvider`, `themeModeProvider`, `NotificationService` | F3, app, F2, F4 |

Mỗi người công bố **stub chạy được trước 24/10** để người khác gọi ngay, rồi làm bản thật sau (như nhánh
`demo`). Component của design system được chia theo người cần đầu tiên, đặt trong `lib/core/widgets/`, Lead
review:

| Người | Component |
|---|---|
| TV1 | RecipeCard, Chip, SearchField, EmptyState |
| TV2 | Button, ServingStepper, StepTimer |
| TV3 | MealSlot, DayStrip (design system chưa có — tự đề xuất theo token, Lead duyệt) |
| TV4 | Icon (Material Symbols Rounded), hàng cài đặt |
| Lead | Theme từ tokens, BottomNav, AvailabilityBadge |

## Kế hoạch theo tuần

| | W1 (19–25/10) | W2 (26/10–1/11) | W3 (2–8/11) | W4 (9–15/11) |
|---|---|---|---|---|
| **TV1** Khám phá | DSC-00 component + API | DSC-01 Khám phá, DSC-02 Tìm kiếm | DSC-03 Hôm nay ăn gì, DSC-04 Đã lưu | DSC-09 |
| **TV2** Nấu | COOK-00 component + API | COOK-01 Chi tiết, COOK-02 Chuẩn bị | COOK-03 Từng bước, COOK-04 Hoàn thành | COOK-09 |
| **TV3** Thực đơn | PLAN-00 component + API | PLAN-01 Ngày, PLAN-02 Tuần + gợi ý | SHP-01 Đi chợ | PLAN-09 |
| **TV4** Hệ thống | SYS-00 icon + API | SYS-01 Onboarding, SYS-02 Cài đặt | SYS-03 Thông báo, SYS-05 Góp ý | SYS-04 Giới thiệu/Chính sách/Xoá, SYS-09 |
| **Lead** Tủ đồ | PAN-00 API + badge | PAN-01 Tủ đồ | PAN-02 Bộ gợi ý | PAN-09 |
| **Lead** Setup | SET-05, 06, 01, 15, 08 | SET-09, 16, 17 | SET-18, SET-13 (v0.1.0) | REL-03 |
| **Cả nhóm** | CNT-01 (3 món/người) | CNT-02 (5 món/người) | — | REL-06, REL-07 |

**Sau MVP (`stretch`, P2):** STR-01 Người dùng đăng công thức, STR-02 Gợi ý thực đơn tuần bằng AI, STR-03
Cập nhật công thức không cần ra bản app mới, STR-04 Setup animation cho app, bắt đầu với câu chúc ở trang
Lưu ý (#107).

**Đường găng:** PR #18 merge → SET-01 (22/10) → SET-15 theme + SET-08 dữ liệu (23/10) → component + stub
của mọi feature (24/10) → luồng chính W2.

**Rủi ro lớn nhất: W1 của Lead** (~6 ngày việc trong 3,5 ngày còn lại). Phần lớn SET-01/05/06 là port từ
nhánh `demo` nên nhanh; nếu vẫn trễ, đẩy PAN-00 sang đầu W2 và để thành viên code với stub tạm.
W4 cố ý nhẹ để làm buffer. Nếu trễ, cắt P1 trước (polish, Crashlytics, màn lỗi), không lấn sang tuần 5.

## Quy ước label

| Loại | Giá trị |
|---|---|
| Milestone | `W1 · Nền tảng & component` (25/10), `W2 · Luồng chính` (1/11), `W3 · Hoàn thiện tính năng` (8/11), `W4 · Kiểm thử & phát hành` (15/11) |
| Feature | `feature:discover` `feature:cook` `feature:pantry` `feature:plan` `feature:system` — bug cũng gắn để về đúng chủ |
| Agent | `agent:claude` Lead + Claude Code · `agent:cline` Cline (model free), Lead review |
| Khác | `track:lead` setup · `shared` việc chung · `release` · `stretch` · `ai-workflow` |
| Priority | `P0` bắt buộc · `P1` nên có · `P2` stretch |
| Size | `size:S` ≤ ½ ngày · `size:M` 1–2 ngày · `size:L` ~3 ngày |

## AI workflow: GitHub ↔ Slack ↔ IDE

Đã chạy thử trọn vòng trên nhánh `demo` — xem `docs/demo-flow.md` ở nhánh đó.

```
Issue (spec cho agent, label feature:<f> → đúng chủ)
  → Project: Todo ─▶ In progress
  → Antigravity / Claude đọc AGENTS.md + docs/design + issue → plan → code trong features/<f>/ → analyze/test
  → PR "Closes #N" → CI + Claude review + Lead approve
  → merge → issue đóng → Project: Done
Slack: #dev (issue, PR, review), #ci (workflow), #standup (/remind 9h).
```

- Issue UI luôn ghi tên file prototype (`docs/design/prototype/<Màn>.dc.html`); PR đính ảnh so với prototype.
- Claude review mỗi PR một lần khi mở; gọi lại bằng `@claude` trong comment.

## Đưa backlog lên GitHub

```bash
DRY_RUN=1 scripts/backlog.sh        # xem trước
ASSIGNEE_DISCOVER=<gh-user> ASSIGNEE_COOK=<gh-user> ASSIGNEE_PLAN=<gh-user> \
  ASSIGNEE_SYSTEM=<gh-user> scripts/backlog.sh
```

Setup và Tủ đồ tự assign cho Lead; thiếu biến `ASSIGNEE_*` thì để trống. Chạy lại không tạo trùng.
