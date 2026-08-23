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

    final displayName = user?.displayName ?? 'Riya';
    final email = user?.email ?? 'riya@skincore.ai';
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'R');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 26),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open Side Menu',
        ),
        title: const Text('Settings & Profile'),
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
                    title: const Text('Dark mode'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeTrackColor: AppColors.purple,
                  ),
                  const Divider(height: 1),
                  const SwitchListTile(
                    title: Text('Notifications'),
                    value: true,
                    onChanged: null,
                    activeTrackColor: AppColors.purple,
                  ),
                  const Divider(height: 1),
                  ListTile(title: const Text('Language'), trailing: const Text('English'), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(title: const Text('Privacy & data'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final auth = ref.read(firebaseAuthProvider);
                if (auth != null) {
                  await auth.signOut();
                }
                if (context.mounted) {
                  context.goNamed('login');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
