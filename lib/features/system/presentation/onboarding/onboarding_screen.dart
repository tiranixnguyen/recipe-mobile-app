import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../discover/discover.dart';
import '../../strings.dart';
import 'onboarding_view_model.dart';

/// Màn tạm Lead dựng cho luồng khởi động; SYS-01 thay bằng màn chọn dụng cụ và chế độ ăn
/// (prototype `Onboarding`), giữ cách tách View / ViewModel này.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  // TODO(SYS-03): nút Xong đi NotifPermission (prototype `Onboarding`); Bỏ qua vẫn về Khám phá.
  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingViewModelProvider.notifier).finish();
    if (context.mounted) context.go(discoverLocation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final onFinish = state.finishing ? null : () => _finish(context, ref);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: onFinish, child: const Text(SystemStrings.onboardingSkip)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          SystemStrings.onboardingTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FilledButton(
            onPressed: onFinish,
            child: const Text(SystemStrings.onboardingDone),
          ),
        ),
      ),
    );
  }
}
