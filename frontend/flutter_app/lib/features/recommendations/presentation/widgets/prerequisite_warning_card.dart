import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PrerequisiteWarningCard extends StatelessWidget {
  final bool missingQuestionnaire;

  const PrerequisiteWarningCard({
    super.key,
    required this.missingQuestionnaire,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = missingQuestionnaire
        ? 'Questionnaire Report Required'
        : 'AI Skin Scan Required';

    final description = missingQuestionnaire
        ? 'To generate accurate, ingredient-focused skincare recommendations, please complete your 12-question Skin Profile first.'
        : 'To tailor AI recommendations to your current skin state, please complete a 30-second AI Skin Scan first.';

    final iconData = missingQuestionnaire
        ? Icons.assignment_outlined
        : Icons.center_focus_strong_rounded;

    final btnLabel = missingQuestionnaire
        ? 'Take Questionnaire'
        : 'Start AI Skin Scan';

    final routeName = missingQuestionnaire ? 'questionnaire' : 'scan';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: AppColors.purple, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pushNamed(routeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  btnLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
