import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trà sữa Hoà Lạc',
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: _router,
    );
  }
}
