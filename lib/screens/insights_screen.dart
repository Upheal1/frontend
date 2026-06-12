import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../design_system/tokens/design_tokens.dart';
import '../features/steps/state/step_tracker_state.dart';
import '../models/auth_model.dart';
import '../models/insight_model.dart';
import '../models/mission_model.dart';
import '../models/sleep_model.dart';
import '../models/user_model.dart';
import '../services/ai_insight_generator.dart';
import '../services/challenge_service.dart';
import '../services/insights_service.dart';
import '../services/screen_time_service.dart';
import '../shared/theme/upheal_home_theme.dart';

enum _InsightsRange {
  week('Week', 'weekly'),
  month('Month', 'monthly'),
  quarter('3 Months', '3months');

  const _InsightsRange(this.label, this.periodKey);

  final String label;
  final String periodKey;
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<Insight> _insights = <Insight>[];
  InsightsSummary? _summary;
  List<Map<String, dynamic>> _todayUsage = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _periodUsage = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _weeklyTrend = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _previousWeekTrend = <Map<String, dynamic>>[];
  bool _isLoading = true;
  _InsightsRange _selectedRange = _InsightsRange.week;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      SleepModel? sleepModel;
      StepTrackerState? stepState;

      try {
        sleepModel = context.read<SleepModel>();
      } catch (_) {}

      try {
        stepState = context.read<StepTrackerState>();
      } catch (_) {}

      final List<Map<String, dynamic>> todayUsage =
          await ScreenTimeService.getRealUsageStats();
      final List<Map<String, dynamic>> periodUsage =
          await ScreenTimeService.getAccurateUsageStats(
        period: _selectedRange.periodKey,
      );
      final List<Map<String, dynamic>> weeklyTrend =
          await ScreenTimeService.getDailyUsageForTrend();
      final List<Map<String, dynamic>> previousWeekTrend =
          await ScreenTimeService.getDailyUsageForPreviousWeek();

      Map<String, dynamic>? sleepData;
      Map<String, dynamic>? stepData;

      if (sleepModel != null) {
        sleepData = <String, dynamic>{
          'totalMinutes': sleepModel.totalSleepToday,
          'averageMinutes': sleepModel.averageSleepDuration,
        };
      }

      if (stepState != null) {
        stepData = <String, dynamic>{
          'todaySteps': stepState.todayStepCount,
          'goalSteps': stepState.dailyGoal,
          'weeklySteps': stepState.stepHistory
              .where(
                (data) => data.date.isAfter(
                  DateTime.now().subtract(const Duration(days: 7)),
                ),
              )
              .fold<int>(0, (sum, data) => sum + data.steps),
        };
      }

      final List<Insight> baseInsights = await InsightsService.generateAllInsights(
        usageData: todayUsage,
        sleepData: sleepData,
        stepData: stepData,
        weeklyTrend: weeklyTrend,
        forceRefresh: forceRefresh,
      );

      final List<Insight> aiInsights =
          await AIInsightGenerator.generateIntelligentInsights(
        dailyUsage: todayUsage,
        weeklyTrend: weeklyTrend,
        sleepData: sleepData,
        stepData: stepData,
      );

      final List<Insight> allInsights = <Insight>[
        ...baseInsights,
        ...aiInsights,
      ];
      final Set<String> seenTitles = <String>{};
      final List<Insight> uniqueInsights = <Insight>[];

      for (final Insight insight in allInsights) {
        final String normalizedTitle = insight.title.toLowerCase();
        if (seenTitles.add(normalizedTitle)) {
          uniqueInsights.add(insight);
        }
      }

      uniqueInsights.sort((a, b) {
        final int priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return b.severity.index.compareTo(a.severity.index);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _todayUsage = todayUsage;
        _periodUsage = periodUsage;
        _weeklyTrend = weeklyTrend;
        _previousWeekTrend = previousWeekTrend;
        _insights = uniqueInsights;
        _summary = InsightsService.createSummary(uniqueInsights);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final UpHealHomeTheme tokens = theme.upHealHome;
    final AppResponsiveInfo responsive = context.responsive;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _InsightsLoadingState(isDark: isDark, tokens: tokens),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.pageGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _loadInsights(forceRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                responsive.space(tokens.screenPadding),
                0,
                responsive.space(tokens.screenPadding),
                120,
              ),
              children: <Widget>[
                SizedBox(height: responsive.space(AppSpacing.lg)),
                _buildHeader(context),
                SizedBox(height: responsive.space(AppSpacing.xl)),
                _buildRangeSelector(context),
                SizedBox(height: responsive.space(AppSpacing.xl)),
                _buildOverviewGrid(context),
                SizedBox(height: responsive.space(AppSpacing.xl)),
                _buildMoodTrendCard(context),
                SizedBox(height: responsive.space(AppSpacing.lg)),
                _buildScreenTimeCard(context),
                SizedBox(height: responsive.space(AppSpacing.lg)),
                _buildWellnessRadarCard(context),
                SizedBox(height: responsive.space(AppSpacing.xxl)),
                Text(
                  'AI INSIGHTS',
                  style: GoogleFonts.inter(
                    fontSize: responsive.isTabletOrWider ? 14 : 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: tokens.secondaryText,
                  ),
                ),
                SizedBox(height: responsive.space(AppSpacing.md)),
                ..._buildInsightCards(context),
                SizedBox(height: responsive.space(AppSpacing.xxl)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final AppResponsiveInfo responsive = context.responsive;

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Wellness Insights',
            style: GoogleFonts.inter(
              fontSize: responsive.isTabletOrWider ? 34 : 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: tokens.primaryText,
            ),
          ),
          SizedBox(height: responsive.space(AppSpacing.xxs)),
          Text(
            'Understand your habits, focus, mood, and recovery.',
            style: GoogleFonts.inter(
              fontSize: responsive.isTabletOrWider ? 15 : 14,
              fontWeight: FontWeight.w500,
              color: tokens.secondaryText,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.04, end: 0);
  }

  Widget _buildRangeSelector(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppResponsiveInfo responsive = context.responsive;

    return Container(
      padding: EdgeInsets.all(responsive.space(AppSpacing.xxs)),
      decoration: BoxDecoration(
        color: isDark
            ? tokens.cardFill
            : tokens.cardFill.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: _InsightsRange.values.map((range) {
          final bool isSelected = range == _selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: isSelected
                  ? null
                  : () {
                      setState(() => _selectedRange = range);
                      _loadInsights();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.space(AppSpacing.md),
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? tokens.accentGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  range.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: responsive.isTabletOrWider ? 14 : 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : tokens.secondaryText,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context) {
    final UserModel user = context.watch<UserModel>();
    final MissionsModel missions = context.watch<MissionsModel>();
    final ChallengeService challenges = context.watch<ChallengeService>();
    final StepTrackerState stepState = context.watch<StepTrackerState>();
    final AppResponsiveInfo responsive = context.responsive;
    final int tasksCompleted = missions.completedCount + challenges.completedTotalCount;
    final int tasksGoal = 24;
    final int weeklySteps = _weeklyStepTotal(stepState);
    final double averageDailyScreenTime = _averageDailyScreenHours;
    final double stepProgress =
        (tasksCompleted / tasksGoal * 100).clamp(0, 100).toDouble();
    final double weeklyStepDelta = _weeklyStepsDelta(stepState);

    final List<_OverviewCardData> cards = <_OverviewCardData>[
      _OverviewCardData(
        icon: LucideIcons.flame,
        iconTint: const Color(0xFFFF8A3D),
        iconBackground: const Color(0xFFFFF1E7),
        value: '${user.streakDays} days',
        title: 'Current Streak',
        footnote: user.streakDays >= 7 ? 'Personal best!' : 'Keep the streak alive',
        footnoteColor: const Color(0xFFFF8A3D),
      ),
      _OverviewCardData(
        icon: LucideIcons.zap,
        iconTint: const Color(0xFFD8A436),
        iconBackground: const Color(0xFFFFF5D9),
        value: _formatWholeNumber(weeklySteps),
        title: 'Weekly Steps',
        footnote: '${weeklyStepDelta >= 0 ? '+' : ''}${weeklyStepDelta.toStringAsFixed(0)}% vs last week',
        footnoteColor: weeklyStepDelta >= 0
            ? const Color(0xFFD8A436)
            : const Color(0xFF7D89A6),
      ),
      _OverviewCardData(
        icon: LucideIcons.target,
        iconTint: const Color(0xFF7AA86F),
        iconBackground: const Color(0xFFE9F5E4),
        value: '$tasksCompleted/$tasksGoal',
        title: 'Tasks Done',
        footnote: '${stepProgress.toStringAsFixed(0)}% completion',
        footnoteColor: const Color(0xFF7AA86F),
      ),
      _OverviewCardData(
        icon: LucideIcons.clock3,
        iconTint: const Color(0xFF76A8F6),
        iconBackground: const Color(0xFFEAF3FF),
        value: '${averageDailyScreenTime.toStringAsFixed(1)} hrs',
        title: 'Screen Time',
        footnote: averageDailyScreenTime <= 5
            ? 'Goal: under 5h ${String.fromCharCode(10003)}'
            : 'Goal: under 5h',
        footnoteColor: const Color(0xFF76A8F6),
      ),
    ];

    final int crossAxisCount = responsive.isTabletOrWider ? 4 : 2;

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: responsive.space(AppSpacing.md),
        mainAxisSpacing: responsive.space(AppSpacing.md),
        childAspectRatio: responsive.isTabletOrWider ? 1.32 : 0.96,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _OverviewMetricCard(data: cards[index]);
      },
    );
  }

  Widget _buildMoodTrendCard(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<double> moodPoints = _moodTrendValues;
    final double trendDelta = _trendDeltaPercent(moodPoints);
    final Color lineColor = isDark
        ? const Color(0xFF8A6CF6)
        : const Color(0xFF7C5CF5);

    return _InsightsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CardHeader(
            title: 'Mood Trend',
            subtitle: '7-day overview',
            badgeText: '${trendDelta >= 0 ? '+' : ''}${trendDelta.round()}%',
            badgeColor: trendDelta >= 0
                ? const Color(0xFFE4F6E6)
                : const Color(0xFFFFF1E7),
            badgeTextColor: trendDelta >= 0
                ? const Color(0xFF6EA474)
                : const Color(0xFFE07A5F),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5.5,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? tokens.cardBorder
                        : tokens.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: tokens.faintText,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const List<String> labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final int index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: tokens.faintText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.4,
                        color: lineColor,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          lineColor.withValues(alpha: 0.16),
                          lineColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    spots: List<FlSpot>.generate(
                      moodPoints.length,
                      (int index) => FlSpot(index.toDouble(), moodPoints[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<double> barValues = _barTrendValues;
    final double percentChange = _screenTimeChangePercent;
    final double goalProgress = (_averageDailyScreenHours / 5).clamp(0, 1);
    final Color barColor = isDark
        ? const Color(0xFF5B7CFA).withValues(alpha: 0.7)
        : const Color(0xFF5B7CFA);

    return _InsightsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CardHeader(
            title: 'Screen Time',
            subtitle: _selectedRange == _InsightsRange.week
                ? 'Daily hours'
                : '${_selectedRange.label} overview',
            badgeText: '${percentChange >= 0 ? '+' : ''}${percentChange.round()}%',
            badgeColor: percentChange <= 0
                ? const Color(0xFFE4F6E6)
                : const Color(0xFFFFF1E7),
            badgeTextColor: percentChange <= 0
                ? const Color(0xFF6EA474)
                : const Color(0xFFE07A5F),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: math.max(10, (barValues.fold<double>(0, math.max) + 1.5)),
                minY: 0,
                groupsSpace: 10,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? tokens.cardBorder
                        : tokens.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 3,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: tokens.faintText,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        const List<String> labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final int index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[index],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: tokens.faintText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(
                  barValues.length,
                  (int index) => BarChartGroupData(
                    x: index,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: barValues[index],
                        width: 26,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                          bottom: Radius.circular(4),
                        ),
                        color: barColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: goalProgress,
                    backgroundColor: tokens.trackColor,
                    color: const Color(0xFF5B7CFA),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Goal: 5h/day \u2022 Today: ${_todayHours.toStringAsFixed(1)}h${_todayHours <= 5 ? ' \u2713' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessRadarCard(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final _RadarMetrics radar = _radarMetrics(context);
    final Color radarFill = isDark
        ? const Color(0xFF8A6CF6).withValues(alpha: 0.25)
        : const Color(0xFF8A6CF6).withValues(alpha: 0.18);
    final Color radarBorder = isDark
        ? const Color(0xFF8A6CF6).withValues(alpha: 0.5)
        : const Color(0xFF8A6CF6).withValues(alpha: 0.4);

    return _InsightsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CardHeader(
            title: 'Wellness Radar',
            subtitle: 'Your skill map this month',
            trailing: Icon(
              LucideIcons.sparkles,
              size: 16,
              color: tokens.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: false),
                dataSets: <RadarDataSet>[
                  RadarDataSet(
                    fillColor: radarFill,
                    borderColor: radarBorder,
                    entryRadius: 2.6,
                    borderWidth: 2,
                    dataEntries: radar.values
                        .map((value) => RadarEntry(value: value))
                        .toList(growable: false),
                  ),
                ],
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.transparent,
                ),
                tickBorderData: BorderSide(
                  color: isDark
                      ? tokens.cardBorder
                      : tokens.dividerColor,
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: isDark
                      ? tokens.cardBorder
                      : tokens.dividerColor,
                  width: 1,
                ),
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: tokens.secondaryText,
                ),
                titlePositionPercentageOffset: 0.15,
                getTitle: (index, angle) => RadarChartTitle(
                  text: radar.labels[index],
                  angle: angle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInsightCards(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final List<Insight> cards = _insights.take(3).toList(growable: false);
    if (cards.isEmpty) {
      return <Widget>[
        _InsightsSurface(
          child: Text(
            'Use the app a little longer to unlock your first AI wellness summary.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: tokens.secondaryText,
            ),
          ),
        ),
      ];
    }

    return cards.asMap().entries.map((entry) {
      final int index = entry.key;
      final Insight insight = entry.value;
      final _InsightPalette palette = _paletteFor(insight);

      return Padding(
        padding: EdgeInsets.only(bottom: index == cards.length - 1 ? 0 : 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  palette.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      insight.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _insightSummaryText(insight),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: tokens.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        palette.badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette.badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(growable: false);
  }

  double get _todayHours {
    if (_todayUsage.isEmpty) {
      return 0;
    }
    return _todayUsage.fold<double>(
      0,
      (sum, app) => sum + ((app['usageTime'] as int?) ?? 0) / (1000 * 60 * 60),
    );
  }

  double get _averageDailyScreenHours {
    final double totalHours = _periodUsage.fold<double>(
      0,
      (sum, app) => sum + ((app['usageTime'] as int?) ?? 0) / (1000 * 60 * 60),
    );

    final int divisor = switch (_selectedRange) {
      _InsightsRange.week => 7,
      _InsightsRange.month => 30,
      _InsightsRange.quarter => 90,
    };

    return divisor == 0 ? 0 : totalHours / divisor;
  }

  double get _screenTimeChangePercent {
    final double current = _weeklyTrend.fold<double>(
      0,
      (sum, day) => sum + ((day['totalHours'] as num?)?.toDouble() ?? 0),
    );
    final double previous = _previousWeekTrend.fold<double>(
      0,
      (sum, day) => sum + ((day['totalHours'] as num?)?.toDouble() ?? 0),
    );

    if (previous <= 0.01) {
      return 0;
    }
    return ((current - previous) / previous) * 100;
  }

  List<double> get _barTrendValues {
    if (_weeklyTrend.isEmpty) {
      return <double>[4.4, 4.2, 4.9, 3.6, 4.1, 5.0, 3.2];
    }

    return _weeklyTrend.map((day) {
      return (((day['totalHours'] as num?)?.toDouble() ?? 0).clamp(0, 10)).toDouble();
    }).toList(growable: false);
  }

  List<double> get _moodTrendValues {
    if (_weeklyTrend.isEmpty) {
      return <double>[2.8, 3.2, 2.9, 3.8, 4.1, 3.5, 3.9];
    }

    return _weeklyTrend.asMap().entries.map((entry) {
      final int index = entry.key;
      final double hours = ((entry.value['totalHours'] as num?)?.toDouble() ?? 0);
      final double inverseUsage = 4.9 - (hours.clamp(0, 8) * 0.34);
      final double gentleVariation = math.sin((index + 1) * 0.8) * 0.25;
      return ((inverseUsage + gentleVariation).clamp(1.6, 4.8)).toDouble();
    }).toList(growable: false);
  }

  int _weeklyStepTotal(StepTrackerState state) {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
    return state.stepHistory
        .where((data) => data.date.isAfter(cutoff))
        .fold<int>(0, (sum, data) => sum + data.steps);
  }

  double _weeklyStepsDelta(StepTrackerState state) {
    final DateTime now = DateTime.now();
    final DateTime currentCutoff = now.subtract(const Duration(days: 7));
    final DateTime previousCutoff = now.subtract(const Duration(days: 14));

    final int current = state.stepHistory
        .where((data) => data.date.isAfter(currentCutoff))
        .fold<int>(0, (sum, data) => sum + data.steps);
    final int previous = state.stepHistory
        .where((data) =>
            data.date.isAfter(previousCutoff) && data.date.isBefore(currentCutoff))
        .fold<int>(0, (sum, data) => sum + data.steps);

    if (previous == 0) {
      return current.toDouble();
    }
    return ((current - previous) / previous) * 100;
  }

  double _trendDeltaPercent(List<double> values) {
    if (values.length < 2 || values.first == 0) {
      return 0;
    }
    return ((values.last - values.first) / values.first) * 100;
  }

  String _formatWholeNumber(int value) {
    final String source = value.toString();
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < source.length; index++) {
      final int reverseIndex = source.length - index;
      buffer.write(source[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  _RadarMetrics _radarMetrics(BuildContext context) {
    final SleepModel sleep = context.watch<SleepModel>();
    final StepTrackerState stepState = context.watch<StepTrackerState>();
    final AuthModel auth = context.watch<AuthModel>();
    final UserModel user = context.watch<UserModel>();

    final double sleepScore = ((sleep.totalSleepToday / 480) * 100).clamp(22, 96);
    final double focusScore = ((5 - _averageDailyScreenHours.clamp(0, 5)) / 5 * 100)
        .clamp(18, 94)
        .toDouble();
    final double calmScore = ((_summary?.overallHealthScore ?? 65) + 6)
        .clamp(20, 96)
        .toDouble();
    final double socialHours = _periodUsage.fold<double>(0, (sum, app) {
      final String category = (app['category'] as String? ?? '').toLowerCase();
      if (category.contains('social')) {
        return sum + ((app['usageTime'] as int?) ?? 0) / (1000 * 60 * 60);
      }
      return sum;
    });
    final double socialScore = (70 - (socialHours * 6)).clamp(20, 92).toDouble();
    final double habitsScore = (math.min(user.streakDays, 21) / 21 * 100)
        .clamp(18, 98)
        .toDouble();
    final double energyScore = math.max(
      ((stepState.todayStepCount / stepState.dailyGoal) * 100).clamp(18, 96).toDouble(),
      auth.isAuthenticated ? 32 : 24,
    );

    return _RadarMetrics(
      labels: const <String>['Focus', 'Calm', 'Sleep', 'Social', 'Habits', 'Energy'],
      values: <double>[
        focusScore,
        calmScore,
        sleepScore,
        socialScore,
        habitsScore,
        energyScore,
      ],
    );
  }

  _InsightPalette _paletteFor(Insight insight) {
    switch (insight.category) {
      case InsightCategory.positive:
        return const _InsightPalette(
          background: Color(0xFFEAF5E9),
          border: Color(0xFFC9DFC5),
          emoji: '🌅',
          badgeColor: Color(0xFFD4EDD4),
          badgeTextColor: Color(0xFF3D8B47),
          badgeLabel: 'Positive',
        );
      case InsightCategory.neutral:
        return const _InsightPalette(
          background: Color(0xFFEAF3FF),
          border: Color(0xFFC9DBF4),
          emoji: '📊',
          badgeColor: Color(0xFFD4E4FF),
          badgeTextColor: Color(0xFF4A7BCF),
          badgeLabel: 'Insight',
        );
      case InsightCategory.warning:
        return const _InsightPalette(
          background: Color(0xFFFFF1E7),
          border: Color(0xFFF1D4B9),
          emoji: '🔥',
          badgeColor: Color(0xFFFFE4D6),
          badgeTextColor: Color(0xFFD4763A),
          badgeLabel: 'Notice',
        );
      case InsightCategory.critical:
        return const _InsightPalette(
          background: Color(0xFFFFE9E6),
          border: Color(0xFFF3C4BB),
          emoji: '⚠️',
          badgeColor: Color(0xFFFFD6D1),
          badgeTextColor: Color(0xFFC9443A),
          badgeLabel: 'Attention',
        );
    }
  }

  String _insightSummaryText(Insight insight) {
    final String text = insight.description.trim().isNotEmpty
        ? insight.description.trim()
        : insight.title.trim();
    return text.endsWith('.') ? text : '$text.';
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState({required this.isDark, required this.tokens});

  final bool isDark;
  final UpHealHomeTheme tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.pageGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: tokens.primaryText.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms),
            const SizedBox(height: 22),
            Text(
              'Building your wellness snapshot...',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({required this.data});

  final _OverviewCardData data;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? tokens.cardFill : tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : <BoxShadow>[],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 16, color: data.iconTint),
          ),
          const Spacer(),
          Text(
            data.value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: tokens.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.footnote,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: data.footnoteColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSurface extends StatelessWidget {
  const _InsightsSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? tokens.cardFill : tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : <BoxShadow>[],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              badgeText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.icon,
    required this.iconTint,
    required this.iconBackground,
    required this.value,
    required this.title,
    required this.footnote,
    required this.footnoteColor,
  });

  final IconData icon;
  final Color iconTint;
  final Color iconBackground;
  final String value;
  final String title;
  final String footnote;
  final Color footnoteColor;
}

class _RadarMetrics {
  const _RadarMetrics({required this.labels, required this.values});

  final List<String> labels;
  final List<double> values;
}

class _InsightPalette {
  const _InsightPalette({
    required this.background,
    required this.border,
    required this.emoji,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.badgeLabel,
  });

  final Color background;
  final Color border;
  final String emoji;
  final Color badgeColor;
  final Color badgeTextColor;
  final String badgeLabel;
}
