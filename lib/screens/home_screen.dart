import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/mission_model.dart';
import '../models/user_model.dart';
import '../models/streak_model.dart';
import '../constants/app_colors.dart';
import '../gamification/xp_config.dart';
import '../services/comeback_reward_service.dart';
import '../navigation/app_routes.dart';
import 'journal_screen.dart';
import 'notification_settings_screen.dart';
import 'roadmap_screen.dart';
import 'ai_chat_screen.dart';
import 'insights_screen.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/traveler_viewer.dart';
import '../avatar/models/avatar_unlock_config.dart';
import '../avatar/services/avatar_progression_provider.dart';
import '../features/community/ui/community_hub_screen.dart';
import '../design_system/tokens/design_tokens.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';

// Helper class to hold selected data for minimal rebuilds
class _HomeScreenData {
  final List<Mission> missions;
  final UserModel user;

  _HomeScreenData({required this.missions, required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HomeScreenData &&
          runtimeType == other.runtimeType &&
          missions == other.missions &&
          user == other.user;

  @override
  int get hashCode => missions.hashCode ^ user.hashCode;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Short-lived greeting at the top of Home (no avatar row — replaced old welcome card).
  bool _showWelcomeBanner = true;
  Timer? _welcomeBannerTimer;
  bool _showRotateHint = true;

  @override
  void initState() {
    super.initState();
    _welcomeBannerTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showWelcomeBanner = false);
    });
    Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showRotateHint = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final streakState = context.read<StreakState>();
      final user = context.read<UserModel>();

      final result = await ComebackRewardService.checkAndApply(
        streakState: streakState,
        user: user,
      );

      if (!mounted || !result.granted || result.message == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message!),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _welcomeBannerTimer?.cancel();
    _showRotateHint = false;
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLabel() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector to minimize rebuilds - only rebuild when missions or user data actually changes
    return Selector2<MissionsModel, UserModel, _HomeScreenData>(
      selector: (_, missions, user) => _HomeScreenData(
        missions: missions.missions,
        user: user,
      ),
      builder: (context, data, child) {
        final missions = data.missions;
        final user = data.user;

        return UpHealScaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, user)),
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: _showWelcomeBanner
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                          child: _buildEphemeralWelcomeBanner(context, user),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: _buildTravelerSection(context, user),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: _buildHomeJourneyPanel(context, user, missions),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────── HEADER ─────────────────────────────

  Widget _buildHeader(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DrawerMenuButton(
                iconColor: isDark ? Colors.white : tokens.primaryText,
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.sm,
                  color: isDark ? const Color(0xFF1C1F26) : tokens.cardFill,
                  boxShadow: context.appShadows.soft,
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.bell,
                    color: isDark ? Colors.white : tokens.primaryText,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                  tooltip: 'Notifications',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _dateLabel(),
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : tokens.faintText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_greeting()}, ${user.username}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.48,
              color: isDark ? Colors.white : tokens.primaryText,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── TRAVELER CARD ─────────────────────────────

  Widget _buildTravelerSection(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final avatarProgression = context.read<AvatarProgressionProvider>();
    final equippedSrc = avatarProgression.equippedSrc ?? AvatarUnlockConfig.all.first.src;
    final int currentJourneyDay = _journeyDay(user);
    final int nextLevelXp = XpConfig.totalXpForLevel(user.level + 1);
    final int xpToNextLevel = (nextLevelXp - user.xp).clamp(0, nextLevelXp);
    final String rankTitle = _travelerRankTitle(user.level);
    final double viewerHeight = MediaQuery.sizeOf(context).width >= 600 ? 340 : 248;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xl,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B69), Color(0xFF1C1526)],
              )
            : null,
        color: isDark ? null : tokens.cardFill,
        boxShadow: [
          BoxShadow(
            color: tokens.glowColor,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Your Traveler',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withValues(alpha: 0.94) : tokens.primaryText,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDBA2D),
                  borderRadius: AppRadius.pill,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFFDBA2D).withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      LucideIcons.star,
                      size: 14,
                      color: Color(0xFF7A4A00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LVL ${user.level}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7A4A00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: viewerHeight,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: <Color>[
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
                TravelerViewer(
                  assetPath: equippedSrc,
                  height: viewerHeight,
                  backgroundColor: Colors.transparent,
                ),
                if (_showRotateHint)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                            Icon(
                              LucideIcons.rotateCcw,
                              size: 14,
                              color: isDark ? Colors.white.withValues(alpha: 0.88) : Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Press & drag to rotate',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildTravelerMetric(
                  isDark: isDark,
                  icon: LucideIcons.trophy,
                  iconColor: const Color(0xFFF3C64C),
                  value: rankTitle,
                  label: 'Rank',
                ),
              ),
              Expanded(
                child: _buildTravelerMetric(
                  isDark: isDark,
                  value: 'Day $currentJourneyDay',
                  subvalue: 'of 90',
                  label: '',
                ),
              ),
              Expanded(
                child: _buildTravelerMetric(
                  isDark: isDark,
                  icon: LucideIcons.zap,
                  iconColor: const Color(0xFF72F0A8),
                  value: _formatCompactNumber(user.xp),
                  label: 'XP',
                  valueColor: isDark ? Colors.white : tokens.primaryText,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Level ${user.level} · $rankTitle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE7EEFF) : tokens.primaryText,
                  ),
                ),
              ),
              Text(
                '$xpToNextLevel XP to next',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withValues(alpha: 0.65) : tokens.faintText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: user.levelProgress,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.15) : tokens.trackColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelerMetric({
    required bool isDark,
    IconData? icon,
    Color? iconColor,
    required String value,
    required String label,
    String? subvalue,
    Color? valueColor,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    final tokens = Theme.of(context).upHealHome;
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: iconColor ?? (isDark ? Colors.white : tokens.faintText)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? (isDark ? Colors.white : tokens.primaryText),
                ),
              ),
            ),
          ],
        ),
        if (subvalue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subvalue,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.62) : tokens.faintText,
              ),
            ),
          )
        else
          const SizedBox(height: 2),
        if (label.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withValues(alpha: 0.62) : tokens.faintText,
            ),
          ),
      ],
    );
  }

  int _journeyDay(UserModel user) {
    final int elapsedDays = DateTime.now().difference(user.joinDate).inDays + 1;
    return elapsedDays.clamp(1, 90);
  }

  String _travelerRankTitle(int level) {
    if (level >= 15) return 'Luminary';
    if (level >= 11) return 'Pathfinder';
    if (level >= 7) return 'Trailblazer';
    if (level >= 4) return 'Wanderer';
    return 'Explorer';
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }

  Widget _buildHomeJourneyPanel(
    BuildContext context,
    UserModel user,
    List<Mission> missions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionHeader(
          context,
          icon: LucideIcons.target,
          label: "Today's Quest",
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTodayQuestCard(context, missions),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionHeader(
          context,
          icon: LucideIcons.zap,
          label: 'Quick Access',
          color: const Color(0xFFF97316),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildQuickAccessSection(context),
        const SizedBox(height: AppSpacing.xxl),
        _buildFocusSessionCard(context),
        const SizedBox(height: AppSpacing.lg),
        _buildContinueAscentCard(context, user),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionHeader(
          context,
          icon: LucideIcons.calendar,
          label: 'Upcoming',
          color: const Color(0xFFA78BFA),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildUpcomingCard(context, missions),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: isDark ? Colors.white : tokens.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayQuestCard(BuildContext context, List<Mission> missions) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final List<Mission> visibleMissions = missions.take(4).toList(growable: false);
    final int completedCount = visibleMissions.where((m) => m.completed).length;
    final double progress =
        visibleMissions.isEmpty ? 0 : completedCount / visibleMissions.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? const <BoxShadow>[]
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completedCount/${visibleMissions.length} done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : tokens.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : UpHealHomeTheme.sharedAccentGradient,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : null,
                  borderRadius: BorderRadius.circular(tokens.pillRadius),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.80)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Accent-gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.pillRadius),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : tokens.trackColor,
                    ),
                  ),
                  if (progress > 0)
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF5B7CFA),
                              Color(0xFF8A6CF6),
                              Color(0xFFB07BF5),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...visibleMissions.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildQuestTile(context, mission),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(BuildContext context, Mission mission) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    return InkWell(
      borderRadius: AppRadius.md,
      onTap: () => context.read<MissionsModel>().toggleMission(mission.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : mission.completed
                  ? const Color(0xFFE8F5E9)
                  : tokens.cardFill,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : mission.completed
                    ? const Color(0xFFC8E6C9)
                    : tokens.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: mission.completed
                    ? const Color(0xFF45D9A8)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : tokens.trackColor),
                shape: BoxShape.circle,
              ),
              child: mission.completed
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: mission.completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: isDark
                          ? Colors.white38
                          : const Color(0xFF94A3B8),
                      color: isDark
                          ? Colors.white.withValues(
                              alpha: mission.completed ? 0.45 : 0.90)
                          : mission.completed
                              ? tokens.faintText
                              : tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _missionDurationText(mission),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : tokens.faintText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // XP pill: accent gradient in light, tinted in dark
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: isDark ? null : UpHealHomeTheme.sharedAccentGradient,
                color: isDark
                    ? const Color(0xFFFDBA2D).withValues(alpha: 0.15)
                    : null,
                borderRadius: BorderRadius.circular(tokens.pillRadius),
              ),
              child: Text(
                '+${mission.xpReward} XP',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFEDB448)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessTile(
            context,
            icon: LucideIcons.bookOpen,
            label: 'Journal',
            tileBg: isDark ? tokens.quickJournal : tokens.quickJournal,
            chipColor: isDark ? tokens.quickJournalChip : tokens.quickJournalChip,
            iconColor: isDark ? tokens.quickJournalIcon : tokens.quickJournalIcon,
            labelColor: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : tokens.quickJournalLabel,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAccessTile(
            context,
            icon: LucideIcons.messageCircle,
            label: 'AI Coach',
            tileBg: isDark ? tokens.quickCoach : tokens.quickCoach,
            chipColor: isDark ? tokens.quickCoachChip : tokens.quickCoachChip,
            iconColor: isDark ? tokens.quickCoachIcon : tokens.quickCoachIcon,
            labelColor: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : tokens.quickCoachLabel,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAccessTile(
            context,
            icon: LucideIcons.barChart3,
            label: 'Insights',
            tileBg: isDark ? tokens.quickInsights : tokens.quickInsights,
            chipColor: isDark ? tokens.quickInsightsChip : tokens.quickInsightsChip,
            iconColor: isDark ? tokens.quickInsightsIcon : tokens.quickInsightsIcon,
            labelColor: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : tokens.quickInsightsLabel,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InsightsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAccessTile(
            context,
            icon: LucideIcons.users,
            label: 'Groups',
            tileBg: isDark ? tokens.quickGroups : tokens.quickGroups,
            chipColor: isDark ? tokens.quickGroupsChip : tokens.quickGroupsChip,
            iconColor: isDark ? tokens.quickGroupsIcon : tokens.quickGroupsIcon,
            labelColor: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : tokens.quickGroupsLabel,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommunityHubScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusSessionCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        const FocusSessionRoute().push<void>(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? null : tokens.cardFill,
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B69), Color(0xFF1A1035)],
                )
              : null,
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : tokens.cardBorder,
          ),
          boxShadow: tokens.cardShadow == null
              ? const <BoxShadow>[]
              : <BoxShadow>[tokens.cardShadow!],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                ),
                borderRadius: AppRadius.md,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.timer,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Session',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deep work without distractions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.60)
                          : tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                LucideIcons.arrowRight,
                size: 18,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.70)
                    : const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(
            begin: 0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildQuickAccessTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color tileBg,
    required Color chipColor,
    required Color iconColor,
    required Color labelColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final tokens = Theme.of(context).upHealHome;
    return InkWell(
      borderRadius: AppRadius.lg,
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: AppRadius.lg,
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.07))
              : Border.all(color: tokens.cardBorder),
          boxShadow: isDark
              ? null
              : (tokens.cardShadow == null
                  ? null
                  : <BoxShadow>[tokens.cardShadow!]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueAscentCard(BuildContext context, UserModel user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final int journeyDay = _journeyDay(user);
    return InkWell(
      borderRadius: AppRadius.lg,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RoadmapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: tokens.cardFill,
          borderRadius: AppRadius.lg,
          border: Border.all(color: tokens.cardBorder),
          boxShadow: tokens.cardShadow == null
              ? null
              : <BoxShadow>[tokens.cardShadow!],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF8A5CF0).withValues(alpha: 0.18)
                    : const Color(0xFFEFE9FD),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(LucideIcons.map,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF8A5CF0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Your Ascent',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: isDark ? Colors.white : tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Day $journeyDay · ${math.max(90 - journeyDay, 0)} days to summit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.55)
                          : tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : tokens.faintText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, List<Mission> missions) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final Mission? nextMission =
        missions.where((m) => !m.completed).isEmpty
            ? null
            : missions.firstWhere((m) => !m.completed);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: AppRadius.xl,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? null
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF8A5CF0).withValues(alpha: 0.20)
                  : const Color(0xFFEFE9FD),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(LucideIcons.users,
                size: 18,
                color: isDark
                    ? const Color(0xFFA78BFA)
                    : const Color(0xFF8A5CF0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextMission != null
                      ? 'Next Quest: ${nextMission.title}'
                      : 'Group Session: Anxiety Support',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nextMission != null ? nextMission.description : 'Tomorrow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : tokens.faintText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _missionDurationText(Mission mission) {
    final RegExp durationPattern = RegExp(r'(\d+)\s*(min|minute|minutes|m)');
    final String source = '${mission.title} ${mission.description}'.toLowerCase();
    final RegExpMatch? match = durationPattern.firstMatch(source);
    if (match != null) {
      return '${match.group(1)} min';
    }
    return mission.completed ? 'Completed' : 'Tap to complete';
  }

  /// Shown once per visit for [Duration(seconds: 10)] — replaces the old welcome card + avatar row.
  Widget _buildEphemeralWelcomeBanner(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: AppRadius.md,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? null
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: AppColors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, ${user.username}!',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ready to focus and grow?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
