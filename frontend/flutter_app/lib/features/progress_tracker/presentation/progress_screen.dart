import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medical_report.dart';
import '../../../models/skincare_routine.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/skincare_routine_provider.dart';
import '../../../providers/questionnaire_provider.dart';
import 'widgets/progress_analytics_tab.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.purple),
            SizedBox(width: 10),
            Text('Clean Up Routine History'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will delete routine completion records older than 30 days to optimize storage.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF3E8FF),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your routine definitions, saved medical reports, questionnaire responses, and profile details will NOT be deleted.',
                      style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final deleted = await ref.read(routineCompletionLogsProvider.notifier).cleanup30DaysHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleaned up $deleted completion records older than 30 days. Routines & reports remain intact.'),
                  ),
                );
              }
            },
            child: const Text('Clean Up Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(BuildContext context, MedicalReport report) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat('MMMM dd, yyyy · hh:mm a').format(report.dateTime);
    final isSerious = report.prediction.toLowerCase().contains('serious');
    final isQuestionnaire = report.reportType == 'questionnaire' || report.prediction == 'Skin Understanding';

    String formatClassName(String raw) {
      switch (raw.toLowerCase()) {
        case 'acne':
          return 'Acne Vulgaris';
        case 'eczema_rash':
        case 'eczema/rash':
          return 'Eczema / Rash';
        case 'pigmentation':
          return 'Hyperpigmentation';
        case 'serious_condition':
          return 'Serious Condition Alert';
        case 'skin understanding':
          return 'Skin Understanding Profile';
        default:
          return raw.replaceAll('_', ' ').toUpperCase();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQuestionnaire ? 'PATIENT QUESTIONNAIRE REPORT' : 'MEDICAL ANALYSIS REPORT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.id,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: (isSerious ? AppColors.danger : AppColors.purple).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isSerious ? AppColors.danger : AppColors.purple).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isQuestionnaire ? 'SKIN PROFILE RECORD' : 'AI DIAGNOSIS FINDING',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSerious ? AppColors.danger : AppColors.rose,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSerious ? AppColors.danger : AppColors.purple,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                isQuestionnaire ? '100% Complete' : '${report.confidence.toStringAsFixed(1)}% Match',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatClassName(report.prediction),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSerious ? AppColors.danger : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recorded on $formattedDate',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isQuestionnaire) ...[
                    _QuestionnaireResponseTable(
                      answers: report.questionnaireAnswers ?? ref.read(questionnaireProvider).answers ?? {},
                      isDark: isDark,
                    ),
                  ] else ...[
                    // 1. SKIN PROFILE & RISK ASSESSMENT CARD
                    if (report.skinType != null || report.assessmentState != null || report.riskLevel.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SKIN PROFILE & RISK ASSESSMENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (report.skinType != null && report.skinType!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Skin Type: ${report.skinType!.toUpperCase()}',
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (report.assessmentState != null && report.assessmentState!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.psychology_outlined, size: 14, color: AppColors.purple),
                                          const SizedBox(width: 6),
                                          Text(
                                            'State: ${report.assessmentState}',
                                            style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isSerious ? AppColors.danger : AppColors.rose).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shield_outlined, size: 14, color: isSerious ? AppColors.danger : AppColors.rose),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Risk: ${report.riskLevel}',
                                          style: TextStyle(
                                            color: isSerious ? AppColors.danger : AppColors.rose,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 2. AI ANALYSIS & INSIGHTS CARD
                    if (report.keyObservations.isNotEmpty || (report.visualDescription != null && report.visualDescription!.isNotEmpty) || report.safetyMessage != null) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI ANALYSIS & INSIGHTS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              if (report.safetyMessage != null && report.safetyMessage!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          report.safetyMessage!,
                                          style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (report.visualDescription != null && report.visualDescription!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  report.visualDescription!,
                                  style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                                ),
                              ],
                              if (report.keyObservations.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ...report.keyObservations.map(
                                  (obs) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Expanded(
                                          child: Text(obs, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 3. FACIAL REGION OBSERVATIONS CARD (only when available)
                    if (report.regionObservations != null && report.regionObservations!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.face_retouching_natural_rounded, color: AppColors.purple, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FACIAL REGION OBSERVATIONS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...report.regionObservations!.map((reg) {
                                final regionName = (reg['region'] ?? 'General').toUpperCase();
                                final obsText = reg['observation'] ?? '';
                                final severity = (reg['severity'] ?? 'moderate').toLowerCase();

                                Color sevColor;
                                if (severity.contains('severe') || severity.contains('high')) {
                                  sevColor = AppColors.danger;
                                } else if (severity.contains('mild')) {
                                  sevColor = const Color(0xFF10B981);
                                } else {
                                  sevColor = const Color(0xFFF59E0B);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          regionName,
                                          style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(obsText, style: const TextStyle(fontSize: 12, height: 1.3)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sevColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          severity.toUpperCase(),
                                          style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 4. RECOMMENDED CARE GUIDELINES CARD
                    if (report.recommendedCare.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RECOMMENDED CARE GUIDELINES',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...report.recommendedCare.map(
                                (care) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(care, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 5. ADDITIONAL FINDINGS CARD (if present)
                    if (report.additionalFindings != null && report.additionalFindings!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADDITIONAL OBSERVATIONS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...report.additionalFindings!.map(
                                (finding) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold)),
                                      Expanded(child: Text(finding, style: const TextStyle(fontSize: 12, height: 1.3))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 6. REPORT METADATA & INFORMATION CARD
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REPORT INFORMATION',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _MetaInfoItem(label: 'Report ID', value: report.id),
                                _MetaInfoItem(label: 'Model Version', value: report.modelVersion),
                                _MetaInfoItem(label: 'Image Dimensions', value: report.imageSize),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 7. DOWNLOAD OFFICIAL PDF REPORT BUTTON
                  ElevatedButton.icon(
                    onPressed: () {
                      final user = ref.read(authStateProvider).value;
                      final userName = user?.displayName ?? 'Patient';
                      PdfReportService.generateAndDownloadPdf(report, userName: userName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Download Official PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(reportsProvider);
    final userRoutines = ref.watch(skincareRoutineProvider);
    final logsNotifier = ref.watch(routineCompletionLogsProvider.notifier);
    final user = ref.watch(authStateProvider).value;

    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    final todayCompletedCount = logsNotifier.getTodayCompletedCount(userRoutines);
    final totalRoutinesCount = userRoutines.length;
    final adherenceRatio = totalRoutinesCount > 0 ? todayCompletedCount / totalRoutinesCount : 0.0;

    final filteredReports = reports.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.id.toLowerCase().contains(q) ||
          r.prediction.toLowerCase().contains(q) ||
          r.riskLevel.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('tracker_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            onPressed: () => _showCleanupDialog(context),
            tooltip: 'Clean up 30-day history',
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () => context.pushNamed('scan'),
            tooltip: 'New Skin Scan',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: l10n.translate('tab_routine_progress')),
                    Tab(text: l10n.translate('tab_analytics_insights')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: ROUTINE PROGRESS (DEFAULT GROUP 2 VIEW)
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      // ==========================================
                      // SECTION 1: ROUTINE ADHERENCE DASHBOARD
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'TODAY\'S ADHERENCE DASHBOARD',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      todayStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${(adherenceRatio * 100).toInt()}% Done',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: adherenceRatio,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '$todayCompletedCount of $totalRoutinesCount Routines Completed Today',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                GestureDetector(
                                  onTap: () => context.pushNamed('recommendations'),
                                  child: const Text(
                                    'Manage Routines',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Today's Interactive Checklist Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 8,
                                children: [
                                  const Text(
                                    'Today\'s Routine Checklist',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _showCleanupDialog(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.auto_delete_outlined, size: 14),
                                    label: const Text('30-Day Cleanup', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (userRoutines.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'No skincare routines added yet. Go to Routines to set up your morning/evening steps.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    for (int i = 0; i < userRoutines.length; i++) ...[
                                      if (i > 0) const Divider(height: 1),
                                      _DashboardRoutineChecklistRow(
                                        item: userRoutines[i],
                                        onToggle: () {
                                          ref
                                              .read(routineCompletionLogsProvider.notifier)
                                              .toggleCompletion(userRoutines[i].id);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==========================================
                      // SECTION 2: DEDICATED MEDICAL REPORTS & HISTORY
                      // ==========================================
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          const Text(
                            'Saved Medical Reports & Records',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${reports.length} Reports',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search report ID or skin condition...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (filteredReports.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.description_outlined, color: AppColors.purple, size: 30),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _searchQuery.isEmpty ? 'No medical reports saved yet' : 'No matching reports found',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Complete your skin scan or profile survey to generate downloadable PDF medical reports.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: filteredReports.map((report) {
                            final formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(report.dateTime);
                            final isSerious = report.prediction.toLowerCase().contains('serious');
                            final isQuestionnaire = report.reportType == 'questionnaire' || report.prediction == 'Skin Understanding';

                            String formatClassName(String raw) {
                              switch (raw.toLowerCase()) {
                                case 'acne':
                                  return 'Acne Vulgaris';
                                case 'eczema_rash':
                                case 'eczema/rash':
                                  return 'Eczema / Rash';
                                case 'pigmentation':
                                  return 'Hyperpigmentation';
                                case 'serious_condition':
                                  return 'Serious Condition Alert';
                                case 'skin understanding':
                                  return 'Skin Understanding Profile';
                                default:
                                  return raw.replaceAll('_', ' ').toUpperCase();
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: (isSerious ? AppColors.danger : AppColors.purple).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    isQuestionnaire ? Icons.assignment_turned_in_rounded : Icons.description_outlined,
                                                    color: isSerious ? AppColors.danger : AppColors.purple,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        report.id,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        formattedDate,
                                                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isSerious ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              report.riskLevel,
                                              style: TextStyle(
                                                color: isSerious ? AppColors.danger : AppColors.success,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              formatClassName(report.prediction),
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSerious ? AppColors.danger : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isQuestionnaire ? '100% Complete' : '${report.confidence.toStringAsFixed(1)}% match',
                                            style: TextStyle(
                                              color: isSerious ? AppColors.danger : AppColors.purple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _showReportDetails(context, report),
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                              label: const Text('View Report'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                final userName = user?.displayName ?? 'Patient';
                                                PdfReportService.generateAndDownloadPdf(report, userName: userName);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.purple,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              icon: const Icon(Icons.download_rounded, size: 16),
                                              label: const Text('Download PDF'),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.muted),
                                            onPressed: () {
                                              ref.read(reportsProvider.notifier).deleteReport(report.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Report deleted')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),

                  // TAB 2: ANALYTICS & INSIGHTS (NEW FEATURE)
                  const ProgressAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRoutineChecklistRow extends ConsumerWidget {
  final SkincareRoutineItem item;
  final VoidCallback onToggle;

  const _DashboardRoutineChecklistRow({
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(routineCompletionLogsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCompletedToday = logs.any((l) => l.routineId == item.id && l.dateString == todayStr);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompletedToday ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isCompletedToday ? AppColors.success : AppColors.mutedLight,
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: isCompletedToday
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                    color: isCompletedToday ? AppColors.muted : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.routineType} Routine · ${item.time}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
      ],
    );
  }
}

const List<Map<String, String>> _questionnaire12Questions = [
  {
    'id': '1',
    'field': 'skin_type',
    'question': 'How would you describe your skin type?',
  },
  {
    'id': '2',
    'field': 'main_concern',
    'question': 'What is your main skin concern?',
  },
  {
    'id': '3',
    'field': 'duration',
    'question': 'How long have you been experiencing this concern?',
  },
  {
    'id': '4',
    'field': 'symptoms',
    'question': 'What symptoms are you currently experiencing?',
  },
  {
    'id': '5',
    'field': 'severity',
    'question': 'How severe would you describe the concern?',
  },
  {
    'id': '6',
    'field': 'progress',
    'question': 'Is the affected area getting better, worse, or staying the same?',
  },
  {
    'id': '7',
    'field': 'wash_frequency',
    'question': 'How often do you usually wash your face?',
  },
  {
    'id': '8',
    'field': 'products',
    'question': 'What skincare products do you currently use?',
  },
  {
    'id': '9',
    'field': 'previous_occurrence',
    'question': 'Have you experienced a similar skin problem before?',
  },
  {
    'id': '10',
    'field': 'triggers',
    'question': 'Have you noticed anything that makes your skin concern better or worse?',
  },
  {
    'id': '11',
    'field': 'additional_notes',
    'question': 'Tell us anything else you\'d like SkinCore to know about your skin.',
  },
  {
    'id': '12',
    'field': 'help_request',
    'question': 'Is there anything specific you would like help with?',
  },
];

class _QuestionnaireResponseTable extends StatelessWidget {
  final Map<String, dynamic> answers;
  final bool isDark;

  const _QuestionnaireResponseTable({
    required this.answers,
    required this.isDark,
  });

  String _formatAnswer(dynamic value) {
    if (value == null) return 'Not answered';
    if (value is List) {
      final nonNull = value.where((e) => e != null && e.toString().trim().isNotEmpty).toList();
      return nonNull.isEmpty ? 'Not answered' : nonNull.join(', ');
    }
    final str = value.toString().trim();
    return str.isEmpty ? 'Not answered' : str;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.purple, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUESTIONNAIRE SURVEY RESPONSES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '12 Recorded Patient Profile Parameters',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._questionnaire12Questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final qData = entry.value;
              final field = qData['field']!;
              final question = qData['question']!;
              final rawAns = answers[field];
              final ansStr = _formatAnswer(rawAns);
              final isUnanswered = ansStr == 'Not answered';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.lineLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Q${idx + 1}',
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUnanswered
                            ? (isDark ? Colors.white10 : Colors.grey.shade100)
                            : AppColors.purple.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ansStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isUnanswered ? FontWeight.normal : FontWeight.bold,
                          color: isUnanswered
                              ? AppColors.muted
                              : (isDark ? Colors.white : AppColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


