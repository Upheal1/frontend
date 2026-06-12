import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sleep_session.dart';
import '../services/sleep_service.dart';
import '../constants/app_colors.dart';
import '../widgets/drawer_menu_button.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final SleepService _sleepService = SleepService();
  bool _isLoading = false;
  String _selectedPeriod = 'weekly';
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    await _sleepService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
      if (_sleepService.isTracking) {
        _startLiveTimer();
      }
    }
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startSleepTracking() async {
    await _sleepService.startSleepTracking();
    if (mounted) {
      setState(() => _startLiveTimer());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep tracking started!'),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isEnding = false;

  Future<void> _endSleepTracking() async {
    if (!_sleepService.isTracking || _isEnding) return;

    _liveTimer?.cancel();
    final result = await showDialog<_EndSleepResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SleepEndDialog(),
    );

    if (result == null || !mounted) {
      if (_sleepService.isTracking) _startLiveTimer();
      return;
    }

    setState(() => _isEnding = true);
    await _sleepService.endSleepTracking(
      quality: result.quality,
      notes: result.notes.isNotEmpty ? result.notes : null,
    );
    setState(() => _isEnding = false);

    if (mounted) {
      final sessions = _sleepService.sessions;
      if (sessions.isNotEmpty) {
        final session = sessions.last;
        final xp = session.calculateXP();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep session completed! +$xp XP'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
      backgroundColor: isDark ? Colors.transparent : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: DrawerMenuButton(
          iconColor: isDark ? Colors.white : colorScheme.onSurface,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep Tracker',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            Text(
              'Build better rest, one night at a time.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              child: Column(
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildOverviewStats(),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildSleepChart(),
                  const SizedBox(height: 20),
                  _buildRecentSessions(),
                ],
              ),
            ),
    );
  }

  // ─── Hero Card ─────────────────────────────────────────────────

  Widget _buildHeroCard() {
    if (_sleepService.isTracking) {
      return _buildActiveSessionCard();
    }
    return _buildStartSleepCard();
  }

  Widget _buildStartSleepCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.purple.withOpacity(0.35),
                  const Color(0xFF2D1B69).withOpacity(0.5),
                  const Color(0xFF1A1040).withOpacity(0.6),
                ]
              : [
                  AppColors.purple.withOpacity(0.15),
                  AppColors.blue.withOpacity(0.08),
                  AppColors.purple.withOpacity(0.04),
                ],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.purple.withOpacity(0.25)
              : AppColors.purple.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withOpacity(0.3),
                  AppColors.purple.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              LucideIcons.moon,
              color: isDark ? AppColors.purple.withOpacity(0.9) : AppColors.purple,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to rest?',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking before sleep and wake up to insights.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _startSleepTracking,
              icon: const Icon(LucideIcons.moon, size: 20),
              label: Text(
                'Start Sleep',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    final session = _sleepService.currentSession!;
    final elapsed = session.elapsedTime;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.purple.withOpacity(0.4),
                  const Color(0xFF2D1B69).withOpacity(0.5),
                  const Color(0xFF1A1040).withOpacity(0.6),
                ]
              : [
                  AppColors.purple.withOpacity(0.12),
                  AppColors.purple.withOpacity(0.06),
                  const Color(0xFFB07BF5).withOpacity(0.04),
                ],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.purple.withOpacity(0.25)
              : AppColors.purple.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withOpacity(0.3),
                  AppColors.purple.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              LucideIcons.moon,
              color: isDark ? Colors.white.withOpacity(0.9) : AppColors.purple,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sleep in progress',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${hours}h ${minutes}m',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Started at ${_formatTime(session.startTime)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isEnding ? null : _endSleepTracking,
              icon: const Icon(LucideIcons.sun, size: 20),
              label: Text(
                'End Sleep',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: AppColors.purple.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ─── Stats Section ─────────────────────────────────────────────

  Widget _buildOverviewStats() {
    final avgDuration = _sleepService.getAverageSleepDuration();
    final avgQuality = _sleepService.getAverageSleepQuality();
    final hours = avgDuration.inHours;
    final minutes = avgDuration.inMinutes % 60;
    final totalNights = _sleepService.sessions.where((s) => s.isCompleted).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.clock,
            value: hours > 0 ? '${hours}h ${minutes}m' : '--',
            label: 'Average Sleep',
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.star,
            value: _getQualityText(avgQuality),
            label: 'Sleep Quality',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.calendar,
            value: '$totalNights',
            label: 'Total Nights',
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? color.withOpacity(0.12)
            : color.withOpacity(0.08),
        border: Border.all(
          color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Period Selector ───────────────────────────────────────────

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : colorScheme.surfaceContainerHighest.withOpacity(0.6),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPill('Weekly', 'weekly', LucideIcons.calendarDays)),
          const SizedBox(width: 4),
          Expanded(child: _buildPill('Monthly', 'monthly', LucideIcons.calendarRange)),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: isSelected
              ? AppColors.purple
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (
                isDark ? Colors.white.withOpacity(0.5) : colorScheme.onSurface.withOpacity(0.5)
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (
                  isDark ? Colors.white.withOpacity(0.7) : colorScheme.onSurface.withOpacity(0.7)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sleep Chart ───────────────────────────────────────────────

  Widget _buildSleepChart() {
    return FutureBuilder<List<SleepSession>>(
      future: _selectedPeriod == 'weekly'
          ? _sleepService.getWeeklySessions()
          : _sleepService.getMonthlySessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return _buildChartEmptyState();
        }

        return _buildChartWithData(sessions);
      },
    );
  }

  Widget _buildChartEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.barChart3,
            size: 36,
            color: isDark
                ? Colors.white.withOpacity(0.25)
                : colorScheme.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No sleep data yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your first night to see your rhythm.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartWithData(List<SleepSession> sessions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final sorted = List<SleepSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 18,
                color: isDark ? Colors.white.withOpacity(0.7) : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                'Sleep Duration Trend',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : colorScheme.primary.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                        final date = sorted[i].startTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}h',
                          style: GoogleFonts.inter(
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: sorted.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;
                  final hours = session.duration?.inHours.toDouble() ?? 0.0;
                  final qualityColor = _getQualityColor(session.quality);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        color: isDark
                            ? qualityColor.withOpacity(0.8)
                            : qualityColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Sessions ───────────────────────────────────────────

  Widget _buildRecentSessions() {
    return FutureBuilder<List<SleepSession>>(
      future: _selectedPeriod == 'weekly'
          ? _sleepService.getWeeklySessions()
          : _sleepService.getMonthlySessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 18,
                    color: isDark ? Colors.white.withOpacity(0.7) : colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...sessions.take(5).map((session) => _buildSessionCard(session)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(SleepSession session) {
    final duration = session.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration != null ? (duration.inMinutes % 60) : 0;
    final date = session.startTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final qualityColor = _getQualityColor(session.quality);
    final hasNotes = session.notes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: qualityColor.withOpacity(isDark ? 0.2 : 0.15),
                ),
                child: Icon(
                  LucideIcons.moon,
                  color: qualityColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration != null
                          ? '$hours h $minutes m \u2022 ${_getQualityText(session.quality.index.toDouble())}'
                          : 'Incomplete',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (duration != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.green.withOpacity(isDark ? 0.15 : 0.1),
                  ),
                  child: Text(
                    '+${session.calculateXP()} XP',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
            ],
          ),
          if (hasNotes) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 52),
                Expanded(
                  child: Text(
                    session.notes.join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Color _getQualityColor(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return AppColors.green;
      case SleepQuality.good:
        return AppColors.blue;
      case SleepQuality.fair:
        return AppColors.orange;
      case SleepQuality.poor:
        return AppColors.red;
    }
  }

  String _getQualityText(double qualityIndex) {
    if (qualityIndex >= 3) return 'Excellent';
    if (qualityIndex >= 2) return 'Good';
    if (qualityIndex >= 1) return 'Fair';
    return 'Poor';
  }
}

// ─── End Sleep Dialog ──────────────────────────────────────────────

class _EndSleepResult {
  final SleepQuality quality;
  final List<String> notes;
  const _EndSleepResult({required this.quality, required this.notes});
}

class _SleepEndDialog extends StatefulWidget {
  const _SleepEndDialog();

  @override
  State<_SleepEndDialog> createState() => _SleepEndDialogState();
}

class _SleepEndDialogState extends State<_SleepEndDialog> {
  SleepQuality _selectedQuality = SleepQuality.good;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: isDark
          ? const Color(0xFF1E1535)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withOpacity(isDark ? 0.2 : 0.1),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: AppColors.purple,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your sleep?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rate your night to complete the session',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: SleepQuality.values.map((quality) {
                final isSelected = _selectedQuality == quality;
                final label = _qualityLabel(quality);
                final icon = _qualityIcon(quality);
                return GestureDetector(
                  onTap: () => setState(() => _selectedQuality = quality),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppColors.purple
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.purple
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : (
                            isDark ? Colors.white.withOpacity(0.6) : colorScheme.onSurface.withOpacity(0.6)
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : colorScheme.onSurface.withOpacity(0.3),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : colorScheme.onSurface,
                fontSize: 13,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white.withOpacity(0.7) : colorScheme.onSurface.withOpacity(0.7),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _isSaving = true);
                            final notes = _notesController.text.trim();
                            Navigator.of(context).pop(
                              _EndSleepResult(
                                quality: _selectedQuality,
                                notes: notes.isNotEmpty ? [notes] : [],
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: AppColors.purple.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save Sleep',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }

  IconData _qualityIcon(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return LucideIcons.frown;
      case SleepQuality.fair:
        return LucideIcons.meh;
      case SleepQuality.good:
        return LucideIcons.smile;
      case SleepQuality.excellent:
        return LucideIcons.sparkles;
    }
  }
}
