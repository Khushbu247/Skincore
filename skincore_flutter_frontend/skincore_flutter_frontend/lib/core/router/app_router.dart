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
  final hasOnboarded = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final loggedIn = authState.value != null;
      final loading = authState.isLoading;
      final path = state.matchedLocation;

      if (loading) return null; // wait for auth stream to resolve

      final isAuthRoute = path == '/login' || path == '/signup' || path == '/forgot-password';
      final isOnboardingRoute = path == '/onboarding';

      if (!hasOnboarded && !isOnboardingRoute) return '/onboarding';
      if (hasOnboarded && isOnboardingRoute) return loggedIn ? '/home' : '/login';
      if (!loggedIn && !isAuthRoute && !isOnboardingRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const LoginScreen(), // Phase 3 will split this out
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const LoginScreen(), // Phase 3 will split this out
      ),

      // Full-screen flows (pushed above the shell)
      GoRoute(path: '/scan', name: 'scan', builder: (context, state) => const SkinScanScreen()),
      GoRoute(path: '/questionnaire', name: 'questionnaire', builder: (context, state) => const QuestionnaireScreen()),
      GoRoute(
        path: '/recommendations',
        name: 'recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),

      // Bottom-nav shell
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(path: '/home', name: 'home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/progress', name: 'progress', builder: (context, state) => const ProgressScreen()),
          GoRoute(path: '/chat', name: 'chat', builder: (context, state) => const ChatbotScreen()),
          GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's authStateProvider stream into a Listenable so
/// go_router re-evaluates `redirect` whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
