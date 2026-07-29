import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.purple,
                  child: Text(
                    (user?.email ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'Your Profile', style: theme.textTheme.titleLarge),
                    Text(user?.email ?? '', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark mode'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeColor: AppColors.purple,
                  ),
                  const Divider(height: 1),
                  const SwitchListTile(title: Text('Notifications'), value: true, onChanged: null, activeColor: AppColors.purple),
                  const Divider(height: 1),
                  ListTile(title: const Text('Language'), trailing: const Text('English'), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(title: const Text('Privacy & data'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(title: const Text('Terms of service'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                title: const Text('Delete account', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                await ref.read(firebaseAuthProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
