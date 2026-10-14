---
description: Làm một GitHub issue theo quy trình của team
---

1. Hỏi số issue nếu chưa có. Đọc issue bằng `gh issue view <N>` (hoặc nội dung người dùng dán vào).
2. Đọc `AGENTS.md`, xác định feature của issue từ label `feature:*` hoặc thư mục được nhắc tới.
3. Viết plan: file sẽ tạo/sửa (chỉ trong thư mục feature đó), test sẽ viết. Dừng lại chờ duyệt.
4. Tạo branch `feat/<N>-<slug>` từ nhánh base của issue, rồi code.
5. Chạy `fvm dart format lib test && fvm flutter analyze && fvm flutter test`, sửa đến khi sạch.
6. Tóm tắt thay đổi và gợi ý nội dung PR theo `.github/pull_request_template.md`, có `Closes #<N>`.
