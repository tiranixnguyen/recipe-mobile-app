import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_mobile_app/app/app.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWith((ref) => SharedPrefsLocalStore(prefs))],
      child: const App(),
    ),
  );
}
