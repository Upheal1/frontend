import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../navigation/app_routes.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/rewards/xp_burst_overlay.dart';
import '../design_system/tokens/design_tokens.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';
import 'challenges/avatar_header.dart';
import 'challenges/challenge_card.dart';
import 'challenges/progress_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String? _toastText;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, service, _) {
        final daily = service.dailyChallenges;
        final weekly = service.weeklyChallenges;
        final special = service.specialChallenges;
        final active = service.activeChallenges;

        final completedToday = service.completedTodayCount;
        final totalXpAvailable = service.totalXpAvailable;

        final selectedList = _selectedTab == 0
            ? daily
            : _selectedTab == 1
                ? weekly
                : special;

        final todaysTotal = daily.length;
        final todaysCompleted = daily.where(_isCompletedToday).length;
        final completion =
            todaysTotal == 0 ? 0.0 : (todaysCompleted / todaysTotal);
        final xpEarnedToday = _xpEarnedToday([...daily, ...weekly, ...special]);

        return UpHealScaffold(
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, completedToday, totalXpAvailable),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AvatarHeader(
                        message: _motivationMessage(
                          completedToday: completedToday,
                          totalXpAvailable: totalXpAvailable,
                        ),
                        onAvatarTap: () =>
                            const AvatarRoute().push<void>(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      child: ProgressCard(
                        completion: completion,
                        xpEarnedToday: xpEarnedToday,
                        tasksCompleted: todaysCompleted,
                        tasksTotal: todaysTotal,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                      child: _PremiumTabBar(
                        selectedIndex: _selectedTab,
                        onSelected: _onTabSelected,
                        dailyCount: daily.length,
                        weeklyCount: weekly.length,
                        specialCount: special.length,
                      ),
                    ),
                  ),
                  if (active.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                        child: _buildSectionHeader(
                          context,
                          icon: LucideIcons.flame,
                          label: 'In progress',
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ),
                  if (active.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                        child: Column(
                          children: [
                            for (final c in active)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ChallengeCard(
                                  challenge: c,
                                  confettiController: _confettiController,
                                  showConfetti: false,
                                  onPrimaryAction: () =>
                                      _handlePrimaryAction(context, service, c),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                      child: _buildSectionHeader(
                        context,
                        icon: LucideIcons.swords,
                        label: _selectedTab == 0
                            ? 'Daily challenges'
                            : _selectedTab == 1
                                ? 'Weekly challenges'
                                : 'Special challenges',
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.02, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: selectedList.isEmpty
                            ? SizedBox(
                                key: const ValueKey('empty'),
                                height: 160,
                                child: Center(
                                  child: Text(
                                    'No challenges available · Check back soon',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.55)
                                          : Theme.of(context).upHealHome.faintText,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                key: ValueKey('list_$_selectedTab'),
                                children: [
                                  for (final c in selectedList)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: ChallengeCard(
                                        challenge: c,
                                        confettiController: _confettiController,
                                        showConfetti: false,
                                        onPrimaryAction: () =>
                                            _handlePrimaryAction(context, service, c),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_toastText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(child: _XpToast(text: _toastText!)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, int completedToday, int totalXpAvailable) {
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Challenges',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.48,
              color: isDark ? Colors.white : tokens.primaryText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$completedToday completed today · $totalXpAvailable XP available',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : tokens.faintText,
              height: 1.2,
            ),
          ),
        ],
      ),
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

  Future<void> _handlePrimaryAction(
    BuildContext context,
    ChallengeService service,
    ChallengeModel challenge,
  ) async {
    if (challenge.status == ChallengeStatus.available && !challenge.isExpired) {
      service.joinChallenge(challenge.id);
      _showToast('Started');
      return;
    }

    if (challenge.status == ChallengeStatus.active && !challenge.isExpired) {
      final willComplete =
          challenge.currentCount + 1 >= challenge.targetCount &&
              challenge.targetCount > 0;
      await service.incrementProgress(challenge.id, context);
      if (!mounted) return;

      if (willComplete) {
        _confettiController.play();
        _showToast('+${challenge.xpReward} XP');
        XpBurstOverlay.show(
          context,
          amount: challenge.xpReward,
          oldXp: 0,
          newXp: challenge.xpReward,
          xpNeeded: 0,
          level: 1,
        );
      } else {
        _showToast('+1 progress');
      }
    }
  }

  void _showToast(String text) {
    setState(() => _toastText = text);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _toastText = null);
    });
  }

  bool _isCompletedToday(ChallengeModel c) {
    final completedAt = c.completedAt;
    if (completedAt == null) return false;
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  int _xpEarnedToday(List<ChallengeModel> all) {
    return all
        .where(_isCompletedToday)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }

  String _motivationMessage({
    required int completedToday,
    required int totalXpAvailable,
  }) {
    if (completedToday == 0) return 'Let\u2019s win the first quest today.';
    if (totalXpAvailable == 0) return 'Perfect day. You cleared the board.';
    return 'Nice streak \u2014 $totalXpAvailable XP still waiting.';
  }
}

class _PremiumTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int dailyCount;
  final int weeklyCount;
  final int specialCount;

  const _PremiumTabBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.dailyCount,
    required this.weeklyCount,
    required this.specialCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final items = <({String label, IconData icon})>[
      (label: 'Daily', icon: LucideIcons.calendarDays),
      (label: 'Weekly', icon: LucideIcons.calendarRange),
      (label: 'Special', icon: LucideIcons.sparkles),
    ];
    final counts = [dailyCount, weeklyCount, specialCount];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : tokens.cardFill,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : tokens.cardBorder,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : (tokens.cardShadow == null
                ? null
                : [tokens.cardShadow!]),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: selectedIndex == i
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF7C3AED),
                              Color(0xFFB4AFFF),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: selectedIndex == i
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : tokens.faintText),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${items[i].label} (${counts[i]})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedIndex == i
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : tokens.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _XpToast extends StatelessWidget {
  final String text;

  const _XpToast({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.purple.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms)
        .moveY(begin: 6, end: 0, duration: 240.ms)
        .then()
        .fadeOut(duration: 250.ms);
  }
}
