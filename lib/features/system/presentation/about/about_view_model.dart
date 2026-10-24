import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/features/system/data/app_info.dart';

class AboutState {
  const AboutState({this.version});

  /// Null khi chưa đọc xong.
  final String? version;
}

class AboutViewModel extends Notifier<AboutState> {
  @override
  AboutState build() => AboutState(version: ref.watch(appVersionProvider).value);
}

final aboutViewModelProvider = NotifierProvider.autoDispose<AboutViewModel, AboutState>(
  AboutViewModel.new,
);
