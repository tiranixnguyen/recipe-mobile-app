import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_view_model.dart';

void main() {
  test('hiện phiên bản thật khi đọc xong', () async {
    final container = ProviderContainer(
      overrides: [appVersionProvider.overrideWith((ref) async => '0.1.0')],
    );
    addTearDown(container.dispose);
    final sub = container.listen(aboutViewModelProvider, (_, _) {});

    expect(sub.read().version, isNull);
    await container.read(appVersionProvider.future);
    expect(sub.read().version, '0.1.0');
  });
}
