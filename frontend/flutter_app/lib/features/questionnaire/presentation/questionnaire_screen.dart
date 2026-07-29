import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _step = 0;
  final int _totalSteps = 9;
  String? _skinType;
  String? _sunExposure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: const Text('Skin Profile'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_step + 1} / $_totalSteps', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                minHeight: 6,
                backgroundColor: const Color(0xFFF0E8F2),
                valueColor: const AlwaysStoppedAnimation(AppColors.purple),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP ${_step + 1}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text("What's your skin type?", style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('This helps us tune your routine precisely.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 18),
                  _ChipGroup(
                    options: const ['Oily', 'Dry', 'Combination', 'Normal', 'Sensitive'],
                    selected: _skinType,
                    onSelected: (v) => setState(() => _skinType = v),
                  ),
                  const SizedBox(height: 28),
                  Text('Sun exposure', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Hours outdoors daily', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 14),
                  _ChipGroup(
                    options: const ['< 1 hr', '1–3 hrs', '3+ hrs'],
                    selected: _sunExposure,
                    onSelected: (v) => setState(() => _sunExposure = v),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GradientButton(
              label: 'Continue',
              onPressed: () {
                if (_step < _totalSteps - 1) {
                  setState(() => _step++);
                } else {
                  context.pushNamed('recommendations');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ChipGroup({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected ? AppColors.purple.withOpacity(0.1) : Theme.of(context).cardColor,
              border: Border.all(color: isSelected ? AppColors.purple : const Color(0xFFEFE7F0), width: 1.4),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: isSelected ? AppColors.purple : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
