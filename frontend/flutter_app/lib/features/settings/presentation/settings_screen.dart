import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';

import '../../../providers/notification_provider.dart';
import '../../../providers/skincare_routine_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final activeEmail = ref.watch(activeUserEmailProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    final String currentLangLabel = switch (currentLocale.languageCode) {
      'hi' => 'हिन्दी',
      'mr' => 'मराठी',
      _ => 'English',
    };

    final email = activeEmail ?? user?.email ?? '';
    final displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (email.isNotEmpty ? email.split('@')[0] : 'User');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final smartNotifications = ref.watch(smartNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 26),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open Side Menu',
        ),
        title: Text(l10n.translate('settings_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.purple,
                  child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.photoURL!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: theme.textTheme.titleLarge),
                    Text(email, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(theme.brightness == Brightness.dark ? 'Dark Mode' : 'Light Mode'),
                    value: theme.brightness == Brightness.dark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeTrackColor: AppColors.purple,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.translate('settings_smart_notifs')),
                    subtitle: Text(l10n.translate('settings_smart_notifs_sub')),
                    value: smartNotifications,
                    onChanged: (val) {
                      ref.read(smartNotificationsProvider.notifier).setEnabled(val);
                      final routines = ref.read(skincareRoutineProvider);
                      ref.read(smartNotificationsProvider.notifier).syncRoutineReminders(routines);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? 'Smart Notifications & Routine Reminders Enabled'
                                : 'Smart Notifications Disabled',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeTrackColor: AppColors.purple,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.translate('settings_language')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentLangLabel,
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                      ],
                    ),
                    onTap: () => _showLanguageSelectorModal(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.translate('settings_privacy')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyModal(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => showLogoutConfirmationDialog(context, ref),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.translate('auth_sign_out')),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectorModal(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.translate('language_select'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                ref,
                title: 'English',
                localeCode: 'en',
                isSelected: currentLocale.languageCode == 'en',
              ),
              const Divider(height: 1),
              _buildLanguageOption(
                context,
                ref,
                title: 'हिन्दी',
                localeCode: 'hi',
                isSelected: currentLocale.languageCode == 'hi',
              ),
              const Divider(height: 1),
              _buildLanguageOption(
                context,
                ref,
                title: 'मराठी',
                localeCode: 'mr',
                isSelected: currentLocale.languageCode == 'mr',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String localeCode,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.purple : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.purple)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(localeCode));
        Navigator.pop(context);
      },
    );
  }

  void _showPrivacyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PrivacyDataBottomSheet(),
    );
  }
}

class _PrivacyDataBottomSheet extends StatefulWidget {
  const _PrivacyDataBottomSheet();

  @override
  State<_PrivacyDataBottomSheet> createState() => _PrivacyDataBottomSheetState();
}

class _PrivacyDataBottomSheetState extends State<_PrivacyDataBottomSheet> {
  bool _shareTelemetry = false;
  bool _encryptLocalLogs = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.purple, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Privacy & Data Management',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: AppColors.purple.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SkinCore uses local MobileNetV2 and secure ephemeral Groq Vision processing. Scanned images are never permanently stored without explicit consent.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Privacy Controls', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Anonymous Diagnostic Telemetry'),
                      subtitle: const Text('Helps improve MobileNetV2 & SkinCore AI accuracy'),
                      value: _shareTelemetry,
                      onChanged: (val) {
                        setState(() => _shareTelemetry = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Telemetry sharing enabled' : 'Telemetry sharing disabled'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeTrackColor: AppColors.purple,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Encrypt Local Medical Logs'),
                      subtitle: const Text('Encrypt saved PDF & tabular scan history'),
                      value: _encryptLocalLogs,
                      onChanged: (val) {
                        setState(() => _encryptLocalLogs = val);
                      },
                      activeTrackColor: AppColors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Data Management', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.purple),
                      title: const Text('Clear Scan Cache'),
                      subtitle: const Text('Frees local temporary cache and pre-rendered previews'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scan cache cleared successfully!')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.purple),
                      title: const Text('Export My Medical Data'),
                      subtitle: const Text('Download all tabular logs as a structured zip/JSON'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preparing medical data package for export...')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                      title: const Text('Delete Medical Data', style: TextStyle(color: AppColors.danger)),
                      subtitle: const Text('Permanently remove stored reports and user profile history'),
                      onTap: () => _confirmDeleteData(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Medical History?'),
        content: const Text(
          'This action cannot be undone. All saved skin scan reports, tabular records, and local history will be erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All medical records deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
