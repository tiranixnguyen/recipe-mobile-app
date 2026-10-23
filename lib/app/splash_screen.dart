import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../features/discover/discover.dart';
import '../features/system/system.dart';
import 'strings.dart';

/// Màn khởi động (prototype `Splash`). Lần đầu mở app đi tới Onboarding, các lần sau vào thẳng Khám phá.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 800);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, _next);
  }

  void _next() {
    final onboarded = ref.read(onboardingDoneProvider);
    context.go(onboarded ? discoverLocation : onboardingLocation);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.appName, style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s2),
            Text(AppStrings.tagline, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
