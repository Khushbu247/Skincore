import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/skin_scan/presentation/skin_scan_screen.dart';
import '../../features/questionnaire/presentation/questionnaire_screen.dart';
import '../../features/recommendations/presentation/recommendations_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/progress_tracker/presentation/progress_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasOnboarded = ref.watch(onboardingControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,

    initialLocation: hasOnboarded ? '/home' : '/onboarding',

    redirect: (context, state) {
      // Firebase authentication is still loading
      if (authState.isLoading) {
        return null;
      }

      final path = state.matchedLocation;

      // Current Firebase user
      final user = authState.value;

      final isOnboardingRoute = path == '/onboarding';
      final isLoginRoute =
          path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password';

      // --------------------------------------------------
      // 1. Onboarding not completed
      // --------------------------------------------------
      if (!hasOnboarded) {
        if (!isOnboardingRoute) {
          return '/onboarding';
        }

        return null;
      }

      // --------------------------------------------------
      // 2. Onboarding completed but user is NOT logged in
      // --------------------------------------------------
      if (user == null) {
        if (!isLoginRoute) {
          return '/login';
        }

        return null;
      }

      // --------------------------------------------------
      // 3. User is logged in
      // --------------------------------------------------
      // Don't allow logged-in users to remain on login pages.
      if (isLoginRoute || isOnboardingRoute) {
        return '/home';
      }

      return null;
    },

    refreshListenable: GoRouterRefreshStream(ref),

    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const LoginScreen(),
      ),

      // Skin features
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const SkinScanScreen(),
      ),

      GoRoute(
        path: '/questionnaire',
        name: 'questionnaire',
        builder: (context, state) => const QuestionnaireScreen(),
      ),

      GoRoute(
        path: '/recommendations',
        name: 'recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),

      // Dashboard
      ShellRoute(
        builder: (context, state, child) =>
            DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          GoRoute(
            path: '/progress',
            name: 'progress',
            builder: (context, state) => const ProgressScreen(),
          ),

          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatbotScreen(),
          ),

          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}