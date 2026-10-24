import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/feedback_repository.dart';
import 'package:recipe_mobile_app/features/system/data/device_info.dart';
import 'package:recipe_mobile_app/features/system/data/screenshot_picker.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Ảnh đính kèm tối đa 2 MB.
const maxScreenshotBytes = 2 * 1024 * 1024;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// State của màn Góp ý.
@immutable
class FeedbackState {
  const FeedbackState({
    this.kind = FeedbackKind.bug,
    this.message = '',
    this.email = '',
    this.includeDeviceInfo = true,
    this.screenshot,
    this.screenshotTooBig = false,
    this.sending = false,
  });

  final FeedbackKind kind;
  final String message;
  final String email;
  final bool includeDeviceInfo;
  final Uint8List? screenshot;

  /// Ảnh vừa chọn lớn hơn [maxScreenshotBytes] nên không đính kèm.
  final bool screenshotTooBig;
  final bool sending;

  /// Email để trống là được; điền thì phải đúng dạng.
  bool get emailValid => email.trim().isEmpty || _emailPattern.hasMatch(email.trim());

  bool get canSend => message.trim().isNotEmpty && emailValid && !sending;

  FeedbackState copyWith({
    FeedbackKind? kind,
    String? message,
    String? email,
    bool? includeDeviceInfo,
    ValueGetter<Uint8List?>? screenshot,
    bool? screenshotTooBig,
    bool? sending,
  }) => FeedbackState(
    kind: kind ?? this.kind,
    message: message ?? this.message,
    email: email ?? this.email,
    includeDeviceInfo: includeDeviceInfo ?? this.includeDeviceInfo,
    screenshot: screenshot != null ? screenshot() : this.screenshot,
    screenshotTooBig: screenshotTooBig ?? this.screenshotTooBig,
    sending: sending ?? this.sending,
  );
}

/// [errorCode] khác null khi mở từ màn lỗi ("Báo lỗi cho nhóm"): chọn sẵn Báo lỗi và ghi mã lỗi.
class FeedbackViewModel extends Notifier<FeedbackState> {
  FeedbackViewModel(this.errorCode);

  final String? errorCode;

  @override
  FeedbackState build() {
    final code = errorCode;
    return code == null
        ? const FeedbackState()
        : FeedbackState(message: '${SystemStrings.feedbackErrorCode(code)}\n');
  }

  void setKind(FeedbackKind kind) => state = state.copyWith(kind: kind);

  void setMessage(String message) => state = state.copyWith(message: message);

  void setEmail(String email) => state = state.copyWith(email: email);

  void setIncludeDeviceInfo(bool on) => state = state.copyWith(includeDeviceInfo: on);

  Future<void> pickScreenshot() async {
    final bytes = await ref.read(pickScreenshotProvider)();
    if (bytes == null || !ref.mounted) return;
    state = bytes.length > maxScreenshotBytes
        ? state.copyWith(screenshot: () => null, screenshotTooBig: true)
        : state.copyWith(screenshot: () => bytes, screenshotTooBig: false);
  }

  void removeScreenshot() =>
      state = state.copyWith(screenshot: () => null, screenshotTooBig: false);

  /// Gửi góp ý; trả về `true` khi gửi được. Lỗi thì giữ nguyên nội dung để người dùng gửi lại.
  Future<bool> send() async {
    if (!state.canSend) return false;
    state = state.copyWith(sending: true);
    final email = state.email.trim();
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .send(
            kind: state.kind,
            message: state.message.trim(),
            screenshot: state.screenshot,
            email: email.isEmpty ? null : email,
            deviceInfo: state.includeDeviceInfo ? await _deviceInfo() : null,
          );
      return true;
    } on Object catch (error) {
      debugPrint('Không gửi được góp ý: $error');
      return false;
    } finally {
      if (ref.mounted) state = state.copyWith(sending: false);
    }
  }

  /// Không đọc được thông tin máy thì vẫn gửi góp ý, chỉ thiếu phần này.
  Future<Map<String, String>?> _deviceInfo() async {
    try {
      return await ref.read(deviceInfoProvider.future);
    } on Object {
      return null;
    }
  }
}

final feedbackViewModelProvider = NotifierProvider.autoDispose
    .family<FeedbackViewModel, FeedbackState, String?>(FeedbackViewModel.new);
