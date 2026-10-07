import 'dart:convert';
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
  final _confirmPasswordCtrl = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? _error;

  Future<void> _submitEmailAuth() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    if (_isSignUpMode && password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final auth = ref.read(firebaseAuthProvider);

      // Load persistent credentials store
      final String rawStore = prefs.getString('user_credentials_store') ?? '{}';
      Map<String, dynamic> userStore = {};
      try {
        userStore = jsonDecode(rawStore) as Map<String, dynamic>;
      } catch (_) {}

      if (_isSignUpMode) {
        // --- NEW USER SIGN UP ---
        if (userStore.containsKey(email)) {
          setState(() {
            _error = 'An account with this email already exists. Please log in.';
            _loading = false;
          });
          return;
        }

        // Try Firebase Auth Registration if configured
        if (auth != null) {
          try {
            await auth.createUserWithEmailAndPassword(email: email, password: password);
            // Sign out of Firebase immediately so user performs explicit login
            await auth.signOut();
          } on FirebaseAuthException catch (fe) {
            if (fe.code == 'email-already-in-use') {
              setState(() {
                _error = 'This email is already registered in Firebase. Please log in.';
                _loading = false;
              });
              return;
            }
          } catch (_) {}
        }

        // Save credential to local persistent user store
        userStore[email] = password;
        await prefs.setString('user_credentials_store', jsonEncode(userStore));

        if (mounted) {
          setState(() {
            _loading = false;
          });

          // Show proper Success Card Modal
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Created Successfully!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You can now log into your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log In Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Reset forms and transition to Login Mode
          setState(() {
            _isSignUpMode = false;
            _passwordCtrl.clear();
            _confirmPasswordCtrl.clear();
            _error = null;
          });
        }
      } else {
        // --- LOG IN MODE ---
        bool authenticated = false;

        // 1. Check local persistent store
        if (userStore.containsKey(email) && userStore[email] == password) {
          authenticated = true;
        }

        // 2. Try Firebase Auth Sign In if local store didn't match or to sync Firebase user
        if (auth != null) {
          try {
            final userCred = await auth.signInWithEmailAndPassword(email: email, password: password);
            if (userCred.user != null) {
              authenticated = true;
            }
          } catch (_) {}
        }

        if (authenticated) {
          await prefs.setString('active_user_email', email);
          ref.read(activeUserEmailProvider.notifier).state = email;

          if (mounted) {
            context.goNamed('home');
          }
        } else {
          setState(() {
            _error = userStore.containsKey(email)
                ? 'Incorrect password. Please try again.'
                : 'Account not found. Click "Sign up" below to create a new member account.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Authentication failed: ${e.toString().replaceAll("Exception: ", "")}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Google Login - Firebase Web (Untouched)
  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(firebaseAuthProvider);

      if (auth == null) {
        setState(() {
          _error = 'Firebase is not initialized. Check your setup.';
        });
        return;
      }

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');

      await auth.signInWithPopup(googleProvider);

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
    _confirmPasswordCtrl.dispose();
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
                _isSignUpMode ? 'Create Account' : 'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),

              const SizedBox(height: 6),

              Text(
                _isSignUpMode
                    ? 'Register as a new member to start your skin journey'
                    : 'Sign in to continue your skin journey',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),

              const SizedBox(height: 28),

              // Email input
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 14),

              // Password input with Eye Toggle
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                ),
              ),

              // Confirm Password input with Eye Toggle (Sign Up mode only)
              if (_isSignUpMode) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                    ),
                  ),
                ),
              ],

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              if (!_isSignUpMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.pushNamed('forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),

              const SizedBox(height: 16),

              // Email Login / Sign Up Submit Button
              GradientButton(
                label: _isSignUpMode ? 'Create Account' : 'Log in',
                isLoading: _loading,
                onPressed: _loading ? null : _submitEmailAuth,
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or continue with',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithGoogle,
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 26,
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up / Log In Toggle Link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignUpMode ? "Already have an account? " : "Don't have an account? ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isSignUpMode ? 'Log in' : 'Sign up',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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