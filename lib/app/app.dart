import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/system/system.dart';
import 'router.dart';
import 'strings.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final GoRouter _router = createRouter(
    isOnboarded: () => ref.read(onboardingDoneProvider),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme tạm; SET-15 thay bằng theme dựng từ tokens.json.
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: ThemeData(brightness: Brightness.light, fontFamily: 'Be Vietnam Pro'),
      darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'Be Vietnam Pro'),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: _router,
    );
  }
}
