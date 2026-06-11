import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../state/step_tracker_state.dart';
import '../../domain/models/step_data.dart';
import '../../../../design_system/tokens/design_tokens.dart';
import '../../../../navigation/app_navigation_keys.dart';
import '../../presentation/steps_theme.dart';
import '../widgets/step_permission_widget.dart';
import '../../../../widgets/common/skeleton_loader.dart';
import '../../../../widgets/common/empty_state_widget.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = Provider.of<StepTrackerState>(context, listen: false);
      if (!state.isInitialized) {
        state.initialize().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StepTrackerState>(context, listen: false)
              .refresh()
              .catchError((_) {});
        }
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<StepTrackerState>(
        builder: (context, state, _) {
          final isBusy = state.isLoading && !state.isInitialized;

          if (isBusy) return _buildSkeleton();
          if (!state.hasPermission) {
            return SingleChildScrollView(
              child: StepPermissionWidget(state: state),
            );
          }
          if (state.errorMessage != null) {
            return _buildError(state);
          }
          if (state.isInitialized &&
              state.hasPermission &&
              !state.isLoading &&
              state.todayStepCount == 0 &&
              state.stepHistory.isEmpty) {
            return Center(
              child: Padding(
                padding: 24.insetsAll,
                child: EmptyStateWidget(
                  iconData: LucideIcons.footprints,
                  title: 'No step data yet',
                  subtitle:
                      'Start walking or sync your device to see your steps.',
                  actionText: 'Refresh',
                  onAction: () => state.refresh(),
                ),
              ),
            );
          }
          return _buildContent(state);
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: 16.insetsAll,
      child: Column(
        children: [
          SkeletonLoader.cardSkeleton(),
          16.gapV,
          SkeletonLoader.cardSkeleton(),
          16.gapV,
          SkeletonLoader.chartSkeleton(),
          16.gapV,
          SkeletonLoader.listItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildError(StepTrackerState state) {
    return Center(
      child: Padding(
        padding: 24.insetsAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, color: context.steps.accentOrange, size: 48),
            16.gapV,
            Text(state.errorMessage!, textAlign: TextAlign.center,
                style: TextStyle(color: context.steps.textSoft)),
            16.gapV,
            FilledButton(onPressed: () => state.refresh(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(StepTrackerState state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(state)),
        SliverToBoxAdapter(child: _buildStepRing(state)),
        SliverToBoxAdapter(child: _buildQuickRecap(state)),
        SliverToBoxAdapter(child: _buildWeeklyChart(state)),
        SliverToBoxAdapter(child: _buildSmartMessage(state)),
        SliverToBoxAdapter(child: _buildActivityLog(state)),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  Widget _buildHeader(StepTrackerState state) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.menu,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A)),
                onPressed: () => rootScaffoldKey.currentState?.openDrawer(),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.calendar,
                    color: context.steps.textFaint),
                onPressed: () {},
              ),
            ],
          ),
          Text(_greeting(),
              style: TextStyle(
                  fontSize: 14,
                  color: context.steps.textSoft,
                  height: 1.2)),
          2.gapV,
          Text("Today's steps",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.56,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.1)),
        ],
      ),
    );
  }

  Widget _buildStepRing(StepTrackerState state) {
    final steps = state.todayStepCount;
    final goal = state.dailyGoal;
    final progress = (steps / goal).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xl,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.steps.cardSurface,
          borderRadius: AppRadius.xl,
          boxShadow: Theme.of(context).appShadows.soft,
        ),
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _StepRingPainter(
                      progress: value,
                      trackColor: context.steps.ringTrackColor,
                      progressColors: context.steps.ringProgressColors,
                      glowColor: context.steps.ringGlowColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatNumber(steps),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.96,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.0,
                            ),
                          ),
                          4.gapV,
                          Text('steps',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: context.steps.textSoft,
                                  height: 1.2)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            16.gapV,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.flag, size: 14, color: context.steps.textFaint),
                4.gapH,
                Text('Goal: ${_formatNumber(goal)} steps',
                    style: TextStyle(
                        fontSize: 13,
                        color: context.steps.textFaint,
                        height: 1.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRecap(StepTrackerState state) {
    final today = state.todaySteps;
    final distance = today?.distance ?? 0.0;
    final calories = today?.calories ?? 0;
    final activeMin = today?.activeTime.inMinutes ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding)
          .copyWith(bottom: AppSpacing.xl),
      child: Row(
        children: [
          _recapTile(LucideIcons.mapPin, '${distance.toStringAsFixed(1)} km',
              'Distance', context.steps.accentBlue),
          12.gapH,
          _recapTile(LucideIcons.flame, '$calories', 'Calories',
              context.steps.accentOrange),
          12.gapH,
          _recapTile(LucideIcons.clock, '${activeMin}m', 'Active',
              context.steps.accentGreen),
        ],
      ),
    );
  }

  Widget _recapTile(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.steps.cardSurface,
          borderRadius: AppRadius.lg,
          boxShadow: Theme.of(context).appShadows.soft,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            8.gapV,
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1)),
            2.gapV,
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.steps.textFaint, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(StepTrackerState state) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekData = state.getStepsForPeriod(weekStart, now);

    final Map<int, int> daySteps = {};
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      daySteps[d.weekday] = 0;
    }
    for (final data in weekData) {
      if (data.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        daySteps[data.date.weekday] = data.steps;
      }
    }

    final maxVal =
        daySteps.values.fold<int>(1, (a, b) => a > b ? a : b).toDouble();

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWd = now.weekday;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding)
          .copyWith(bottom: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: context.steps.cardSurface,
          borderRadius: AppRadius.xl,
          boxShadow: Theme.of(context).appShadows.soft,
        ),
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2)),
            20.gapV,
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final wd = i + 1;
                  final stepsForDay = daySteps[wd] ?? 0;
                  final isToday = wd == todayWd;
                  final frac = maxVal > 0 ? stepsForDay / maxVal : 0.0;
                  final barH = (frac * 100).clamp(4.0, 100.0);
                  final colorIdx = i % context.steps.barColors.length;
                  final barColor = isToday
                      ? context.steps.barColors[colorIdx]
                      : context.steps.barInactiveColor;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: barH),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, h, _) {
                              return Container(
                                width: double.infinity,
                                height: h,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius:
                                      BorderRadius.vertical(top: AppRadius.xsUnit),
                                ),
                              );
                            },
                          ),
                          6.gapV,
                          Text(dayLabels[i],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.steps.textFaint,
                                  height: 1.2)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMessage(StepTrackerState state) {
    final steps = state.todayStepCount;
    final goal = state.dailyGoal;
    final progress = steps / goal;

    String title;
    String subtitle;
    IconData icon;

    if (steps >= goal) {
      title = 'Goal crushed!';
      subtitle = 'Amazing work today! Keep it up.';
      icon = LucideIcons.trophy;
    } else if (progress >= 0.75) {
      title = 'Almost there!';
      subtitle = 'Just a few more steps to reach your goal.';
      icon = LucideIcons.zap;
    } else if (progress >= 0.5) {
      title = 'Halfway there!';
      subtitle = "You're making great progress today.";
      icon = LucideIcons.trendingUp;
    } else if (progress >= 0.25) {
      title = 'Keep going!';
      subtitle = 'Every step counts toward your goal.';
      icon = LucideIcons.footprints;
    } else {
      title = 'Ready to move?';
      subtitle = 'Take a walk to get started on your goal.';
      icon = LucideIcons.footprints;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding)
          .copyWith(bottom: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.steps.smartMessageGradient,
          borderRadius: AppRadius.xl,
          border: Border.all(color: context.steps.glassBorder),
        ),
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: context.steps.avatarGradient,
                borderRadius: AppRadius.lg,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            16.gapH,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2)),
                  2.gapV,
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.steps.textSoft,
                          height: 1.3)),
                ],
              ),
            ),
            12.gapH,
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.steps.accentPurple,
                borderRadius: AppRadius.pill,
              ),
              child: Text('Start',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(StepTrackerState state) {
    final recent = state.stepHistory
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (recent.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding)
          .copyWith(bottom: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: context.steps.cardSurface,
          borderRadius: AppRadius.xl,
          boxShadow: Theme.of(context).appShadows.soft,
        ),
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Log',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2)),
            16.gapV,
            ...recent.take(5).map((data) => _logRow(data)),
          ],
        ),
      ),
    );
  }

  Widget _logRow(StepData data) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label =
        '${dayNames[data.date.weekday - 1]} ${data.date.day}/${data.date.month}';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: context.steps.textSoft,
                  height: 1.2)),
          Spacer(),
          Icon(LucideIcons.footprints,
              size: 12, color: context.steps.textFaint),
          4.gapH,
          Text('${data.steps}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2)),
          16.gapH,
          Text('${data.distance.toStringAsFixed(1)} km',
              style: TextStyle(
                  fontSize: 12, color: context.steps.textFaint, height: 1.2)),
          16.gapH,
          Text('${data.calories} cal',
              style: TextStyle(
                  fontSize: 12, color: context.steps.textFaint, height: 1.2)),
        ],
      ),
    );
  }

}

class _StepRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> progressColors;
  final Color glowColor;

  _StepRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColors,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 16) / 2;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.005) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [glowColor, glowColor.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 20))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(rect, -1.5708, math.pi * 2 * progress, false, glowPaint);

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -1.5708,
          endAngle: -1.5708 + math.pi * 2 * progress,
          colors: progressColors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -1.5708, math.pi * 2 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_StepRingPainter old) => old.progress != progress;
}
