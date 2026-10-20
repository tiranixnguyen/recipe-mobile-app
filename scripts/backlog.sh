#!/usr/bin/env bash
# Tạo labels, milestones, GitHub Project và issues cho MVP "Bếp Hoà Lạc" (xem docs/backlog.md).
# Phạm vi và giao diện bám theo docs/design/ (PR #18). App KHÔNG hiển thị giá tiền ở bất kỳ đâu.
#
# Yêu cầu: gh có scope "project" (gh auth refresh -s project).
# Dùng:    DRY_RUN=1 scripts/backlog.sh   # chỉ in ra, không tạo gì
#          ASSIGNEE_DISCOVER=<gh-user> ASSIGNEE_COOK=<gh-user> ASSIGNEE_PLAN=<gh-user> \
#          ASSIGNEE_SYSTEM=<gh-user> scripts/backlog.sh
# Issue setup (track:lead) và feature Tủ đồ & gợi ý được assign cho người chạy script (Lead).
# Chạy lại sẽ bỏ qua cái đã có (so theo title).
set -euo pipefail

REPO="${REPO:-tiranixnguyen/recipe-mobile-app}"
OWNER="${REPO%%/*}"
PROJECT_TITLE="${PROJECT_TITLE:-Recipe MVP}"
DRY_RUN="${DRY_RUN:-0}"

W1="W1 · Nền tảng & component"
W2="W2 · Luồng chính"
W3="W3 · Hoàn thiện tính năng"
W4="W4 · Kiểm thử & phát hành"

dry() { [[ $DRY_RUN == 1 ]]; }

# ---------------------------------------------------------------- labels

label() { # label <name> <color> <description>
  if dry; then echo "label: $1"; return; fi
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null
}

label P0 b60205 "Bắt buộc cho MVP"
label P1 d93f0b "Nên có — cắt trước nếu trễ"
label P2 fbca04 "Stretch — chỉ làm khi dư thời gian"
label size:S c2e0c6 "≤ nửa ngày"
label size:M 7fd18b "1–2 ngày"
label size:L 2ea44f "~3 ngày — nên tách nhỏ"
label type:feature 1d76db "Màn hình / luồng người dùng thấy"
label type:chore 5319e7 "Hạ tầng, cấu hình, quy trình"
label type:content f9d0c4 "Dữ liệu, nội dung"
label track:lead 000000 "Setup/hạ tầng — Lead phụ trách"
label shared 0e8a16 "Việc chung — cả nhóm cùng làm"
label feature:discover 0052cc "Khám phá: trang chính, tìm kiếm, hôm nay ăn gì, đã lưu"
label feature:cook 006b75 "Nấu: chi tiết món, chuẩn bị, từng bước, hoàn thành"
label feature:pantry b4a7d6 "Tủ đồ & bộ gợi ý món"
label feature:plan 1d76db "Thực đơn ngày/tuần & đi chợ"
label feature:system 5319e7 "Onboarding, cài đặt, thông báo, góp ý, dữ liệu"
label release e99695 "Kiểm thử & phát hành"
label stretch ededed "Ngoài phạm vi MVP"
label ai-workflow bfdadc "Quy trình AI / tooling giữa GitHub, Slack, IDE"

# ------------------------------------------------------------ milestones

EXISTING_MILESTONES=$(gh api "repos/$REPO/milestones?state=all" --paginate --jq '.[].title')

milestone() { # milestone <title> <due YYYY-MM-DD> <description>
  if grep -Fxq -- "$1" <<<"$EXISTING_MILESTONES"; then echo "skip milestone: $1"; return; fi
  if dry; then echo "milestone: $1 (due $2)"; return; fi
  gh api "repos/$REPO/milestones" -f title="$1" -f due_on="$2T23:59:59+07:00" \
    -f description="$3" >/dev/null
}

milestone "$W1" 2026-10-25 "Lead: skeleton, theme từ tokens, data model | Mỗi feature: component + public API stub | Cả nhóm: 15 công thức"
milestone "$W2" 2026-11-01 "Mỗi feature: màn chính chạy được với dữ liệu thật | Cả nhóm: ≥ 40 công thức"
milestone "$W3" 2026-11-08 "Mỗi feature: phần còn lại | Lead: bộ gợi ý, pipeline phát hành, v0.1.0 cho team"
milestone "$W4" 2026-11-15 "Mỗi feature: polish + test | Cả nhóm: test với sinh viên, bug bash"

# --------------------------------------------------------------- project

if dry; then
  PROJECT=DRY
else
  PROJECT=$(gh project list --owner "$OWNER" --format json \
    --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" | head -n1)
  if [[ -z $PROJECT ]]; then
    PROJECT=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json --jq .number)
    gh project link "$PROJECT" --owner "$OWNER" --repo "$REPO" >/dev/null
    echo "created project #$PROJECT"
  fi
fi

# ---------------------------------------------------------------- issues

EXISTING_ISSUES=$(gh issue list --repo "$REPO" --state all --limit 1000 --json title --jq '.[].title')

assignee_for() { # assignee_for <labels> → in ra assignee (rỗng nếu không có)
  case ",$1," in
    *,track:lead,* | *,feature:pantry,*) echo @me ;;
    *,feature:discover,*) echo "${ASSIGNEE_DISCOVER:-}" ;;
    *,feature:cook,*) echo "${ASSIGNEE_COOK:-}" ;;
    *,feature:plan,*) echo "${ASSIGNEE_PLAN:-}" ;;
    *,feature:system,*) echo "${ASSIGNEE_SYSTEM:-}" ;;
  esac
}

issue() { # issue <title> <milestone|-> <labels,...>   (body đọc từ stdin)
  local title=$1 milestone=$2 labels=$3 body url assignee
  body=$(cat)
  assignee=$(assignee_for "$labels")
  if grep -Fxq -- "$title" <<<"$EXISTING_ISSUES"; then echo "skip issue: $title"; return; fi
  if dry; then echo "issue: $title [$milestone] ($labels) → ${assignee:--}"; return; fi
  local args=(--repo "$REPO" --title "$title" --body "$body" --label "$labels")
  [[ $milestone != - ]] && args+=(--milestone "$milestone")
  [[ -n $assignee ]] && args+=(--assignee "$assignee")
  url=$(gh issue create "${args[@]}")
  gh project item-add "$PROJECT" --owner "$OWNER" --url "$url" >/dev/null
  echo "created: $url"
  sleep 1 # tránh secondary rate limit khi tạo hàng loạt
}

# ======================================================================== SETUP (Lead)

issue "SET-05 · AGENTS.md cho app thật" "$W1" "P0,size:S,type:chore,track:lead,ai-workflow" <<'EOF'
**Mục tiêu:** Mọi agent và thành viên đọc cùng một bộ luật cho app thật.

**Acceptance criteria**
- [ ] Gộp `AGENTS.md` của nhánh `demo` (kiến trúc, ranh giới feature, quy trình, Definition of Done) với phần **Thiết kế** của PR #18
- [ ] Ghi rõ luật sản phẩm: Android-only, không tài khoản, dữ liệu chỉ trên máy, **không hiển thị giá tiền ở bất kỳ đâu**, giọng văn theo `docs/design/design-system/README.md`
- [ ] Bảng 5 feature: thư mục, chủ, public API (lấy từ `docs/backlog.md`)
- [ ] `CLAUDE.md` = `@AGENTS.md`; rule + workflow `/implement-issue` trong `.agent/` (copy từ `demo`)

**Phụ thuộc:** PR #18 đã merge
EOF

issue "SET-06 · Templates, CODEOWNERS, branch protection, Project workflows" "$W1" "P0,size:S,type:chore,track:lead,ai-workflow" <<'EOF'
**Acceptance criteria**
- [ ] Copy issue/PR templates từ `demo`; PR template thêm dòng "UI đúng `docs/design/` (ảnh so sánh với prototype)"
- [ ] `CODEOWNERS`: `lib/features/{discover,cook,pantry,plan,system}/` → chủ feature; `lib/app/`, `lib/core/`, `pubspec.yaml`, `assets/`, `.github/` → Lead
- [ ] Bảo vệ `main` giống `demo`: PR + CI xanh + 1 approval (Lead merge PR của mình bằng quyền admin)
- [ ] Project "Recipe MVP": Auto-add, Item closed → Done, PR merged → Done; views Board / theo Milestone / theo label feature / "Việc của tôi"
EOF

issue "SET-01 · Skeleton app theo thiết kế" "$W1" "P0,size:M,type:chore,track:lead" <<'EOF'
**Mục tiêu:** Khung để 5 feature code song song, gần như không conflict. Port từ nhánh `demo`.

**Acceptance criteria**
- [ ] `lib/app/`, `lib/core/`, `lib/features/{discover,cook,pantry,plan,system}/`, mỗi feature có `<f>.dart`, `routes.dart`, `strings.dart`
- [ ] Bottom nav 4 tab theo `BottomNav`: Khám phá · Tủ đồ · Thực đơn · Đã lưu (màn tạm)
- [ ] Luồng khởi động: Splash → (lần đầu) Onboarding → Main
- [ ] Thêm trước package cả nhóm cần: riverpod, go_router, shared_preferences, wakelock_plus, flutter_local_notifications, in_app_review, image_picker, device_info_plus, package_info_plus
- [ ] CI từ `demo` (format · analyze · test)

**Deadline nội bộ:** 22/10.
EOF

issue "SET-15 · Theme sáng/tối từ tokens.json" "$W1" "P0,size:M,type:chore,track:lead" <<'EOF'
**Acceptance criteria**
- [ ] Map `docs/design/design-system/tokens.json` → `ThemeData`/`ColorScheme` + `ThemeExtension` cho token riêng (`chili-soft`, `herb`, `herb-ink`, `line`, `outline`, `danger-ink`…)
- [ ] Font Be Vietnam Pro (bundle trong `assets/fonts/`), text style `meta`, step 24/34
- [ ] Spacing (lưới 4px) và radius thành hằng số trong `core/theme/`
- [ ] `ThemeMode` đọc từ `themeModeProvider` (feature system đặt giá trị), mặc định `system`
- [ ] Trang debug hiển thị toàn bộ màu/chữ ở cả hai theme

**Deadline nội bộ:** 23/10 — component của các feature dựa vào đây.
EOF

issue "SET-08 · Data model, dữ liệu công thức đóng gói, LocalStore" "$W1" "P0,size:M,type:chore,track:lead" <<'EOF'
**Mục tiêu:** Chốt hợp đồng dữ liệu. Công thức đóng gói sẵn trong app (`assets/data/`) — chạy offline hoàn toàn, không cần backend cho dữ liệu món.

**Acceptance criteria**
- [ ] `Ingredient` (id, name, group, isBasicSpice), `Recipe` (id, name, description, imageAsset, minutes, servings, tools[], diets[], meals[], ingredients[] {id, amount, unit, optional, substituteNote}, steps[] {text, timerSeconds?}) — **không có trường giá**
- [ ] Hàm nhân lượng nguyên liệu theo khẩu phần (cho `ServingStepper`) + unit test
- [ ] `RecipeRepository` đọc `assets/data/recipes.json` + `ingredients.json`
- [ ] `LocalStore` (từ `demo`) + `clearAll()` cho màn Xoá dữ liệu
- [ ] `docs/data-model.md` để cả nhóm nhập công thức (CNT-01)

**Deadline nội bộ:** schema 22/10, code 23/10.
EOF

issue "SET-09 · Kiểm tra dữ liệu công thức trong CI" "$W2" "P0,size:S,type:chore,track:lead" <<'EOF'
**Acceptance criteria**
- [ ] Test đọc `assets/data/*.json`: id không trùng, nguyên liệu tham chiếu tồn tại, dụng cụ/chế độ ăn/bữa thuộc danh sách cho phép, ảnh tồn tại, không có trường giá
- [ ] Ảnh món ≤ 200KB, có thumbnail cho card
EOF

issue "SET-16 · Firebase: Crashlytics + Analytics" "$W2" "P1,size:S,type:chore,track:lead" <<'EOF'
**Acceptance criteria**
- [ ] Firebase project, `flutterfire configure` chỉ Android
- [ ] Crashlytics + helper `track(event, params)` trong `core/`; danh sách event ghi vào `AGENTS.md`
- [ ] Nội dung cho màn Chính sách (SYS-04): dữ liệu gửi khi app lỗi và cách tắt
EOF

issue "SET-17 · Kênh nhận góp ý" "$W2" "P0,size:M,type:chore,track:lead" <<'EOF'
**Mục tiêu:** Nơi nhận nội dung từ màn Góp ý & báo lỗi (SYS-05).

**Acceptance criteria**
- [ ] Firestore collection `feedback` chỉ cho tạo (không đọc/sửa từ app), Storage cho ảnh chụp màn hình ≤ 2MB
- [ ] Security rules + test bằng emulator, chạy trong CI
- [ ] `FeedbackRepository.send(kind, text, screenshot?, email?, deviceInfo?)` trong `core/`
- [ ] Lead xem góp ý ở đâu (Firebase console / gửi về Slack `#dev`)
EOF

issue "SET-18 · Màn lỗi & splash cấp app" "$W3" "P1,size:S,type:feature,track:lead" <<'EOF'
**Acceptance criteria**
- [ ] Màn `Error` 3 biến thể theo prototype: `crash`, `notfound`, `storage`, có mã lỗi và nút "Báo lỗi cho nhóm" → Góp ý
- [ ] Bắt lỗi toàn cục (FlutterError, PlatformDispatcher) → màn `crash` + Crashlytics
- [ ] Splash theo prototype `Splash`
EOF

issue "SET-13 · Release signing + Firebase App Distribution" "$W3" "P0,size:M,type:chore,track:lead,release" <<'EOF'
**Acceptance criteria**
- [ ] Release keystore lưu ngoài repo (GitHub Secrets), cấu hình signing
- [ ] Workflow build APK release, đẩy lên App Distribution khi tag `v*`
- [ ] Bản `v0.1.0` cho team trước 8/11
EOF

issue "REL-03 · App icon, splash native, tên app, versioning" "$W4" "P0,size:S,type:chore,track:lead,release" <<'EOF'
**Acceptance criteria**
- [ ] Adaptive icon từ `docs/design/design-system/assets/Logos/` (lớp trước + nền `chili-soft`, lớp monochrome cho themed icon)
- [ ] Tên hiển thị "Bếp Hoà Lạc", version `0.1.0+N`
EOF

# ======================================================================== F1 · Khám phá (discover)

issue "DSC-00 · Component RecipeCard, Chip, SearchField, EmptyState + public API" "$W1" "P0,size:M,type:feature,feature:discover" <<'EOF'
**Acceptance criteria**
- [ ] 4 widget trong `lib/core/widgets/` đúng `docs/design/design-system/components/<Tên>/README.md`, dùng token theme (không mã màu cứng), chạy đúng cả sáng/tối
- [ ] `RecipeCard`: ảnh, tên, meta `15 phút · 1 người · Bếp từ`, slot badge đủ/thiếu đồ, slot nút lưu
- [ ] Public API stub `lib/features/discover/discover.dart`: `SaveButton(recipeId)`, `savedIdsProvider`, route `/search`
- [ ] Widget test mỗi component; Lead review

**Phụ thuộc:** SET-15. **Hạn:** 24/10 (các feature khác dùng card).
EOF

issue "DSC-01 · Màn Khám phá" "$W2" "P0,size:M,type:feature,feature:discover" <<'EOF'
Theo `docs/design/prototype/Main.dc.html`.

**Acceptance criteria**
- [ ] Khối "Hôm nay ăn gì?" → màn Today; ô tìm → Search; chip nhanh (Dưới 15 phút, Nồi cơm điện, Chay, Bữa tối) → Search có sẵn bộ lọc
- [ ] Section "Nấu được với đồ bạn có" (từ `pantry.dart`) + "Nhanh sau giờ học"
- [ ] Đặt `ResumeCookingBanner` (từ `cook.dart`) khi đang nấu dở; icon Cài đặt → route của feature system

**Phụ thuộc:** DSC-00, PAN-00
EOF

issue "DSC-02 · Tìm kiếm món hoặc nguyên liệu" "$W2" "P0,size:M,type:feature,feature:discover" <<'EOF'
Theo `Search.dc.html`.

**Acceptance criteria**
- [ ] Tìm theo tên món và nguyên liệu, không phân biệt dấu ("trung" ra "trứng"), hàm thuần + unit test
- [ ] Chip lọc: thời gian, dụng cụ, bữa, chế độ ăn; dòng tóm tắt "[N] món có trứng, dưới 15 phút"
- [ ] Kết quả có badge Đủ đồ / Thiếu: … (từ `pantry.dart`)
- [ ] Route nhận bộ lọc qua query param (Khám phá dùng)
EOF

issue "DSC-03 · Hôm nay ăn gì?" "$W3" "P0,size:M,type:feature,feature:discover" <<'EOF'
Theo `Today.dc.html`.

**Acceptance criteria**
- [ ] Bữa sắp tới theo giờ (Sáng/Trưa/Tối, đổi được), 1 món chính kèm lý do + 2 món "Hoặc thử" — lấy từ `suggest()` của `pantry.dart`
- [ ] "Đổi món" lấy gợi ý tiếp; "Không thích" → chọn lý do (Vừa ăn rồi / Thiếu đồ / Lâu quá / Không hợp khẩu vị) → `dislike()` để app nhớ
- [ ] "Nấu món này" → Chi tiết

**Phụ thuộc:** PAN-02 (dùng stub trước)
EOF

issue "DSC-04 · Đã lưu: nút lưu + tab Đã lưu" "$W3" "P0,size:M,type:feature,feature:discover" <<'EOF'
Theo `Saved.dc.html`.

**Acceptance criteria**
- [ ] `SaveButton` thật: icon bookmark, tô đặc khi đã lưu, lưu qua `LocalStore`
- [ ] Tab Đã lưu: danh sách `RecipeCard`; trống → `EmptyState` "Tìm món để lưu"
- [ ] `savedIdsProvider` để bộ gợi ý ưu tiên món đã lưu
EOF

issue "DSC-09 · Polish & test Khám phá" "$W4" "P1,size:S,type:feature,feature:discover" <<'EOF'
- [ ] Widget test: Khám phá, tìm kiếm có lọc, Today đổi/không thích, lưu/bỏ lưu
- [ ] Sáng/tối, text scale 1.3, màn 360dp không vỡ; so khớp prototype
- [ ] Analytics: `view_discover`, `search`, `today_suggest`, `today_dislike`, `save_recipe`
EOF

# ======================================================================== F2 · Nấu (cook)

issue "COOK-00 · Component Button, ServingStepper, StepTimer + public API" "$W1" "P0,size:M,type:feature,feature:cook" <<'EOF'
**Acceptance criteria**
- [ ] 3 widget trong `lib/core/widgets/` đúng README component (Button: primary/secondary/ghost/danger, size lg 56px; StepTimer: "Hẹn 3 phút" → thanh đếm ngược `ink` → hết giờ `chili`)
- [ ] Public API stub `lib/features/cook/cook.dart`: route `/recipe/:id`, `ResumeCookingBanner`, `cookHistoryProvider` (món đã nấu + đánh giá)
- [ ] Widget test; Lead review

**Phụ thuộc:** SET-15. **Hạn:** 24/10.
EOF

issue "COOK-01 · Chi tiết món" "$W2" "P0,size:M,type:feature,feature:cook" <<'EOF'
Theo `Detail.dc.html`.

**Acceptance criteria**
- [ ] Ảnh, badge đủ/thiếu đồ, meta, mô tả, nút lưu (`SaveButton`)
- [ ] Nguyên liệu kèm "Có trong tủ" / "Gia vị cơ bản" (từ `pantry.dart`); các bước kèm thời gian
- [ ] "Thêm vào thực đơn" (từ `plan.dart`), "Bắt đầu nấu" → Chuẩn bị; id không tồn tại → màn lỗi `notfound`
EOF

issue "COOK-02 · Chuẩn bị nấu" "$W2" "P0,size:M,type:feature,feature:cook" <<'EOF'
Theo `CookPrep.dc.html`.

**Acceptance criteria**
- [ ] `ServingStepper` nhân lượng nguyên liệu (hàm của SET-08)
- [ ] Checklist "Lấy đồ ra" (Đã lấy x/y); nguyên liệu tuỳ chọn hiện ghi chú thay thế
- [ ] Thứ còn thiếu → "Thêm vào đi chợ" (từ `plan.dart`); "Bắt đầu nấu" → Từng bước
EOF

issue "COOK-03 · Nấu từng bước" "$W3" "P0,size:M,type:feature,feature:cook" <<'EOF'
Theo `CookStep.dc.html`.

**Acceptance criteria**
- [ ] Mỗi màn một bước, chữ 24/34, nút Bước trước / Bước tiếp sát đáy (lg 56px), bottom sheet Nguyên liệu
- [ ] `StepTimer` cho bước có thời gian; hết giờ khi đang ở app khác → thông báo qua `NotificationService` (từ `system.dart`)
- [ ] Màn hình luôn sáng (`wakelock_plus`)
- [ ] Lưu tiến độ → `ResumeCookingBanner` "Đang nấu dở … bước 2/4 · Nấu tiếp"
EOF

issue "COOK-04 · Hoàn thành & đánh giá món" "$W3" "P0,size:M,type:feature,feature:cook" <<'EOF'
Theo `CookDone.dc.html`, `RateApp.dc.html`.

**Acceptance criteria**
- [ ] "Cập nhật Tủ đồ": tick thứ đã dùng hết → bỏ khỏi tủ qua `pantry.dart`
- [ ] Đánh giá Ngon / Tạm / Chê lưu vào lịch sử nấu; "Chê" → món tạm lùi trong gợi ý 3 ngày
- [ ] Hộp đánh giá Google Play (`in_app_review`) sau vài lần "Ngon", không hỏi lại liên tục
EOF

issue "COOK-09 · Polish & test Nấu" "$W4" "P1,size:S,type:feature,feature:cook" <<'EOF'
- [ ] Widget test: đổi khẩu phần, qua bước, hẹn giờ, hoàn thành cập nhật tủ
- [ ] Sáng/tối, text scale 1.3, màn 360dp; so khớp prototype
- [ ] Analytics: `view_recipe`, `start_cooking`, `finish_cooking`, `rate_recipe`
EOF

# ======================================================================== F3 · Tủ đồ & gợi ý (Lead)

issue "PAN-00 · Public API Tủ đồ & gợi ý + AvailabilityBadge" "$W1" "P0,size:S,type:feature,feature:pantry" <<'EOF'
**Acceptance criteria**
- [ ] `lib/features/pantry/pantry.dart` (stub chạy được): `pantryItemsProvider`, `addToPantry`, `removeFromPantry`, `availabilityFor(recipe)` (Đủ đồ / Thiếu: …), `suggest(meal, count)`, `dislike(recipeId, reason)`
- [ ] `AvailabilityBadge` trong `lib/core/widgets/` đúng README component

**Hạn:** 24/10 — 4 feature còn lại gọi các API này.
EOF

issue "PAN-01 · Màn Tủ đồ" "$W2" "P0,size:M,type:feature,feature:pantry" <<'EOF'
Theo `Pantry.dc.html`.

**Acceptance criteria**
- [ ] Nguyên liệu theo nhóm, bấm để bật/tắt, lưu qua `LocalStore`
- [ ] "Nấu được ngay (n)" và "Thiếu 1–2 thứ" cập nhật tức thì; trống → gợi ý bật thêm nguyên liệu
EOF

issue "PAN-02 · Bộ gợi ý món" "$W3" "P0,size:L,type:feature,feature:pantry" <<'EOF'
**Mục tiêu:** Một bộ gợi ý dùng chung cho Khám phá, Hôm nay ăn gì, Tủ đồ và Gợi ý cả tuần.

**Acceptance criteria**
- [ ] Lọc theo dụng cụ và chế độ ăn (`kitchenProfileProvider` của system)
- [ ] Xếp hạng: đủ đồ > thiếu ít; ưu tiên món đã lưu; lùi 3 ngày món bị "Chê"/"Không thích"; tránh món vừa nấu; hợp bữa (sáng/trưa/tối)
- [ ] Kèm lý do ngắn cho Today ("Đủ đồ, 15 phút, bếp từ")
- [ ] Hàm thuần trong `domain/`, unit test đầy đủ
EOF

issue "PAN-09 · Polish & test Tủ đồ" "$W4" "P1,size:S,type:feature,feature:pantry" <<'EOF'
- [ ] Widget test bật/tắt nguyên liệu; sáng/tối, text scale 1.3, màn 360dp
- [ ] Analytics: `pantry_update`, `pantry_ready_count`
EOF

# ======================================================================== F4 · Thực đơn & đi chợ (plan)

issue "PLAN-00 · Component ô thực đơn, dải chọn ngày + public API" "$W1" "P0,size:M,type:feature,feature:plan" <<'EOF'
**Acceptance criteria**
- [ ] `MealSlot` (trống: viền đứt `outline` + "Thêm món"; có món: tên + meta) và `DayStrip` — design system chưa có, tự đề xuất theo token + prototype `MealPlan`, Lead duyệt
- [ ] Public API stub `lib/features/plan/plan.dart`: `addToPlan(recipeId, day, meal)`, `addToShopping(recipeId, servings)`, `plannedMealsProvider`, route `/shopping`

**Phụ thuộc:** SET-15. **Hạn:** 24/10.
EOF

issue "PLAN-01 · Thực đơn theo ngày" "$W2" "P0,size:M,type:feature,feature:plan" <<'EOF'
Theo `MealPlan.dc.html` (chế độ Ngày).

**Acceptance criteria**
- [ ] `DayStrip`, 3 bữa Sáng / Trưa / Tối, "Đã lên x/21 bữa"
- [ ] Thêm món vào ô (chọn từ Đã lưu hoặc tìm), đổi, xoá; lưu qua `LocalStore`
EOF

issue "PLAN-02 · Thực đơn theo tuần + gợi ý cả tuần" "$W2" "P0,size:M,type:feature,feature:plan" <<'EOF'
**Acceptance criteria**
- [ ] Chuyển Ngày / Tuần; lưới 7 ngày × 3 bữa
- [ ] "Gợi ý cả tuần" lấp ô trống bằng `suggest()` (không ghi đè ô đã có)
- [ ] Bottom sheet "Thêm vào thực đơn" chọn ngày + bữa (Chi tiết dùng qua `addToPlan`)
EOF

issue "SHP-01 · Danh sách đi chợ" "$W3" "P0,size:M,type:feature,feature:plan" <<'EOF'
Theo `Shopping.dc.html`.

**Acceptance criteria**
- [ ] Gom nguyên liệu của thực đơn tuần + món thêm từ Chuẩn bị nấu, nhân theo khẩu phần, gộp trùng
- [ ] Trừ đồ có trong Tủ đồ, báo "Đã bỏ n thứ có sẵn trong Tủ đồ: …"
- [ ] Nhóm theo loại, ghi món dùng tới; tick đã mua; "Xong, cất vào tủ" → `addToPantry`
- [ ] Logic gom/trừ là hàm thuần + unit test. **Không có giá tiền.**
EOF

issue "PLAN-09 · Polish & test Thực đơn" "$W4" "P1,size:S,type:feature,feature:plan" <<'EOF'
- [ ] Widget test: thêm món vào ô, gợi ý cả tuần, đi chợ trừ tủ
- [ ] Sáng/tối, text scale 1.3, màn 360dp; so khớp prototype
- [ ] Analytics: `plan_add`, `plan_suggest_week`, `shopping_done`
EOF

# ======================================================================== F5 · Hệ thống (system)

issue "SYS-00 · Icon, ô cài đặt + public API" "$W1" "P0,size:S,type:feature,feature:system" <<'EOF'
**Acceptance criteria**
- [ ] Map bộ `Icon` của design sang Material Symbols Rounded (`core/widgets/app_icon.dart`)
- [ ] Widget hàng cài đặt dùng chung (tiêu đề, ghi chú, chevron/switch)
- [ ] Public API stub `lib/features/system/system.dart`: `kitchenProfileProvider` (dụng cụ, chế độ ăn), `themeModeProvider`, `NotificationService` (`timerDone`, `mealReminder`)

**Phụ thuộc:** SET-15. **Hạn:** 24/10.
EOF

issue "SYS-01 · Onboarding: bếp của bạn" "$W2" "P0,size:M,type:feature,feature:system" <<'EOF'
Theo `Onboarding.dc.html`.

**Acceptance criteria**
- [ ] Lần đầu mở app: chọn dụng cụ (Nồi cơm điện, Bếp từ / bếp ga, Lò vi sóng, Ấm siêu tốc) và chế độ ăn; có "Bỏ qua"
- [ ] Lưu vào `kitchenProfileProvider`; xong → xin quyền thông báo (SYS-03) → Khám phá
EOF

issue "SYS-02 · Cài đặt" "$W2" "P0,size:M,type:feature,feature:system" <<'EOF'
Theo `Settings.dc.html`.

**Acceptance criteria**
- [ ] Giao diện Sáng / Tối / Theo hệ thống → `themeModeProvider`, đổi ngay
- [ ] Sửa dụng cụ & chế độ ăn (tái dùng màn Onboarding)
- [ ] Bật/tắt thông báo hẹn giờ và nhắc bữa; links Giới thiệu, Chính sách, Góp ý; Xoá dữ liệu
EOF

issue "SYS-03 · Thông báo: xin quyền, hẹn giờ, nhắc bữa" "$W3" "P0,size:M,type:feature,feature:system" <<'EOF'
Theo `NotifPermission.dc.html`.

**Acceptance criteria**
- [ ] Màn giải thích trước khi xin quyền (Android 13+), "Để sau" không hỏi lại ngay
- [ ] `NotificationService.timerDone` (Nấu từng bước gọi), `mealReminder` theo `plannedMealsProvider`, giờ nhắc do người dùng chọn
- [ ] Icon thông báo dùng logo monochrome
EOF

issue "SYS-05 · Góp ý & báo lỗi" "$W3" "P0,size:M,type:feature,feature:system" <<'EOF'
Theo `Feedback.dc.html`.

**Acceptance criteria**
- [ ] Chọn loại góp ý (chip), nội dung, đính kèm ảnh chụp màn hình, email (không bắt buộc), tick gửi kèm thông tin máy
- [ ] Gửi qua `FeedbackRepository` (SET-17); lỗi mạng → báo và giữ nội dung
- [ ] Màn lỗi "Báo lỗi cho nhóm" mở màn này kèm mã lỗi

**Phụ thuộc:** SET-17
EOF

issue "SYS-04 · Giới thiệu, Chính sách, Xoá dữ liệu" "$W4" "P0,size:S,type:feature,feature:system" <<'EOF'
Theo `About.dc.html`, `Policy.dc.html`, `ClearData.dc.html`.

**Acceptance criteria**
- [ ] Giới thiệu: phiên bản thật (`package_info_plus`), tên nhóm, liên hệ, giấy phép mã nguồn mở
- [ ] Chính sách: điền phần còn để trống (nơi nhận góp ý, Crashlytics từ SET-16)
- [ ] Xoá dữ liệu: nút `danger` chỉ mở khi gõ đúng `CONFIRM DELETE` → `LocalStore.clearAll()` → về Splash
EOF

issue "SYS-09 · Polish & test Hệ thống" "$W4" "P1,size:S,type:feature,feature:system" <<'EOF'
- [ ] Widget test: onboarding lưu hồ sơ, đổi theme, xoá dữ liệu cần gõ xác nhận
- [ ] Sáng/tối, text scale 1.3, màn 360dp
- [ ] Analytics: `onboarding_done`, `theme_change`, `feedback_send`
EOF

# ======================================================================== Việc chung

issue "CNT-01 · Danh mục nguyên liệu + 15 công thức đầu" "$W1" "P0,size:L,type:content,shared" <<'EOF'
**Mục tiêu:** Dữ liệu thật cho bếp ký túc xá Hoà Lạc. Mỗi người 3 món. **Không ghi giá.**

**Acceptance criteria**
- [ ] `assets/data/ingredients.json`: ~60 nguyên liệu theo nhóm như màn Tủ đồ, đánh dấu gia vị cơ bản
- [ ] 15 công thức đúng `docs/data-model.md`: thời gian, khẩu phần, dụng cụ, chế độ ăn, bữa, nguyên liệu (tuỳ chọn + cách thay), bước kèm thời gian hẹn giờ
- [ ] Giọng văn theo brand book: xưng "bạn", câu ngắn, không emoji
- [ ] Ảnh tự chụp hoặc giấy phép rõ ràng

**Phụ thuộc:** SET-08 (schema)
EOF

issue "CNT-02 · Bổ sung lên ≥ 40 công thức" "$W2" "P0,size:M,type:content,shared" <<'EOF'
- [ ] Mỗi người thêm 5 món → ≥ 40, phủ đều 4 dụng cụ, các chế độ ăn và 3 bữa (đủ để "Gợi ý cả tuần" lấp 21 bữa)
- [ ] Món nào cũng có người nấu thử hoặc kiểm tra lại

**Phụ thuộc:** CNT-01
EOF

issue "REL-06 · Test với 8–10 sinh viên Hoà Lạc" "$W4" "P0,size:M,type:content,shared,release" <<'EOF'
- [ ] Mỗi người mời 2 bạn, quan sát họ dùng feature của mình
- [ ] Kịch bản: lần đầu mở app, Hôm nay ăn gì, bật Tủ đồ rồi nấu một món, lên thực đơn tuần và đi chợ
- [ ] Góp ý qua màn Góp ý trong app; tổng hợp thành issue gắn label feature trước 12/11

**Phụ thuộc:** SET-13
EOF

issue "REL-07 · Bug bash + buffer sửa lỗi (time-box 2 ngày)" "$W4" "P0,size:L,type:chore,shared,release" <<'EOF'
- [ ] Bug bash 1 buổi trên nhiều máy Android, cả sáng lẫn tối; bug gắn label feature → về đúng chủ
- [ ] Đóng hết bug P0 trước 15/11
EOF

# ======================================================================== Stretch (không milestone)

issue "STR-01 · Người dùng đăng công thức" - "P2,size:L,type:feature,stretch" <<'EOF'
Cần thêm tài khoản và backend cho dữ liệu món — khi đó chuyển dữ liệu `LocalStore` lên tài khoản ở lần đăng nhập đầu.
EOF

issue "STR-02 · Gợi ý thực đơn tuần bằng AI" - "P2,size:L,type:feature,stretch" <<'EOF'
Thay luật xếp hạng của "Gợi ý cả tuần" bằng LLM qua Cloud Function (không để API key trong app), chỉ chọn trong dữ liệu có sẵn.
EOF

issue "STR-03 · Cập nhật công thức không cần ra bản app mới" - "P2,size:M,type:chore,stretch" <<'EOF'
Tải `recipes.json` mới từ Firebase Storage/Remote Config, fallback về bản đóng gói khi offline.
EOF

echo "Done. Project: https://github.com/users/$OWNER/projects/$PROJECT"
