import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';

Future<void> showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.translate('auth_sign_out'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to sign out of your SkinCore account?',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('active_user_email');
    ref.read(activeUserEmailProvider.notifier).state = null;

    final auth = ref.read(firebaseAuthProvider);
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (_) {}
    }

    if (context.mounted) {
      context.goNamed('login');
    }
  }
}
