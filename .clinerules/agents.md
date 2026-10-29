# Luật cho Cline

Đọc và làm theo [`AGENTS.md`](../AGENTS.md) ở gốc repo trước khi code. Đó là luật chung cho mọi agent: luật sản
phẩm, kiến trúc, ranh giới feature, quy trình làm issue và Definition of Done.

Nhắc riêng cho Cline:

- Chỉ làm issue có label `agent:cline`. Đọc comment giao việc trên issue để biết issue nào phải merge trước.
- Luôn dùng `fvm`. Trước khi mở PR, chạy `fvm dart format lib test && fvm flutter analyze && fvm flutter test`
  và phải sạch.
- Cần sửa `lib/core/`, `lib/app/`, `pubspec.yaml` hoặc `assets/` mà issue không giao thì dừng lại, ghi vào PR.
- Mở PR theo template, có `Closes #<N>`. Lead review trước khi merge.
