import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                    Text('Riya ✨', style: theme.textTheme.titleLarge),
                  ],
                ),
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.purple,
                  child: const Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const _SkinScoreRing(score: 76),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TODAY\'S SKIN SCORE',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Up 4 pts this week — hydration is paying off.',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.pushNamed('scan'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(22)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Skin Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Get an instant AI read in 30s', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your routine · Today', style: theme.textTheme.titleMedium),
                GestureDetector(
                  onTap: () => context.goNamed('progress'),
                  child: Text('See all', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.purple, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: const [
                    _RoutineRow(title: 'Gentle cleanser', subtitle: 'Morning · 2 min', time: '7:30 AM', done: true),
                    Divider(height: 1),
                    _RoutineRow(title: 'SPF 50 sunscreen', subtitle: 'Morning · Reapply 2pm', time: '7:35 AM', done: true),
                    Divider(height: 1),
                    _RoutineRow(title: 'Niacinamide serum', subtitle: 'Night · 5 min', time: '9:00 PM', done: false),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Text('Myth of the day', style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF2B1533), Color(0xFF7A3B93)]),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"Oily skin doesn\'t need moisturizer."',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 8),
                  Text(
                    'False — skipping it can trigger more oil production. Lightweight, non-comedogenic formulas help balance skin.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinScoreRing extends StatelessWidget {
  final int score;
  const _SkinScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 9,
              backgroundColor: const Color(0xFFF0E8F2),
              valueColor: const AlwaysStoppedAnimation(AppColors.rose),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text('SCORE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool done;

  const _RoutineRow({required this.title, required this.subtitle, required this.time, required this.done});

  @override
  State<_RoutineRow> createState() => _RoutineRowState();
}

class _RoutineRowState extends State<_RoutineRow> {
  late bool done = widget.done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => done = !done),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(color: done ? AppColors.success : AppColors.mutedLight, width: 1.6),
                borderRadius: BorderRadius.circular(7),
              ),
              child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(widget.subtitle, style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ],
            ),
          ),
          Text(widget.time, style: TextStyle(color: AppColors.mutedLight, fontSize: 11)),
        ],
      ),
    );
  }
}
