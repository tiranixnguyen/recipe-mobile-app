import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/feedback_repository.dart';
import 'package:recipe_mobile_app/features/system/data/device_info.dart';
import 'package:recipe_mobile_app/features/system/data/screenshot_picker.dart';
import 'package:recipe_mobile_app/features/system/presentation/feedback/feedback_view_model.dart';

typedef _Sent = ({
  FeedbackKind kind,
  String message,
  Uint8List? screenshot,
  String? email,
  Map<String, String>? deviceInfo,
});

class _FakeRepository implements FeedbackRepository {
  final sent = <_Sent>[];
  bool fail = false;

  @override
  Future<void> send({
    required FeedbackKind kind,
    required String message,
    Uint8List? screenshot,
    String? email,
    Map<String, String>? deviceInfo,
  }) async {
    if (fail) throw Exception('mất mạng');
    sent.add((
      kind: kind,
      message: message,
      screenshot: screenshot,
      email: email,
      deviceInfo: deviceInfo,
    ));
  }
}

void main() {
  late _FakeRepository repository;
  late Uint8List? picked;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRepository();
    picked = null;
    container = ProviderContainer(
      overrides: [
        feedbackRepositoryProvider.overrideWithValue(repository),
        deviceInfoProvider.overrideWith((ref) async => {'app': '0.1.0', 'android': '15'}),
        pickScreenshotProvider.overrideWithValue(() async => picked),
      ],
    );
  });

  tearDown(() => container.dispose());

  ProviderSubscription<FeedbackState> listen([String? code]) =>
      container.listen(feedbackViewModelProvider(code), (_, _) {});
  FeedbackViewModel viewModel([String? code]) =>
      container.read(feedbackViewModelProvider(code).notifier);

  test('mặc định: Báo lỗi, gửi kèm thông tin máy, chưa gửi được khi trống', () {
    final sub = listen();
    expect(sub.read().kind, FeedbackKind.bug);
    expect(sub.read().includeDeviceInfo, isTrue);
    expect(sub.read().canSend, isFalse);

    viewModel().setMessage('   ');
    expect(sub.read().canSend, isFalse);
  });

  test('email: để trống được, điền sai thì không gửi được', () {
    final sub = listen();
    viewModel().setMessage('App đứng hình');
    expect(sub.read().canSend, isTrue);

    viewModel().setEmail('ban@vidu');
    expect(sub.read().emailValid, isFalse);
    expect(sub.read().canSend, isFalse);

    viewModel().setEmail(' ban@vidu.com ');
    expect(sub.read().canSend, isTrue);
  });

  test('gửi đúng nội dung, ảnh, email và thông tin máy', () async {
    listen();
    picked = Uint8List.fromList([1, 2, 3]);
    viewModel()
      ..setKind(FeedbackKind.recipe)
      ..setMessage('  Thêm món lò vi sóng  ')
      ..setEmail('ban@vidu.com');
    await viewModel().pickScreenshot();

    expect(await viewModel().send(), isTrue);

    final sent = repository.sent.single;
    expect(sent.kind, FeedbackKind.recipe);
    expect(sent.message, 'Thêm món lò vi sóng');
    expect(sent.screenshot, [1, 2, 3]);
    expect(sent.email, 'ban@vidu.com');
    expect(sent.deviceInfo, {'app': '0.1.0', 'android': '15'});
  });

  test('bỏ tick thông tin máy, không điền email thì không gửi hai thứ đó', () async {
    listen();
    viewModel()
      ..setMessage('Góp ý')
      ..setIncludeDeviceInfo(false);

    await viewModel().send();

    expect(repository.sent.single.deviceInfo, isNull);
    expect(repository.sent.single.email, isNull);
  });

  test('gửi lỗi: báo false, giữ nguyên nội dung, gửi lại được', () async {
    final sub = listen();
    repository.fail = true;
    viewModel()
      ..setMessage('App đứng hình')
      ..setEmail('ban@vidu.com');

    expect(await viewModel().send(), isFalse);
    expect(sub.read().message, 'App đứng hình');
    expect(sub.read().email, 'ban@vidu.com');
    expect(sub.read().sending, isFalse);
    expect(sub.read().canSend, isTrue);

    repository.fail = false;
    expect(await viewModel().send(), isTrue);
  });

  test('ảnh quá 2 MB thì không đính kèm, báo lỗi; bỏ ảnh được', () async {
    final sub = listen();
    picked = Uint8List(maxScreenshotBytes + 1);
    await viewModel().pickScreenshot();
    expect(sub.read().screenshot, isNull);
    expect(sub.read().screenshotTooBig, isTrue);

    picked = Uint8List(10);
    await viewModel().pickScreenshot();
    expect(sub.read().screenshot, hasLength(10));
    expect(sub.read().screenshotTooBig, isFalse);

    viewModel().removeScreenshot();
    expect(sub.read().screenshot, isNull);
  });

  test('huỷ chọn ảnh thì giữ ảnh cũ', () async {
    final sub = listen();
    picked = Uint8List(10);
    await viewModel().pickScreenshot();
    picked = null;
    await viewModel().pickScreenshot();

    expect(sub.read().screenshot, hasLength(10));
  });

  test('mở từ màn lỗi: Báo lỗi, nội dung ghi sẵn mã lỗi', () {
    final sub = listen('ERR-0042');

    expect(sub.read().kind, FeedbackKind.bug);
    expect(sub.read().message, startsWith('Mã lỗi: ERR-0042'));
    expect(sub.read().canSend, isTrue);
  });
}
