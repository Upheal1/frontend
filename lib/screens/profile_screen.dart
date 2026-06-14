import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../avatar/models/avatar_config.dart';
import '../avatar/services/avatar_provider.dart';
import '../avatar/ui/avatar_widget.dart';
import '../constants/app_colors.dart';
import '../gamification/xp_config.dart';
import '../models/auth_model.dart';
import '../models/journal_model.dart';
import '../models/mission_model.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';
import '../navigation/app_routes.dart';
import '../services/challenge_service.dart';
import '../shared/theme/upheal_home_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.upHealHome;
    final authModel = context.watch<AuthModel>();
    final userModel = context.watch<UserModel>();
    final avatarProvider = context.watch<AvatarProvider>();
    final streakState = context.watch<StreakState>();
    final missionsModel = context.watch<MissionsModel>();
    final challengeService = context.watch<ChallengeService>();
    final journalModel = context.watch<JournalModel>();

    final username = authModel.userName ?? userModel.username;
    final currentStreak =
        math.max<int>(userModel.streakDays, streakState.currentStreak);
    final tasksCompleted =
        missionsModel.completedCount + challengeService.completedTotalCount;
    final journalEntries = journalModel.entries.length;
    final focusSessions = userModel.totalSessions;
    final moodCheckIns =
        math.max<int>(currentStreak, focusSessions > 0 ? 1 : 0);
    final nextLevelXp = XpConfig.totalXpForLevel(userModel.level + 1);

    final progressItems = <_ProgressSnapshotItemData>[
      _ProgressSnapshotItemData(
        label: 'Journal entries',
        current: journalEntries,
        goal: _nextGoal(journalEntries, min: 7, step: 7),
        color: const Color(0xFF7EA18D),
      ),
      _ProgressSnapshotItemData(
        label: 'Mindfulness sessions',
        current: focusSessions,
        goal: _nextGoal(focusSessions, min: 7, step: 7),
        color: const Color(0xFF6CA4D9),
      ),
      _ProgressSnapshotItemData(
        label: 'Tasks completed',
        current: tasksCompleted,
        goal: _nextGoal(tasksCompleted, min: 12, step: 6),
        color: const Color(0xFFD3A852),
      ),
      _ProgressSnapshotItemData(
        label: 'Mood check-ins',
        current: moodCheckIns,
        goal: _nextGoal(moodCheckIns, min: 7, step: 7),
        color: const Color(0xFFA487F7),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.pageGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeroCard(
                  username: username,
                  level: userModel.level,
                  rank: userModel.rank,
                  levelTitle: _levelTitle(userModel.level),
                  avatarAssetPath: avatarProvider.selectedAvatarAsset,
                  mood: avatarProvider.mood,
                  onOpenSettings: () => const SettingsRoute().push<void>(context),
                  onEditAvatar: () => const AvatarRoute().push<void>(context),
                ),
                const SizedBox(height: 14),
                _XpProgressCard(
                  xp: userModel.xp,
                  level: userModel.level,
                  nextLevelXp: nextLevelXp,
                  progress: userModel.levelProgress,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: LucideIcons.flame,
                        iconColor: const Color(0xFFF59E0B),
                        value: '$currentStreak',
                        label: 'Streak',
                        onTap: () => const StreakRoute().push<void>(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        icon: LucideIcons.star,
                        iconColor: const Color(0xFFEAB308),
                        value:
                            '$journalEntries/${_nextGoal(journalEntries, min: 7, step: 7)}',
                        label: 'Day',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        icon: LucideIcons.award,
                        iconColor: const Color(0xFF9B87F5),
                        value: '${userModel.badges}',
                        label: 'Badges',
                        onTap: () => const BadgesRoute().push<void>(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        icon: LucideIcons.users,
                        iconColor: const Color(0xFF5F95E7),
                        value: '#${userModel.rank}',
                        label: 'Rank',
                        onTap: () => const CommunityRoute().push<void>(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SegmentedProfileActions(
                  onBadgesTap: () => const BadgesRoute().push<void>(context),
                  onBoardTap: () => const CommunityRoute().push<void>(context),
                ),
                const SizedBox(height: 14),
                _ProgressSnapshotCard(items: progressItems),
                const SizedBox(height: 16),
                _QuickAccessCard(
                  icon: LucideIcons.bookOpen,
                  iconTint: const Color(0xFF87A98B),
                  title: 'My Journal Entries',
                  subtitle: '${_formatNumber(journalEntries)} entries written',
                  onTap: () => const JournalRoute().push<void>(context),
                ),
                const SizedBox(height: 12),
                _QuickAccessCard(
                  icon: LucideIcons.users,
                  iconTint: const Color(0xFF6E9DE4),
                  title: 'My Support Groups',
                  subtitle: userModel.rank <= 10
                      ? 'You are ranked near the top this week'
                      : 'Check in with your community spaces',
                  onTap: () => const CommunityRoute().push<void>(context),
                ),
                const SizedBox(height: 12),
                _QuickAccessCard(
                  icon: LucideIcons.sparkles,
                  iconTint: const Color(0xFFD4A65A),
                  title: 'Book a Session',
                  subtitle: 'AI therapist support is available now',
                  onTap: () => const AiChatRoute().push<void>(context),
                ),
                const SizedBox(height: 12),
                _QuickAccessCard(
                  icon: LucideIcons.personStanding,
                  iconTint: const Color(0xFF9B87F5),
                  title: 'Browse Avatars',
                  subtitle: 'Explore the 3D avatars available for your profile',
                  onTap: () => const AvatarRoute().push<void>(context),
                ),
                const SizedBox(height: 18),
                _LogoutButton(
                  onLogout: () => _confirmLogout(context, authModel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    AuthModel authModel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authModel.logout();
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.username,
    required this.level,
    required this.rank,
    required this.levelTitle,
    required this.avatarAssetPath,
    required this.mood,
    required this.onOpenSettings,
    required this.onEditAvatar,
  });

  final String username;
  final int level;
  final int rank;
  final String levelTitle;
  final String avatarAssetPath;
  final String mood;
  final VoidCallback onOpenSettings;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF7C5CF5),
            const Color(0xFF6A4BE8),
            const Color(0xFF8A6CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF6A4BE8).withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarTile(
            avatarAssetPath: avatarAssetPath,
            mood: mood,
            onEditAvatar: onEditAvatar,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'LVL $level',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      levelTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rank <= 10
                      ? 'You are building steady momentum this week.'
                      : 'Keep showing up. Your progress is compounding.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onOpenSettings,
              icon: const Icon(
                LucideIcons.settings2,
                size: 19,
                color: Colors.white,
              ),
              tooltip: 'Open settings',
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatarAssetPath,
    required this.mood,
    required this.onEditAvatar,
  });

  final String avatarAssetPath;
  final String mood;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: UpHealHomeTheme.sharedAccentGradient,
          ),
          alignment: Alignment.center,
          child: AvatarWidget(
            config: AvatarConfig(
              skin: 'skin_1',
              hair: 'hair_1',
              outfit: 'outfit_1',
            ),
            mood: mood,
            size: 54,
            avatarAssetPath: avatarAssetPath,
            bubbleText: '',
            showBubble: false,
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEditAvatar,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  LucideIcons.pencil,
                  size: 13,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _XpProgressCard extends StatelessWidget {
  const _XpProgressCard({
    required this.xp,
    required this.level,
    required this.nextLevelXp,
    required this.progress,
  });

  final int xp;
  final int level;
  final int nextLevelXp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return _SoftSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_formatNumber(xp)} XP',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: tokens.primaryText,
                  letterSpacing: -0.7,
                ),
              ),
              const Spacer(),
              Text(
                'Level ${level + 1} at ${_formatNumber(nextLevelXp)} XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.faintText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: tokens.trackColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8A6CF6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatefulWidget {
  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_SummaryTile> createState() => _SummaryTileState();
}

class _SummaryTileState extends State<_SummaryTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final child = _SoftSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Icon(widget.icon, size: 15, color: widget.iconColor),
          const SizedBox(height: 8),
          Text(
            widget.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).upHealHome.primaryText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).upHealHome.secondaryText,
            ),
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return child;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedProfileActions extends StatelessWidget {
  const _SegmentedProfileActions({
    required this.onBadgesTap,
    required this.onBoardTap,
  });

  final VoidCallback onBadgesTap;
  final VoidCallback onBoardTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? tokens.cardFill : tokens.cardFill.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _SegmentChip(
              icon: LucideIcons.scrollText,
              label: 'Stats',
              isSelected: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentChip(
              icon: LucideIcons.medal,
              label: 'Badges',
              onTap: onBadgesTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentChip(
              icon: LucideIcons.trophy,
              label: 'Board',
              onTap: onBoardTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected ? tokens.accentGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 13,
            color: isSelected
                ? Colors.white
                : tokens.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : tokens.secondaryText,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _ProgressSnapshotCard extends StatelessWidget {
  const _ProgressSnapshotCard({required this.items});

  final List<_ProgressSnapshotItemData> items;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return _SoftSurface(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ProgressSnapshotRow(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          Text(
            'Your weekly wellness snapshot updates as you journal, reflect, and finish tasks.',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tokens.faintText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSnapshotRow extends StatelessWidget {
  const _ProgressSnapshotRow({required this.item});

  final _ProgressSnapshotItemData item;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final progress =
        item.goal <= 0 ? 0.0 : (item.current / item.goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.secondaryText,
                ),
              ),
            ),
            Text(
              '${item.current}/${item.goal}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tokens.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: tokens.trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconTint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        onTap: onTap,
        child: _SoftSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconTint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconTint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: tokens.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: tokens.faintText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: Icon(
          LucideIcons.logOut,
          size: 18,
          color: tokens.faintText,
        ),
        label: Text(
          'Log out',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: tokens.faintText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.tileRadius),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _SoftSurface extends StatelessWidget {
  const _SoftSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.cardFill,
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

class _ProgressSnapshotItemData {
  const _ProgressSnapshotItemData({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final int current;
  final int goal;
  final Color color;
}

int _nextGoal(int value, {required int min, required int step}) {
  final baseline = math.max(value + 1, min);
  return ((baseline + step - 1) ~/ step) * step;
}

String _formatNumber(int value) {
  final digits = value.abs().toString();
  final parts = <String>[];

  for (var end = digits.length; end > 0; end -= 3) {
    final start = math.max(0, end - 3);
    parts.insert(0, digits.substring(start, end));
  }

  final joined = parts.join(',');
  return value < 0 ? '-$joined' : joined;
}

String _levelTitle(int level) {
  if (level >= 25) return 'Guiding Light';
  if (level >= 18) return 'Momentum Keeper';
  if (level >= 10) return 'Trail Blazer';
  if (level >= 5) return 'Steady Builder';
  return 'New Explorer';
}
