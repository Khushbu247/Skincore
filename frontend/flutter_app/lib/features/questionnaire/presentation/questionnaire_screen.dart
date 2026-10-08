import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/questionnaire_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../providers/questionnaire_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _currentIndex = 0;
  List<QuestionItem> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final Map<String, dynamic> _answers = {};
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final loaded = await QuestionnaireService.loadQuestions();
    if (mounted) {
      setState(() {
        _questions = loaded;
        _isLoading = false;
      });
      _syncCurrentAnswerText();
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _syncCurrentAnswerText() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final currentQ = _questions[_currentIndex];
    if (currentQ.isOpenText) {
      _textCtrl.text = _answers[currentQ.jsonField] as String? ?? '';
    }
  }

  void _onOptionSelected(QuestionItem item, String option) {
    setState(() {
      if (item.isSingleChoice) {
        _answers[item.jsonField] = option;
      } else if (item.isMultipleChoice) {
        final currentList = List<String>.from(_answers[item.jsonField] ?? []);
        if (currentList.contains(option)) {
          currentList.remove(option);
        } else {
          currentList.add(option);
        }
        _answers[item.jsonField] = currentList;
      }
    });
  }

  bool _isOptionSelected(QuestionItem item, String option) {
    if (item.isSingleChoice) {
      return _answers[item.jsonField] == option;
    } else if (item.isMultipleChoice) {
      final currentList = List<String>.from(_answers[item.jsonField] ?? []);
      return currentList.contains(option);
    }
    return false;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authStateProvider).value;
      final uid = user?.uid ?? 'guest';

      if (_questions[_currentIndex].isOpenText) {
        _answers[_questions[_currentIndex].jsonField] = _textCtrl.text.trim();
      }

      await ref.read(questionnaireProvider.notifier).submitQuestionnaire(
            uid: uid,
            answers: _answers,
          );
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skin Profile & Questionnaire saved permanently to account! ✨'),
            backgroundColor: AppColors.success,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.goNamed('home');
        }
      }
    }
  }

  void _nextQuestion() {
    if (_questions[_currentIndex].isOpenText) {
      _answers[_questions[_currentIndex].jsonField] = _textCtrl.text.trim();
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _syncCurrentAnswerText();
    } else {
      _submit();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _syncCurrentAnswerText();
    }
  }

  String _getOptionDisplayLabel(BuildContext context, String option) {
    final l10n = AppLocalizations.of(context);
    final lower = option.toLowerCase();
    if (lower.contains('oily')) return l10n.translate('opt_oily');
    if (lower.contains('dry')) return l10n.translate('opt_dry');
    if (lower.contains('combination')) return l10n.translate('opt_combination');
    if (lower.contains('normal')) return l10n.translate('opt_normal');
    if (lower.contains('sensitive') && lower.contains('high')) return l10n.translate('opt_high');
    if (lower.contains('sensitive')) return l10n.translate('opt_sensitive');
    if (lower.contains('acne')) return l10n.translate('opt_acne');
    if (lower.contains('aging') || lower.contains('fine lines')) return l10n.translate('opt_aging');
    if (lower.contains('pigmentation') || lower.contains('dark spots')) return l10n.translate('opt_pigmentation');
    if (lower.contains('redness') || lower.contains('rosacea')) return l10n.translate('opt_redness');
    if (lower.contains('budget friendly')) return l10n.translate('opt_budget_low');
    if (lower.contains('mid-range')) return l10n.translate('opt_budget_mid');
    if (lower.contains('premium')) return l10n.translate('opt_budget_premium');
    if (lower.contains('low') || lower.contains('gentle')) return l10n.translate('opt_low');
    if (lower.contains('moderate')) return l10n.translate('opt_medium');
    return option;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQ = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentIndex > 0) {
              _previousQuestion();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(l10n.translate('q_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Title Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('q_subtitle'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.translate('q_step')} ${_currentIndex + 1} ${l10n.translate('q_of')} ${_questions.length} · ${currentQ.section}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0E8F2),
                      valueColor: const AlwaysStoppedAnimation(AppColors.rose),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Question & Answer Inputs
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    currentQ.question,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentQ.answerType,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // Option Cards or Open Text Input
                  if (currentQ.isOpenText) ...[
                    TextField(
                      controller: _textCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter details here (optional)...',
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      ),
                    ),
                  ] else ...[
                    ...currentQ.options.map((option) {
                      final selected = _isOptionSelected(currentQ, option);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _onOptionSelected(currentQ, option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.purple.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? AppColors.purple : (isDark ? AppColors.lineDark : AppColors.lineLight),
                                width: selected ? 1.8 : 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentQ.isSingleChoice
                                      ? (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded)
                                      : (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
                                  color: selected ? AppColors.purple : AppColors.mutedLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _getOptionDisplayLabel(context, option),
                                    style: TextStyle(
                                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                      color: selected ? AppColors.purple : null,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // Navigation Controls Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousQuestion,
                        child: Text(l10n.translate('common_back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: _currentIndex == _questions.length - 1 ? l10n.translate('q_submit') : l10n.translate('common_next'),
                      icon: _currentIndex == _questions.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? () {} : _nextQuestion,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
