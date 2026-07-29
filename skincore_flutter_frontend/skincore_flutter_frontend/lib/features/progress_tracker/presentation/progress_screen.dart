import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scores = [58.0, 64.0, 61.0, 70.0, 67.0, 76.0];

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('30-DAY IMPROVEMENT', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('+18%', style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(scores.length, (i) {
                          final isHighlighted = i == 3 || i == 5;
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: scores[i],
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              gradient: isHighlighted ? AppColors.brandGradient : null,
                              color: isHighlighted ? null : const Color(0xFFEFE1F0),
                            ),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Before / After', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(height: 110, decoration: BoxDecoration(color: const Color(0xFFF3E4EE), borderRadius: BorderRadius.circular(14))),
                    const SizedBox(height: 6),
                    Text('June 28 · Score 58', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(height: 110, decoration: BoxDecoration(color: const Color(0xFFE4F0E8), borderRadius: BorderRadius.circular(14))),
                    const SizedBox(height: 6),
                    Text('July 28 · Score 76', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _TimelineItem(title: 'Scan · Mild acne detected', subtitle: 'Jul 28 · Score 76', highlighted: true, isLast: false),
          const _TimelineItem(title: 'Routine updated', subtitle: 'Jul 15 · Added niacinamide', highlighted: false, isLast: false),
          const _TimelineItem(title: 'Scan · Baseline', subtitle: 'Jun 28 · Score 58', highlighted: false, isLast: true),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool highlighted;
  final bool isLast;

  const _TimelineItem({required this.title, required this.subtitle, required this.highlighted, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: highlighted ? AppColors.brandGradient : null,
                  color: highlighted ? null : const Color(0xFFEFE7F0),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFEFE7F0))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
