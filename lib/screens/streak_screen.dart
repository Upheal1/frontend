import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/streak_model.dart';
import '../services/streak_service.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';
import '../widgets/streak/streak_freeze_dialog.dart';
import '../widgets/streak/streak_celebration.dart';

const Color _fireA = Color(0xFFFFB23E);
const Color _fireB = Color(0xFFFF7A45);
const Color _fireC = Color(0xFFFF4D6D);
const LinearGradient _fireGradient = LinearGradient(
  colors: [_fireA, _fireB, _fireC],
);
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  bool _showCelebration = false;
  StreakMilestone? _celebratingMilestone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCelebrations();
    });
  }

  void _checkForCelebrations() {
    final streakState = context.read<StreakState>();
    final unlockedMilestones = streakState.milestones
        .where((m) => m.isUnlocked && m.daysRequired == streakState.currentStreak)
        .toList();

    if (unlockedMilestones.isNotEmpty) {
      setState(() {
        _showCelebration = true;
        _celebratingMilestone = unlockedMilestones.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;
    final streakState = context.watch<StreakState>();

    return UpHealScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildHeader(streakState, tokens),
                SliverToBoxAdapter(child: _buildHeroCard(streakState, tokens)),
                SliverToBoxAdapter(child: _buildWeekCard(streakState, tokens)),
                SliverToBoxAdapter(child: _buildStatRow(streakState, tokens)),
                SliverToBoxAdapter(child: _buildFreezeCard(streakState, tokens)),
                SliverToBoxAdapter(child: _buildMilestonesSection(streakState, tokens)),
                SliverToBoxAdapter(child: SizedBox(height: tokens.screenPadding)),
              ],
            ),
          ),
          if (_showCelebration && _celebratingMilestone != null)
            StreakCelebration(
              milestone: _celebratingMilestone!,
              onDismiss: () => setState(() {
                _showCelebration = false;
                _celebratingMilestone = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(StreakState streakState, UpHealHomeTheme tokens) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, tokens.space8, tokens.space12, 0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: tokens.primaryText),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Back',
            ),
            Text(
              'My Streak',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showFreezeDialog(context, streakState),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: tokens.space8, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.cardFill,
                  borderRadius: BorderRadius.circular(tokens.pillRadius),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.snowflake, size: 14, color: const Color(0xFF6BCB8E)),
                    SizedBox(width: 4),
                    Text(
                      '${streakState.freezeTokens}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(StreakState streakState, UpHealHomeTheme tokens) {
    final streak = streakState.currentStreak;
    final nextMs = streakState.nextMilestone;
    final progress = nextMs != null
        ? (streak / nextMs.daysRequired).clamp(0.0, 1.0)
        : 1.0;
    final record = streakState.longestStreak;
    final daysToBeat = record > streak ? record - streak : 0;
    final motivMsg = daysToBeat > 0
        ? '$daysToBeat day${daysToBeat > 1 ? 's' : ''} to beat your record'
        : streak >= 365
            ? 'Incredible! A full year!'
            : streak >= 180
                ? 'Half a year strong! Keep going!'
                : streak >= 90
                    ? 'Quarter champion! Almost half a year!'
                    : streak >= 30
                        ? 'A whole month! You\u2019re on fire!'
                        : streak >= 14
                            ? 'Two weeks strong! Building the habit!'
                            : streak >= 7
                                ? 'One week! Keep the momentum!'
                                : 'Every day counts. Keep going!';

    return Container(
      margin: EdgeInsets.all(tokens.screenPadding),
      padding: EdgeInsets.all(tokens.space20),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _fireA.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 172,
                height: 172,
                child: CustomPaint(
                  painter: _FireRingPainter(progress: progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\uD83D\uDD25', style: TextStyle(fontSize: 28)),
                        SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => _fireGradient.createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            '$streak',
                            style: GoogleFonts.inter(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                        Text(
                          'DAY STREAK',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tokens.faintText,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space12),
          Text(
            motivMsg,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: tokens.secondaryText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(StreakState streakState, UpHealHomeTheme tokens) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      days.add(weekStart.add(Duration(days: i)));
    }

    int activeCount = 0;

    return Container(
      margin: EdgeInsets.fromLTRB(tokens.screenPadding, 0, tokens.screenPadding, tokens.space12),
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week \u00b7 0 of 7 active',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.secondaryText,
            ),
          ),
          SizedBox(height: tokens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 7; i++) ...[
                _buildDayCell(days[i], streakState, tokens, refActive: (v) => activeCount += v ? 1 : 0),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date, StreakState streakState, UpHealHomeTheme tokens, {required Function(bool) refActive}) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final label = dayLabels[date.weekday - 1];
    final isToday = _isSameDay(date, DateTime.now());
    final dayData = streakState.getStreakDay(date);
    final isCompleted = dayData?.isCompleted ?? false;
    final isFrozen = dayData?.completedActivities.contains('streak_freeze') ?? false;

    if (isCompleted) refActive(true);

    Widget cell;

    if (isCompleted && isFrozen) {
      cell = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A5C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(LucideIcons.snowflake, size: 16, color: const Color(0xFF6BCB8E)),
        ),
      );
    } else if (isCompleted) {
      cell = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: _fireGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('\uD83D\uDD25', style: TextStyle(fontSize: 14)),
        ),
      );
    } else if (isToday) {
      cell = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8A6CF6), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A6CF6),
            ),
          ),
        ),
      );
    } else {
      cell = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: tokens.trackColor,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.faintText,
            ),
          ),
        ),
      );
    }

    return cell;
  }

  Widget _buildStatRow(StreakState streakState, UpHealHomeTheme tokens) {
    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.screenPadding, 0, tokens.screenPadding, tokens.space12),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('\uD83C\uDFC6', '${streakState.longestStreak}', 'Longest streak', tokens)),
          SizedBox(width: tokens.space12),
          Expanded(child: _buildStatCard('\uD83D\uDCC5', '${streakState.totalDaysActive}', 'Total active days', tokens)),
          SizedBox(width: tokens.space12),
          Expanded(child: _buildStatCard('\u2744\uFE0F', '${streakState.freezeTokens}', 'Freezes left', tokens)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, UpHealHomeTheme tokens) {
    return AppCard(
      padding: EdgeInsets.symmetric(vertical: tokens.space12, horizontal: tokens.space12),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          SizedBox(height: tokens.space8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: tokens.faintText,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeCard(StreakState streakState, UpHealHomeTheme tokens) {
    return Container(
      margin: EdgeInsets.fromLTRB(tokens.screenPadding, 0, tokens.screenPadding, tokens.space12),
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(LucideIcons.snowflake, size: 20, color: const Color(0xFF6BCB8E)),
            ),
          ),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Freeze${streakState.freezeTokens > 0 ? ' active' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.primaryText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  streakState.freezeTokens > 0
                      ? 'Protects your streak on a missed day'
                      : 'Earn freezes through streaks and challenges',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tokens.faintText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.space8),
          GestureDetector(
            onTap: () => _showFreezeDialog(context, streakState),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: tokens.space12, vertical: tokens.space8),
              decoration: BoxDecoration(
                gradient: UpHealHomeTheme.sharedAccentGradient,
                borderRadius: BorderRadius.circular(tokens.pillRadius),
              ),
              child: Text(
                'Manage',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(StreakState streakState, UpHealHomeTheme tokens) {
    final allMilestones = StreakMilestone.allMilestones;
    final streak = streakState.currentStreak;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: tokens.space12),
            child: Text(
              'Milestones',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
              ),
            ),
          ),
          ...allMilestones.map((m) => _buildMilestoneRow(m, streak, streakState, tokens)),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(StreakMilestone m, int streak, StreakState streakState, UpHealHomeTheme tokens) {
    final isUnlocked = m.isUnlocked;
    final isNext = !isUnlocked && (streakState.nextMilestone?.daysRequired == m.daysRequired);
    final progress = isUnlocked ? 1.0 : (streak / m.daysRequired).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: tokens.space8),
      padding: EdgeInsets.all(tokens.space12),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNext
              ? const Color(0xFF8A6CF6)
              : tokens.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isUnlocked
                  ? const Color(0x33FFB23E)
                  : isNext
                      ? tokens.quickGroupsChip
                      : tokens.trackColor,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(m.emoji, style: TextStyle(fontSize: 20))
                  : isNext
                      ? Icon(LucideIcons.arrowRight, size: 18, color: tokens.quickGroupsIcon)
                      : Icon(LucideIcons.lock, size: 16, color: tokens.faintText),
            ),
          ),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.primaryText,
                      ),
                    ),
                    if (isUnlocked) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFB23E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Earned',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _fireA,
                          ),
                        ),
                      ),
                    ],
                    if (isNext) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.quickGroupsChip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Next',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tokens.quickGroupsIcon,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                if (!isUnlocked)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: tokens.trackColor,
                      color: isNext ? tokens.navActive : tokens.faintText,
                      minHeight: 4,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: tokens.space8),
          Text(
            '${m.daysRequired}d',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? _fireA : tokens.faintText,
            ),
          ),
        ],
      ),
    );
  }

  void _showFreezeDialog(BuildContext context, StreakState streakState) {
    StreakFreezeDialog.show(
      context,
      streakState,
      onUseFreeze: () {
        StreakService.useStreakFreeze();
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _FireRingPainter extends CustomPainter {
  final double progress;

  _FireRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    final gradientPaint = Paint()
      ..shader = _fireGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(_FireRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
