import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../models/streak_model.dart';
import '../services/streak_service.dart';
import '../constants/app_colors.dart';
import '../navigation/navigation_helpers.dart';
import '../widgets/streak/streak_calendar.dart';
import '../widgets/streak/streak_stats_card.dart';
import '../widgets/streak/streak_milestone_card.dart';
import '../widgets/streak/streak_freeze_dialog.dart';
import '../widgets/streak/streak_celebration.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showCelebration = false;
  StreakMilestone? _celebratingMilestone;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Check for new milestones to celebrate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCelebrations();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkForCelebrations() {
    final streakState = context.read<StreakState>();
    // Check if there's a newly unlocked milestone to celebrate
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => safeGoBack(context),
          tooltip: 'Back',
        ),
        title: Text(
          'My Streak',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<StreakState>(
            builder: (context, streakState, _) {
              return StreakFreezeIndicator(
                freezeTokens: streakState.freezeTokens,
                onTap: () => _showFreezeDialog(context, streakState),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Consumer2<UserModel, StreakState>(
            builder: (context, userModel, streakState, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak Header Card with pulse animation
                    _buildStreakHeaderCard(context, userModel, streakState),
                    const SizedBox(height: 24),

                    // Today's Activities
                    _buildTodayActivities(context, streakState),
                    const SizedBox(height: 24),

                    // Streak Stats Card
                    StreakStatsCard(streakState: streakState),
                    const SizedBox(height: 24),

                    // Milestones Section
                    StreakMilestonesList(
                      milestones: StreakMilestone.allMilestones,
                      currentStreak: streakState.currentStreak,
                      onMilestoneTap: (milestone) => _showMilestoneDetails(context, milestone, streakState),
                    ),
                    const SizedBox(height: 24),

                    // Streak Calendar
                    StreakCalendar(streakState: streakState),
                    const SizedBox(height: 24),

                    // Tips Section
                    _buildTipsSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
          
          // Celebration overlay
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

  void _showFreezeDialog(BuildContext context, StreakState streakState) {
    StreakFreezeDialog.show(
      context,
      streakState,
      onUseFreeze: () {
        StreakService.useStreakFreeze();
      },
    );
  }

  void _showMilestoneDetails(BuildContext context, StreakMilestone milestone, StreakState streakState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = streakState.currentStreak >= milestone.daysRequired;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              milestone.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              milestone.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              milestone.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isUnlocked
                    ? const Color(0xFF4CAF50).withOpacity(0.2)
                    : const Color(0xFFFF6B35).withOpacity(0.2),
              ),
              child: Text(
                isUnlocked
                    ? '✓ Unlocked!'
                    : '${milestone.daysRequired - streakState.currentStreak} days to unlock',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6B35),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${milestone.xpReward} XP Reward',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeaderCard(BuildContext context, UserModel userModel, StreakState streakState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = streakState.currentStreak > 0 ? streakState.currentStreak : userModel.streakDays;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFFFF6B35).withOpacity(0.3),
                      const Color(0xFFFF6B35).withOpacity(0.1),
                    ]
                  : [
                      const Color(0xFFFF6B35).withOpacity(0.2),
                      const Color(0xFFFF6B35).withOpacity(0.05),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFF6B35).withOpacity(0.3)
                  : const Color(0xFFFF6B35).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.1 + _pulseController.value * 0.1),
                blurRadius: 20 + _pulseController.value * 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated flame icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.flame,
                  color: Colors.white,
                  size: 50,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
              const SizedBox(height: 20),
              // Streak count
              Text(
                '$currentStreak',
                style: GoogleFonts.inter(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ).animate().fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              Text(
                currentStreak == 1 ? 'Day Streak' : 'Days Streak',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // XP Multiplier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${streakState.streakMultiplier.toStringAsFixed(1)}x XP Bonus',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
              const SizedBox(height: 16),
              Text(
                _getStreakMessage(currentStreak),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTodayActivities(BuildContext context, StreakState streakState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayActivities = streakState.todayActivities;
    final isTodayCompleted = streakState.isTodayCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTodayCompleted
              ? [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF4CAF50).withOpacity(0.1),
                ]
              : isDark
                  ? [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
                      AppColors.textPrimary.withOpacity(0.05),
                      AppColors.textPrimary.withOpacity(0.02),
                    ],
        ),
        border: Border.all(
          color: isTodayCompleted
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : isDark
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      isTodayCompleted ? LucideIcons.checkCircle : LucideIcons.target,
                      color: isTodayCompleted
                          ? const Color(0xFF4CAF50)
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Today\'s Progress',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTodayCompleted)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF4CAF50),
                    ),
                    child: Text(
                      '✓ Streak Secured!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayActivities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.sunrise,
                    size: 40,
                    color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete any activity to secure today\'s streak!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: todayActivities
                  .map((activity) => _buildActivityChip(context, activity, isDark))
                  .toList(),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityChip(BuildContext context, StreakActivityType activity, bool isDark) {
    final activityInfo = _getActivityInfo(activity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: activityInfo.color.withOpacity(0.2),
        border: Border.all(
          color: activityInfo.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activityInfo.icon,
            size: 16,
            color: activityInfo.color,
          ),
          const SizedBox(width: 6),
          Text(
            activityInfo.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activityInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  _ActivityInfo _getActivityInfo(StreakActivityType activity) {
    switch (activity) {
      case StreakActivityType.journaling:
        return _ActivityInfo('Journal', LucideIcons.bookOpen, const Color(0xFF9C27B0));
      case StreakActivityType.assessment:
        return _ActivityInfo('Assessment', LucideIcons.clipboardCheck, const Color(0xFF2196F3));
      case StreakActivityType.challenge:
        return _ActivityInfo('Challenge', LucideIcons.swords, const Color(0xFFFF9800));
      case StreakActivityType.sleepTracking:
        return _ActivityInfo('Sleep', LucideIcons.moon, const Color(0xFF673AB7));
      case StreakActivityType.stepGoal:
        return _ActivityInfo('Steps', LucideIcons.footprints, const Color(0xFF4CAF50));
      case StreakActivityType.focusSession:
        return _ActivityInfo('Focus', LucideIcons.target, const Color(0xFFE91E63));
      case StreakActivityType.meditation:
        return _ActivityInfo('Mindfulness', LucideIcons.brain, const Color(0xFF00BCD4));
      case StreakActivityType.socialEngagement:
        return _ActivityInfo('Community', LucideIcons.users, const Color(0xFF3F51B5));
      case StreakActivityType.miniGame:
        return _ActivityInfo('Game', LucideIcons.gamepad2, const Color(0xFFFFEB3B));
    }
  }

  Widget _buildTipsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  AppColors.textPrimary.withOpacity(0.05),
                  AppColors.textPrimary.withOpacity(0.02),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : AppColors.textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                color: isDark ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Keep Your Streak Going!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            context,
            'Complete daily missions to maintain your streak',
            LucideIcons.target,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            context,
            'Track your steps and sleep to earn bonus XP',
            LucideIcons.footprints,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            context,
            'Journal daily to reflect and grow',
            LucideIcons.bookOpen,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            context,
            'Use freeze tokens when you need a break',
            LucideIcons.snowflake,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTipItem(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6B35),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _getStreakMessage(int streakDays) {
    if (streakDays == 0) {
      return 'Start your journey today! Complete missions to build your streak.';
    } else if (streakDays < 7) {
      return 'Great start! Keep going to reach your first week milestone.';
    } else if (streakDays < 14) {
      return '🔥 One week strong! You\'re building a powerful habit.';
    } else if (streakDays < 30) {
      return '⚔️ Week Warrior! Push through to Month Master status.';
    } else if (streakDays < 90) {
      return '🏆 Month Master! You\'re in the top 10% of users.';
    } else if (streakDays < 180) {
      return '🌟 Quarter Champion! Incredible dedication.';
    } else if (streakDays < 365) {
      return '💪 Half Year Hero! Legend status awaits.';
    } else {
      return '👑 YEAR LEGEND! You are truly unstoppable!';
    }
  }
}

/// Helper class for activity info
class _ActivityInfo {
  final String label;
  final IconData icon;
  final Color color;

  _ActivityInfo(this.label, this.icon, this.color);
}

