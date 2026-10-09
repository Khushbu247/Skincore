import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/medical_report.dart';
import '../../../../models/skincare_routine.dart';
import '../../../../providers/questionnaire_provider.dart';
import '../../../../providers/reports_provider.dart';
import '../../../../providers/skincare_routine_provider.dart';

class ProgressAnalyticsTab extends ConsumerWidget {
  const ProgressAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final reports = ref.watch(reportsProvider);
    final userRoutines = ref.watch(skincareRoutineProvider);
    final logs = ref.watch(routineCompletionLogsProvider);
    final logsNotifier = ref.watch(routineCompletionLogsProvider.notifier);
    final questionnaireState = ref.watch(questionnaireProvider);

    final activeRoutineIds = userRoutines.map((r) => r.id).toSet();
    final todayCompletedCount = logsNotifier.getTodayCompletedCount(userRoutines);
    final totalRoutinesCount = userRoutines.length;

    // ==========================================
    // ADHERENCE & STREAK CALCULATIONS
    // ==========================================
    final now = DateTime.now();

    // 7-Day Adherence Rate
    int completed7Days = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      completed7Days += logs.where((l) => l.dateString == dStr && activeRoutineIds.contains(l.routineId)).length;
    }
    final possible7Days = totalRoutinesCount * 7;
    final weeklyAdherencePct = possible7Days > 0 ? (completed7Days / possible7Days * 100) : 0.0;

    // 30-Day Adherence Rate
    int completed30Days = 0;
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      completed30Days += logs.where((l) => l.dateString == dStr && activeRoutineIds.contains(l.routineId)).length;
    }
    final possible30Days = totalRoutinesCount * 30;
    final monthlyAdherencePct = possible30Days > 0 ? (completed30Days / possible30Days * 100) : 0.0;

    // Current & Best Streak
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final hasCompletedToday = logs.any((l) => l.dateString == todayStr && activeRoutineIds.contains(l.routineId));
    final startDate = hasCompletedToday ? now : now.subtract(const Duration(days: 1));

    int currentStreak = 0;
    for (int i = 0;; i++) {
      final d = startDate.subtract(Duration(days: i));
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      if (logs.any((l) => l.dateString == dStr && activeRoutineIds.contains(l.routineId))) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Best streak
    final uniqueLogDates = logs
        .where((l) => activeRoutineIds.contains(l.routineId))
        .map((l) => l.dateString)
        .toSet()
        .toList()
      ..sort();

    int maxStreak = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (final dStr in uniqueLogDates) {
      final date = DateTime.tryParse(dStr);
      if (date != null) {
        if (prevDate == null || date.difference(prevDate).inDays == 1) {
          tempStreak++;
        } else if (date.difference(prevDate).inDays > 1) {
          tempStreak = 1;
        }
        if (tempStreak > maxStreak) maxStreak = tempStreak;
        prevDate = date;
      }
    }

    // ==========================================
    // MEDICAL REPORTS CALCULATIONS
    // ==========================================
    final thisMonthCount = reports.where((r) => r.dateTime.year == now.year && r.dateTime.month == now.month).length;
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthCount = reports.where((r) => r.dateTime.year == lastMonthDate.year && r.dateTime.month == lastMonthDate.month).length;
    final latestReportDate = reports.isNotEmpty ? DateFormat('MMM dd, yyyy').format(reports.first.dateTime) : 'N/A';

    // Condition breakdown counts
    int acneCount = 0;
    int pigmentationCount = 0;
    int eczemaCount = 0;
    int seriousCount = 0;
    int questionnaireReportCount = 0;

    for (final r in reports) {
      final p = r.prediction.toLowerCase();
      if (p.contains('acne')) {
        acneCount++;
      } else if (p.contains('pigmentation')) {
        pigmentationCount++;
      } else if (p.contains('eczema') || p.contains('rash')) {
        eczemaCount++;
      } else if (p.contains('serious')) {
        seriousCount++;
      } else if (p.contains('skin understanding') || r.reportType == 'questionnaire') {
        questionnaireReportCount++;
      }
    }

    // Dynamic Insight Message
    String insightMsg;
    if (totalRoutinesCount > 0 && todayCompletedCount > 0) {
      insightMsg = 'You completed $todayCompletedCount of $totalRoutinesCount scheduled routine tasks today!';
    } else if (weeklyAdherencePct > 0) {
      insightMsg = 'Your routine completion rate is ${weeklyAdherencePct.toStringAsFixed(0)}% for the past 7 days.';
    } else if (reports.isNotEmpty) {
      insightMsg = 'You have generated ${reports.length} saved skin analysis and questionnaire reports.';
    } else {
      insightMsg = l10n.translate('analytics_insight_neutral');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ==========================================
        // SECTION 1: COMPACT OVERVIEW METRIC CARDS
        // ==========================================
        Text(
          l10n.translate('analytics_overview_title'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 580) {
              return Row(
                children: [
                  Expanded(
                    child: _SummaryStatCard(
                      title: l10n.translate('analytics_reports_total'),
                      value: '${reports.length}',
                      subtitle: 'Scans & Records',
                      icon: Icons.assignment_turned_in_rounded,
                      color: AppColors.purple,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryStatCard(
                      title: l10n.translate('analytics_weekly_rate'),
                      value: '${weeklyAdherencePct.toStringAsFixed(0)}%',
                      subtitle: 'Past 7 Days',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.rose,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryStatCard(
                      title: 'Today\'s Tasks',
                      value: '$todayCompletedCount / $totalRoutinesCount',
                      subtitle: 'Completed',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryStatCard(
                      title: 'Skin Profile',
                      value: questionnaireState.skinType,
                      subtitle: questionnaireState.isCompleted ? 'Verified' : 'Not Set',
                      icon: Icons.face_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryStatCard(
                  title: l10n.translate('analytics_reports_total'),
                  value: '${reports.length}',
                  subtitle: 'Scans & Records',
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.purple,
                  isDark: isDark,
                ),
                _SummaryStatCard(
                  title: l10n.translate('analytics_weekly_rate'),
                  value: '${weeklyAdherencePct.toStringAsFixed(0)}%',
                  subtitle: 'Past 7 Days',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.rose,
                  isDark: isDark,
                ),
                _SummaryStatCard(
                  title: 'Today\'s Tasks',
                  value: '$todayCompletedCount / $totalRoutinesCount',
                  subtitle: 'Completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                _SummaryStatCard(
                  title: 'Skin Profile',
                  value: questionnaireState.skinType,
                  subtitle: questionnaireState.isCompleted ? 'Verified' : 'Not Set',
                  icon: Icons.face_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        // Dynamic AI Progress Insight Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI PROGRESS INSIGHT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insightMsg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ==========================================
        // SECTION 2: ROUTINE CONSISTENCY & TRENDS (INTERACTIVE)
        // ==========================================
        _RoutineAdherenceTrendsCard(
          userRoutines: userRoutines,
          logs: logs,
          activeRoutineIds: activeRoutineIds,
          weeklyAdherencePct: weeklyAdherencePct,
          monthlyAdherencePct: monthlyAdherencePct,
          currentStreak: currentStreak,
          bestStreak: maxStreak,
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // ==========================================
        // SECTION 3: QUESTIONNAIRE SKIN PROFILE
        // ==========================================
        _QuestionnaireInsightsCard(
          questionnaireState: questionnaireState,
          reports: reports,
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // ==========================================
        // SECTION 4: SKIN ANALYSIS STATISTICS (INTERACTIVE DONUT CHART)
        // ==========================================
        _SkinAnalysisStatisticsCard(
          reports: reports,
          thisMonthCount: thisMonthCount,
          lastMonthCount: lastMonthCount,
          latestReportDate: latestReportDate,
          acneCount: acneCount,
          pigmentationCount: pigmentationCount,
          eczemaCount: eczemaCount,
          seriousCount: seriousCount,
          questionnaireReportCount: questionnaireReportCount,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineAdherenceTrendsCard extends StatefulWidget {
  final List<SkincareRoutineItem> userRoutines;
  final List<RoutineCompletionLog> logs;
  final Set<String> activeRoutineIds;
  final double weeklyAdherencePct;
  final double monthlyAdherencePct;
  final int currentStreak;
  final int bestStreak;
  final bool isDark;

  const _RoutineAdherenceTrendsCard({
    required this.userRoutines,
    required this.logs,
    required this.activeRoutineIds,
    required this.weeklyAdherencePct,
    required this.monthlyAdherencePct,
    required this.currentStreak,
    required this.bestStreak,
    required this.isDark,
  });

  @override
  State<_RoutineAdherenceTrendsCard> createState() => _RoutineAdherenceTrendsCardState();
}

class _RoutineAdherenceTrendsCardState extends State<_RoutineAdherenceTrendsCard> {
  int _selectedFilterIndex = 0; // 0 = 7 Days, 1 = 30 Days
  int? _touchedBarIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    // 7-Day & 30-Day Completion Data
    final daysCount = _selectedFilterIndex == 0 ? 7 : 30;
    final daysData = <double>[];
    final dayLabels = <String>[];
    final dateStrings = <String>[];
    final completedCounts = <int>[];

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dStr = DateFormat('yyyy-MM-dd').format(date);
      final completed = widget.logs.where((l) => l.dateString == dStr && widget.activeRoutineIds.contains(l.routineId)).length;
      final pct = widget.userRoutines.isNotEmpty ? (completed / widget.userRoutines.length * 100) : 0.0;

      daysData.add(pct.clamp(0.0, 100.0));
      completedCounts.add(completed);
      dateStrings.add(DateFormat('EEE, MMM d').format(date));

      if (_selectedFilterIndex == 0) {
        dayLabels.add(DateFormat('E').format(date).substring(0, 3));
      } else {
        dayLabels.add(i % 5 == 0 ? DateFormat('d/M').format(date) : '');
      }
    }

    // Schedule Breakdown: Morning vs Evening
    final morningRoutines = widget.userRoutines.where((r) => r.routineType.toLowerCase() == 'morning').toList();
    final eveningRoutines = widget.userRoutines.where((r) => r.routineType.toLowerCase() == 'evening').toList();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final morningCompleted = widget.logs.where((l) => l.dateString == todayStr && morningRoutines.any((r) => r.id == l.routineId)).length;
    final eveningCompleted = widget.logs.where((l) => l.dateString == todayStr && eveningRoutines.any((r) => r.id == l.routineId)).length;

    final morningPct = morningRoutines.isNotEmpty ? (morningCompleted / morningRoutines.length * 100) : 0.0;
    final eveningPct = eveningRoutines.isNotEmpty ? (eveningCompleted / eveningRoutines.length * 100) : 0.0;

    return Card(
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
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('analytics_trends_title'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Interactive Daily Routine Adherence',
                              style: TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact Segmented Filter Toggle
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.isDark ? AppColors.lineDark : AppColors.lineLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedFilterIndex = 0;
                          _touchedBarIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedFilterIndex == 0 ? AppColors.purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.translate('analytics_filter_7d'),
                            style: TextStyle(
                              color: _selectedFilterIndex == 0 ? Colors.white : AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedFilterIndex = 1;
                          _touchedBarIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedFilterIndex == 1 ? AppColors.purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.translate('analytics_filter_30d'),
                            style: TextStyle(
                              color: _selectedFilterIndex == 1 ? Colors.white : AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.userRoutines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.spa_outlined, color: AppColors.muted, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        l10n.translate('analytics_empty_routines'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Streak Stat Boxes
              Row(
                children: [
                  Expanded(
                    child: _StreakStatBox(
                      title: l10n.translate('analytics_current_streak'),
                      value: '${widget.currentStreak} Days',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFF4915E),
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StreakStatBox(
                      title: l10n.translate('analytics_best_streak'),
                      value: '${widget.bestStreak} Days',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StreakStatBox(
                      title: l10n.translate('analytics_monthly_rate'),
                      value: '${widget.monthlyAdherencePct.toStringAsFixed(0)}%',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.purple,
                      isDark: widget.isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Bar Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilterIndex == 0 ? '7-Day Completion Rate (%)' : '30-Day Completion Rate (%)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  if (_touchedBarIndex != null && _touchedBarIndex! < dateStrings.length)
                    Text(
                      '${dateStrings[_touchedBarIndex!]}: ${completedCounts[_touchedBarIndex!]} done (${daysData[_touchedBarIndex!].toInt()}%)',
                      style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              barTouchResponse == null ||
                              barTouchResponse.spot == null) {
                            return;
                          }
                          _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dateLabel = dateStrings[groupIndex];
                          final count = completedCounts[groupIndex];
                          final total = widget.userRoutines.length;
                          return BarTooltipItem(
                            '$dateLabel\n$count / $total completed (${rod.toY.toInt()}%)',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < dayLabels.length && dayLabels[idx].isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  dayLabels[idx],
                                  style: TextStyle(
                                    color: _touchedBarIndex == idx ? AppColors.purple : AppColors.muted,
                                    fontSize: 10,
                                    fontWeight: _touchedBarIndex == idx ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (int i = 0; i < daysData.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: daysData[i],
                              color: _touchedBarIndex == i ? AppColors.rose : AppColors.purple,
                              width: _selectedFilterIndex == 0 ? 14 : 6,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Routine Schedule Breakdown: Morning vs Evening
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.isDark ? AppColors.lineDark : AppColors.lineLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('analytics_schedule_breakdown'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    const SizedBox(height: 8),
                    _ScheduleProgressBar(
                      label: 'Morning Routine',
                      completed: morningCompleted,
                      total: morningRoutines.length,
                      percentage: morningPct,
                      color: AppColors.purple,
                    ),
                    const SizedBox(height: 6),
                    _ScheduleProgressBar(
                      label: 'Evening Routine',
                      completed: eveningCompleted,
                      total: eveningRoutines.length,
                      percentage: eveningPct,
                      color: const Color(0xFF4A5568),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleProgressBar extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final double percentage;
  final Color color;

  const _ScheduleProgressBar({
    required this.label,
    required this.completed,
    required this.total,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
            Text('$completed / $total (${percentage.toInt()}%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StreakStatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StreakStatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuestionnaireInsightsCard extends StatelessWidget {
  final QuestionnaireState questionnaireState;
  final List<MedicalReport> reports;
  final bool isDark;

  const _QuestionnaireInsightsCard({
    required this.questionnaireState,
    required this.reports,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final answers = questionnaireState.answers ?? {};

    // Find saved questionnaire report from reportsProvider
    MedicalReport? questionnaireReport;
    for (final r in reports) {
      if (r.reportType == 'questionnaire' ||
          r.prediction == 'Skin Understanding' ||
          r.id.startsWith('SKIN-UND')) {
        questionnaireReport = r;
        break;
      }
    }

    // Fallback generation if answers exist but report object isn't in memory list yet
    if (questionnaireReport == null && questionnaireState.isCompleted && answers.isNotEmpty) {
      questionnaireReport = MedicalReport.fromQuestionnaire(
        id: 'SKIN-UND-PROFILE',
        dateTime: DateTime.now(),
        answers: answers,
      );
    }

    final skinType = questionnaireState.skinType;
    final mainConcern = questionnaireState.mainConcern;
    final primaryGoal = (answers['primary_goal'] ?? answers['goal'] ?? answers['help_request'] ?? 'Healthy Skin Maintenance').toString();
    final sunscreenUse = (answers['sunscreen_usage'] ?? answers['sunscreen'] ?? answers['spf'] ?? 'Daily SPF Protection').toString();

    final rawSymptoms = answers['symptoms'];
    final symptomsStr = rawSymptoms is List
        ? rawSymptoms.join(', ')
        : (rawSymptoms as String? ?? 'None reported');

    final insightsList = questionnaireReport?.keyObservations ?? [];
    final careList = questionnaireReport?.recommendedCare ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: AppColors.purple, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('analytics_questionnaire_title'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Text(
                        'Verified Skin Profile & Personalized Insights',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (questionnaireState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppColors.purple)),
                  ),
                ),
              )
            else if (!questionnaireState.isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete your questionnaire survey to view customized skin profile analytics.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // ==========================================
              // HIERARCHY 1: QUESTIONNAIRE OVERVIEW
              // ==========================================
              Text(
                'QUESTIONNAIRE OVERVIEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              _ProfileDetailRow(
                icon: Icons.water_drop_outlined,
                label: 'Recorded Skin Type',
                value: skinType,
                badgeColor: AppColors.purple,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _ProfileDetailRow(
                icon: Icons.coronavirus_outlined,
                label: 'Primary Skin Concern',
                value: mainConcern,
                badgeColor: AppColors.rose,
                isDark: isDark,
              ),

              const SizedBox(height: 8),
              _ProfileDetailRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Sunscreen Protection',
                value: sunscreenUse,
                badgeColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              if (symptomsStr != 'None reported') ...[
                const SizedBox(height: 8),
                _ProfileDetailRow(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Recorded Symptoms',
                  value: symptomsStr,
                  badgeColor: const Color(0xFF6B7280),
                  isDark: isDark,
                ),
              ],

              // ==========================================
              // HIERARCHY 2: PERSONALIZED INSIGHTS
              // ==========================================
              if (insightsList.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PERSONALIZED AI INSIGHTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: insightsList.map(
                      (obs) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 14)),
                            Expanded(
                              child: Text(obs, style: const TextStyle(fontSize: 12, height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],

              // ==========================================
              // HIERARCHY 3: RECOMMENDED CARE GUIDELINES
              // ==========================================
              if (careList.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: careList.map(
                      (care) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(care, style: const TextStyle(fontSize: 12, height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color badgeColor;
  final bool isDark;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.badgeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, size: 16, color: badgeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinAnalysisStatisticsCard extends StatefulWidget {
  final List<MedicalReport> reports;
  final int thisMonthCount;
  final int lastMonthCount;
  final String latestReportDate;
  final int acneCount;
  final int pigmentationCount;
  final int eczemaCount;
  final int seriousCount;
  final int questionnaireReportCount;
  final bool isDark;

  const _SkinAnalysisStatisticsCard({
    required this.reports,
    required this.thisMonthCount,
    required this.lastMonthCount,
    required this.latestReportDate,
    required this.acneCount,
    required this.pigmentationCount,
    required this.eczemaCount,
    required this.seriousCount,
    required this.questionnaireReportCount,
    required this.isDark,
  });

  @override
  State<_SkinAnalysisStatisticsCard> createState() => _SkinAnalysisStatisticsCardState();
}

class _SkinAnalysisStatisticsCardState extends State<_SkinAnalysisStatisticsCard> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final categories = [
      {'label': 'Acne Vulgaris', 'count': widget.acneCount, 'color': AppColors.purple},
      {'label': 'Hyperpigmentation', 'count': widget.pigmentationCount, 'color': AppColors.rose},
      {'label': 'Eczema / Rash', 'count': widget.eczemaCount, 'color': const Color(0xFFF59E0B)},
      {'label': 'Serious Condition Alert', 'count': widget.seriousCount, 'color': AppColors.danger},
      {'label': 'Skin Profile Survey', 'count': widget.questionnaireReportCount, 'color': const Color(0xFF10B981)},
    ];

    final totalCount = widget.reports.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.rose, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('analytics_reports_title'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Text(
                        'AI Scan Record Condition Distribution',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.description_outlined, color: AppColors.muted, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        l10n.translate('analytics_empty_reports'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Summary Stat Pills Row
              Row(
                children: [
                  Expanded(
                    child: _MiniPill(
                      label: l10n.translate('analytics_reports_this_month'),
                      value: '${widget.thisMonthCount}',
                      color: AppColors.purple,
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _MiniPill(
                      label: l10n.translate('analytics_reports_last_month'),
                      value: '${widget.lastMonthCount}',
                      color: AppColors.rose,
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _MiniPill(
                      label: l10n.translate('analytics_latest_report'),
                      value: widget.latestReportDate,
                      color: const Color(0xFF10B981),
                      isDark: widget.isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Donut Chart & Legend
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: [
                            for (int i = 0; i < categories.length; i++) ...[
                              PieChartSectionData(
                                color: categories[i]['color'] as Color,
                                value: ((categories[i]['count'] as int) > 0 ? (categories[i]['count'] as int) : 0.5).toDouble(),
                                title: '',
                                radius: _touchedPieIndex == i ? 22 : 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < categories.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4),
                            _ChartLegendItem(
                              color: categories[i]['color'] as Color,
                              label: categories[i]['label'] as String,
                              count: categories[i]['count'] as int,
                              isSelected: _touchedPieIndex == i,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_touchedPieIndex >= 0 && _touchedPieIndex < categories.length) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (categories[_touchedPieIndex]['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categories[_touchedPieIndex]['label'] as String,
                        style: TextStyle(
                          color: categories[_touchedPieIndex]['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        '${categories[_touchedPieIndex]['count']} reports (${totalCount > 0 ? ((categories[_touchedPieIndex]['count'] as int) / totalCount * 100).toStringAsFixed(0) : 0}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool isSelected;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isSelected ? 10 : 8,
          height: isSelected ? 10 : 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(color: isSelected ? color : AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
