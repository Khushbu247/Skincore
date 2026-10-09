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

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
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
                                isQuestionnaire ? '100% Complete' : '${report.confidence.toStringAsFixed(1)}% Confidence',
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
                  const SizedBox(height: 20),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$todayCompletedCount of $totalRoutinesCount Routines Completed Today',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Today\'s Routine Checklist',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Saved Medical Reports & Records',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
