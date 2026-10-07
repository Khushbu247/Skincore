import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// ApiService provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Firebase Auth provider (safely returns instance if available)
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  try {
    return FirebaseAuth.instance;
  } catch (_) {
    return null;
  }
});

/// Stream of the current auth user with fallback dev support
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth != null) {
    try {
      return auth.authStateChanges();
    } catch (_) {}
  }
  // Fallback stream when Firebase is not yet configured
  return Stream.value(null);
});

/// Active User Email state provider
final activeUserEmailProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('active_user_email');
});

/// Centralized User ID Provider (works seamlessly with Firebase Auth & email sessions)
final activeUserIdProvider = Provider<String>((ref) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
    return firebaseUser.uid;
  }
  final email = ref.watch(activeUserEmailProvider);
  if (email != null && email.isNotEmpty) {
    final sanitized = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'user_$sanitized';
  }
  return 'user_demo_default';
});

/// Local storage provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Overridden in main() after SharedPreferences.getInstance()');
});

class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> completeOnboarding() async {
    state = true;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_complete', true);
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

/// Theme mode controller
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, next.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
