import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  int _tab = 0;
  final _tabs = const ['Morning', 'Night', 'Weekly'];

  final _routineSteps = const {
    'Morning': [
      _Step('Salicylic acid cleanser', 'Step 1 · Unclogs pores', Icons.water_drop_rounded),
      _Step('Niacinamide 5% serum', 'Step 2 · Oil control', Icons.opacity_rounded),
      _Step('SPF 50+ sunscreen', 'Step 3 · Non-negotiable', Icons.wb_sunny_rounded),
    ],
    'Night': [
      _Step('Gentle cleanser', 'Step 1 · Removes buildup', Icons.water_drop_rounded),
      _Step('Benzoyl peroxide spot treatment', 'Step 2 · Targeted care', Icons.healing_rounded),
      _Step('Ceramide moisturizer', 'Step 3 · Barrier repair', Icons.spa_rounded),
    ],
    'Weekly': [
      _Step('Gentle exfoliant', '1-2x/week only', Icons.auto_awesome_rounded),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _routineSteps[_tabs[_tab]]!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: const Text('Your Routine'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == _tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.brandGradient : null,
                      color: selected ? null : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(100),
                      border: selected ? null : Border.all(color: const Color(0xFFEFE7F0)),
                    ),
                    child: Text(_tabs[i],
                        style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(11)),
                          child: Icon(s.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              Text(s.subtitle, style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Text('Ingredients to avoid', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Tag(label: 'Heavy oils'),
              _Tag(label: 'Alcohol denat.'),
              _Tag(label: 'Fragrance (high %)'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Lifestyle', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '💧  2.5L water daily\n😴  7+ hrs sleep\n🥗  Lower dairy & sugar\n🧘  5 min stress check-in',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFFCEBEC), borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: const TextStyle(color: Color(0xFFC13B4A), fontWeight: FontWeight.w600, fontSize: 11.5)),
    );
  }
}
