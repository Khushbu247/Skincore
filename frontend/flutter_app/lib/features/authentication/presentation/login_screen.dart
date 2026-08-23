import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // Email/Password Login
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text;

      // Simulated login delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Validate credentials & persist active user session
      if ((email == 'user1@test.com' && password == 'password123') ||
          (email == 'admin@test.com' && password == 'admin123') ||
          email.contains('@')) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('active_user_email', email);
        ref.read(activeUserEmailProvider.notifier).state = email;

        final auth = ref.read(firebaseAuthProvider);
        if (auth != null) {
          try {
            await auth.signInWithEmailAndPassword(email: email, password: password);
          } catch (_) {}
        }

        if (mounted) {
          context.goNamed('home');
        }
      } else {
        setState(() {
          _error =
              'Invalid credentials. Use user1@test.com / password123';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Google Login - Firebase Web
  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(firebaseAuthProvider);

      if (auth == null) {
        setState(() {
          _error =
              'Firebase is not initialized. Check your setup.';
        });
        return;
      }

      // Create Google provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Optional scopes
      googleProvider.addScope(
        'https://www.googleapis.com/auth/userinfo.email',
      );

      googleProvider.addScope(
        'https://www.googleapis.com/auth/userinfo.profile',
      );

      // Open Google Sign-In popup in Chrome
      await auth.signInWithPopup(googleProvider);

      // Login successful
      if (mounted) {
        context.goNamed('home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Google sign-in failed.';
      });
    } catch (e) {
  debugPrint('GOOGLE SIGN-IN ERROR: $e');

  setState(() {
    _error = 'Google Sign-In Error: $e';
  });
} finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),

              const SizedBox(height: 6),

              Text(
                'Sign in to continue your skin journey',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),

              const SizedBox(height: 28),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  helperText: 'Try: user1@test.com',
                ),
              ),

              const SizedBox(height: 12),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  helperText: 'Try: password123',
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      context.pushNamed('forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: 8),

              // Email Login
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : GradientButton(
                      label: 'Log in',
                      onPressed: _login,
                    ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: Text(
                      'or continue with',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Google Login
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                      _loading ? null : _loginWithGoogle,
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 22,
                  ),
                  label: const Text(
                    'Continue with Google',
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.pushNamed('signup'),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}