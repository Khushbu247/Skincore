import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be configured before running: see the README section on
  // `flutterfire configure`. This generates lib/firebase_options.dart and is
  // required — auth, Firestore, and Storage all depend on it, and routing
  // reads FirebaseAuth.instance directly.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('❌ Firebase.initializeApp() failed: $e');
    debugPrint('   Run `flutterfire configure` in mobile/ before `flutter run`.');
    rethrow;
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SkinCoreApp(),
    ),
  );
}

class SkinCoreApp extends ConsumerWidget {
  const SkinCoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SkinCore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
