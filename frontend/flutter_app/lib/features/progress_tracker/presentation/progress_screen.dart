import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medical_report.dart';
import '../../../providers/reports_provider.dart';

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

  void _showReportDetails(BuildContext context, MedicalReport report) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMMM dd, yyyy · hh:mm a').format(report.dateTime);
    final isSerious = report.prediction.toLowerCase().contains('serious');
    final isQuestionnaire = report.reportType == 'questionnaire' || report.prediction == 'Skin Understanding';
    final answers = report.questionnaireAnswers;

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
            // Sheet Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Modal Header Bar
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

            // Modal Body Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Diagnostic Banner Card
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatClassName(report.prediction),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSerious ? AppColors.danger : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Recorded on $formattedDate',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Questionnaire Specific Full Answers View
                  if (isQuestionnaire && answers != null) ...[
                    Text('Detailed Survey Responses', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _QAnswerCard(title: 'Skin Type', value: answers['skin_type'] ?? 'Combination'),
                    _QAnswerCard(
                      title: 'Main Skin Concern(s)',
                      value: answers['main_concern'] is List
                          ? (answers['main_concern'] as List).join(', ')
                          : answers['main_concern'] ?? 'Acne & Pimples',
                    ),
                    _QAnswerCard(title: 'Duration of Concern', value: answers['duration'] ?? 'Not specified'),
                    _QAnswerCard(
                      title: 'Symptoms Experienced',
                      value: answers['symptoms'] is List
                          ? (answers['symptoms'] as List).join(', ')
                          : answers['symptoms'] ?? 'None reported',
                    ),
                    _QAnswerCard(title: 'Severity Level', value: answers['severity'] ?? 'Moderate'),
                    _QAnswerCard(title: 'Skin Condition Progress', value: answers['progress'] ?? 'Stable'),
                    _QAnswerCard(title: 'Face Wash Frequency', value: answers['wash_frequency'] ?? 'Twice a day'),
                    _QAnswerCard(
                      title: 'Current Skincare Products',
                      value: answers['products'] is List
                          ? (answers['products'] as List).join(', ')
                          : answers['products'] ?? 'Standard routine',
                    ),
                    _QAnswerCard(title: 'Previous Occurrence', value: answers['previous_occurrence'] ?? 'No'),
                    _QAnswerCard(
                      title: 'Identified Triggers',
                      value: answers['triggers'] is List
                          ? (answers['triggers'] as List).join(', ')
                          : answers['triggers'] ?? 'None specified',
                    ),
                    if ((answers['additional_notes'] as String?)?.isNotEmpty ?? false)
                      _QAnswerCard(title: 'Additional Notes', value: answers['additional_notes']),
                    if ((answers['help_request'] as String?)?.isNotEmpty ?? false)
                      _QAnswerCard(title: 'Requested Help / Goal', value: answers['help_request']),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Key Observations Card
                    Text('Key Clinical Observations', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.brightness == Brightness.dark ? AppColors.lineDark : AppColors.lineLight),
                      ),
                      child: Column(
                        children: report.keyObservations
                            .map(
                              (obs) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(obs, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Button PDF
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
    final reports = ref.watch(reportsProvider);
    final user = ref.watch(authStateProvider).value;

    final filteredReports = reports.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.id.toLowerCase().contains(q) ||
          r.prediction.toLowerCase().contains(q) ||
          r.riskLevel.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track History & Reports'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
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
            // Search Bar & Stats Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL REPORTS GENERATED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${reports.length} Records',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Medical Reports History List
            Expanded(
              child: filteredReports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.description_outlined, color: AppColors.purple, size: 36),
                            ),
                            const SizedBox(height: 16),
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
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
                                  // Top Row ID & Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                report.id,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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

                                  // Report Name & Match Rate
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatClassName(report.prediction),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSerious ? AppColors.danger : null,
                                        ),
                                      ),
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

                                  // Action Buttons
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QAnswerCard extends StatelessWidget {
  final String title;
  final String value;

  const _QAnswerCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
