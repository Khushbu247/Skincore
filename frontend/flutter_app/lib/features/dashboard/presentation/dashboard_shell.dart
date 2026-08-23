import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_drawer.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/progress')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    void onTap(int index) {
      switch (index) {
        case 0:
          context.goNamed('home');
        case 1:
          context.goNamed('progress');
        case 2:
          context.goNamed('chat');
        case 3:
          context.goNamed('settings');
      }
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
        child: IconButton(
          icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
          onPressed: () => context.pushNamed('scan'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(icon: Icons.home_rounded, label: 'Home', selected: currentIndex == 0, onTap: () => onTap(0)),
              _NavIcon(
                  icon: Icons.show_chart_rounded,
                  label: 'Progress',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1)),
              const SizedBox(width: 48), // space for notch/FAB
              _NavIcon(
                  icon: Icons.chat_bubble_rounded, label: 'Chat', selected: currentIndex == 2, onTap: () => onTap(2)),
              _NavIcon(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.purple : AppColors.mutedLight;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
