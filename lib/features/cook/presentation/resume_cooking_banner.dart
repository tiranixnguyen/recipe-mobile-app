import 'package:flutter/widgets.dart';

/// Thanh "Đang nấu dở · Nấu tiếp" ở đầu màn Khám phá (prototype `Main`, `showResume`).
///
/// Stub (COOK-00): chưa lưu phiên nấu nên luôn ẩn. Màn chế độ nấu làm bản thật; màn Khám phá cứ
/// đặt sẵn `const ResumeCookingBanner()`, không phải sửa khi bản thật xong.
class ResumeCookingBanner extends StatelessWidget {
  const ResumeCookingBanner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
