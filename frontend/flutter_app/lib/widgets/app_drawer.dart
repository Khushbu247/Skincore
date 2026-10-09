import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/providers.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/logout_confirmation_dialog.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final activeEmail = ref.watch(activeUserEmailProvider);
    final user = ref.watch(authStateProvider).value;
    final email = activeEmail ?? user?.email ?? '';
    final displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (email.isNotEmpty ? email.split('@')[0] : 'User');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && theme.brightness == Brightness.dark);

    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Pro Member',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: l10n.translate('nav_home'),
                    selected: currentLocation == '/home',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('home');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    label: l10n.translate('tracker_title'),
                    badge: 'NEW',
                    selected: currentLocation == '/progress',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('progress');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.center_focus_strong_rounded,
                    label: l10n.translate('home_start_scan_button'),
                    selected: currentLocation == '/scan',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed('scan');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_rounded,
                    label: l10n.translate('chat_title'),
                    selected: currentLocation == '/chat',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('chat');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.spa_rounded,
                    label: l10n.translate('home_routine_title'),
                    selected: currentLocation == '/recommendations',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed('recommendations');
                    },
                  ),
                  const Divider(height: 24, indent: 8, endIndent: 8),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: l10n.translate('nav_settings'),
                    selected: currentLocation == '/settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('settings');
                    },
                  ),
                  _DrawerItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    label: isDark ? 'Light Theme' : 'Dark Theme',
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            // Logout Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => showLogoutConfirmationDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                  foregroundColor: AppColors.danger,
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.translate('auth_sign_out')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.badge,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.purple : (theme.brightness == Brightness.dark ? Colors.white70 : AppColors.ink);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.purple.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }
}
