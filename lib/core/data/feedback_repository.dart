import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loại góp ý người dùng chọn ở màn Góp ý.
enum FeedbackKind { bug, recipe, other }

/// Gửi góp ý của người dùng cho nhóm — dữ liệu duy nhất rời khỏi máy.
///
/// Hiện là stub ([StubFeedbackRepository]). TODO(SET-17): bản thật gửi lên Firebase, chữ ký giữ nguyên.
abstract interface class FeedbackRepository {
  /// Ném lỗi khi không gửi được (mất mạng…); màn Góp ý giữ nguyên nội dung để gửi lại.
  Future<void> send({
    required FeedbackKind kind,
    required String message,
    Uint8List? screenshot,
    String? email,
    Map<String, String>? deviceInfo,
  });
}

/// Chỉ in ra log, coi như gửi thành công.
class StubFeedbackRepository implements FeedbackRepository {
  const StubFeedbackRepository();

  @override
  Future<void> send({
    required FeedbackKind kind,
    required String message,
    Uint8List? screenshot,
    String? email,
    Map<String, String>? deviceInfo,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    debugPrint(
      'Góp ý (stub) ${kind.name}: $message · ảnh ${screenshot?.length ?? 0} byte · '
      'email ${email ?? '-'} · máy $deviceInfo',
    );
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => const StubFeedbackRepository(),
);
