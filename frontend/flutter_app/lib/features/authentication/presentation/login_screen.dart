import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/app_localizations.dart';
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

      if (auth == null) {
        setState(() {
          _error = 'Firebase Authentication service is unavailable. Please check your setup.';
        });
        return;
      }

      if (_isSignUpMode) {
        // --- NEW USER SIGN UP VIA FIREBASE AUTH ---
        try {
          final userCred = await auth.createUserWithEmailAndPassword(email: email, password: password);
          if (userCred.user != null) {
            await prefs.setString('active_user_email', email);
            ref.read(activeUserEmailProvider.notifier).state = email;
            await prefs.remove('user_credentials_store');

            if (mounted) {
              context.goNamed('home');
            }
          }
        } on FirebaseAuthException catch (fe) {
          setState(() {
            _error = switch (fe.code) {
              'email-already-in-use' => 'An account with this email already exists. Please log in.',
              'invalid-email' => 'The email address format is invalid.',
              'weak-password' => 'Password is too weak. Please use at least 6 characters.',
              _ => 'Signup failed: ${fe.message ?? fe.code}',
            };
          });
        }
      } else {
        // --- EXISTING USER LOG IN VIA FIREBASE AUTH ---
        try {
          final userCred = await auth.signInWithEmailAndPassword(email: email, password: password);
          if (userCred.user != null) {
            await prefs.setString('active_user_email', email);
            ref.read(activeUserEmailProvider.notifier).state = email;
            await prefs.remove('user_credentials_store');

            if (mounted) {
              context.goNamed('home');
            }
          }
        } on FirebaseAuthException catch (fe) {
          setState(() {
            _error = switch (fe.code) {
              'user-not-found' || 'invalid-credential' => 'Account not found or invalid credentials. Click "Sign up" below to create an account.',
              'wrong-password' => 'Incorrect password. Please try again.',
              'invalid-email' => 'The email address format is invalid.',
              'user-disabled' => 'This account has been disabled. Please contact support.',
              _ => 'Authentication failed: ${fe.message ?? fe.code}',
            };
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Authentication error: ${e.toString().replaceAll("Exception: ", "")}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Google Login - Multiplatform (Web + Android APK)
  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(firebaseAuthProvider);
      final prefs = ref.read(sharedPreferencesProvider);

      if (auth == null) {
        setState(() {
          _error = 'Firebase is not initialized. Please check your setup.';
        });
        return;
      }

      UserCredential userCred;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');

        userCred = await auth.signInWithPopup(googleProvider);
      } else {
        // --- NATIVE ANDROID GOOGLE SIGN-IN ---
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: '971335277078-0qlflr2hd3tu3cn5067lr07eoelo2qmu.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User canceled the sign-in modal
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCred = await auth.signInWithCredential(credential);
      }

      final authenticatedUser = userCred.user;
      if (authenticatedUser != null &&
          authenticatedUser.email != null &&
          authenticatedUser.email!.isNotEmpty) {
        await prefs.setString('active_user_email', authenticatedUser.email!);
        ref.read(activeUserEmailProvider.notifier).state = authenticatedUser.email;

        if (mounted) {
          context.goNamed('home');
        }
      } else {
        setState(() {
          _error = 'Could not verify Firebase Google account. Please try again.';
        });
      }
    } on PlatformException catch (pe) {
      debugPrint('Google Sign-In PlatformException: ${pe.code} - ${pe.message}');
      setState(() {
        if (pe.code == 'sign_in_failed' || pe.message?.contains('10') == true) {
          _error =
              'Google Sign-In configuration error (ApiException 10). Please verify SHA-1 fingerprint in Firebase Console.';
        } else {
          _error = 'Google Sign-In error: ${pe.message ?? pe.code}';
        }
      });
    } on FirebaseAuthException catch (fe) {
      debugPrint('FirebaseAuthException during Google Sign-In: ${fe.code} - ${fe.message}');
      setState(() {
        _error = fe.message ?? 'Firebase Google Sign-In failed (${fe.code}).';
      });
    } catch (e) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      setState(() {
        _error = 'Google Sign-In Error: ${e.toString().replaceAll("Exception: ", "")}';
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
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Top Bar with Logo & Language Dropdown Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentLocale.languageCode,
                        icon: const Icon(Icons.language_rounded, size: 20),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: 'hi',
                            child: Text('हिन्दी', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: 'mr',
                            child: Text('मराठी', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(localeProvider.notifier).setLocale(Locale(val));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                _isSignUpMode ? l10n.translate('auth_create_account') : l10n.translate('auth_welcome_back'),
                style: theme.textTheme.headlineMedium,
              ),

              const SizedBox(height: 6),

              Text(
                _isSignUpMode
                    ? l10n.translate('auth_signup_subtitle')
                    : l10n.translate('auth_login_subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),

              const SizedBox(height: 28),

              // Email input
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: l10n.translate('auth_email_hint'),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 14),

              // Password input with Eye Toggle
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: l10n.translate('auth_password_hint'),
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
                    tooltip: _obscurePassword ? l10n.translate('auth_show_password') : l10n.translate('auth_hide_password'),
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
                    hintText: l10n.translate('auth_confirm_password_hint'),
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
                      tooltip: _obscureConfirmPassword ? l10n.translate('auth_show_password') : l10n.translate('auth_hide_password'),
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
                    child: Text(l10n.translate('auth_forgot_password')),
                  ),
                ),

              const SizedBox(height: 16),

              // Email Login / Sign Up Submit Button
              GradientButton(
                label: _isSignUpMode ? l10n.translate('auth_create_account') : l10n.translate('auth_login_button'),
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
                      l10n.translate('auth_or_continue_with'),
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
                  label: Text(l10n.translate('auth_google_continue')),
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
                      _isSignUpMode ? l10n.translate('auth_already_have_account') : l10n.translate('auth_dont_have_account'),
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
                        _isSignUpMode ? l10n.translate('auth_log_in_link') : l10n.translate('auth_sign_up_link'),
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