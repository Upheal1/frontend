import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../design_system/tokens/design_tokens.dart';
import '../../../navigation/app_routes.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import '../state/community_notifiers.dart';
import 'community_decor.dart';
import 'community_groups_tab.dart';
import 'feed_tab.dart';

/// Tabs: real-time feed and groups / chat.
class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => GroupsNotifier(ctx.read<CommunityRepository>()),
        ),
      ],
      child: const _CommunityHubShell(),
    );
  }
}

class _CommunityHubShell extends StatefulWidget {
  const _CommunityHubShell();

  @override
  State<_CommunityHubShell> createState() => _CommunityHubShellState();
}

class _CommunityHubShellState extends State<_CommunityHubShell>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GroupsNotifier>().connect();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = _tab.index;
    final AppResponsiveInfo responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(gradient: CommunityDecor.calmBackdrop(context)),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: const _CommunityDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _CommunityHeader(
                tab: _tab,
                responsive: responsive,
              ),
            ),
          ],
          body: AppPageContainer(
            padding: EdgeInsets.zero,
            maxContentWidth: responsive.isTabletOrWider ? 1080 : double.infinity,
            expand: true,
            child: TabBarView(
              controller: _tab,
              children: const [
                FeedTab(),
                CommunityGroupsTab(),
              ],
            ),
          ),
        ),
        floatingActionButton: _GradientFab(
          idx: idx,
          onFeedTap: () => FeedTab.openCompose(context),
          onGroupTap: () => CommunityGroupsTab.openCreateSheet(context),
        ),
      ),
    );
  }
}

// ── Compact premium header ────────────────────────────────────────────────────

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.tab,
    required this.responsive,
  });
  final TabController tab;
  final AppResponsiveInfo responsive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AppPageContainer(
          padding: EdgeInsets.fromLTRB(
            responsive.space(AppSpacing.lg),
            responsive.space(AppSpacing.sm),
            responsive.space(AppSpacing.lg),
            responsive.space(AppSpacing.lg),
          ),
          maxContentWidth: responsive.isTabletOrWider ? 1080 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Community',
                            style: GoogleFonts.inter(
                              fontSize: responsive.isTabletOrWider ? 28 : 24,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'A safe space for your journey',
                            style: GoogleFonts.inter(
                              fontSize: responsive.isTabletOrWider ? 13 : 13,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // + Share button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      FeedTab.openCompose(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.space(AppSpacing.lg)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.isTabletOrWider ? 420 : double.infinity,
                ),
                child: _SegmentedTabBar(controller: tab),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Animated segmented tab bar ────────────────────────────────────────────────

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final AppResponsiveInfo responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF0F1F5);
    final selectedColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: selectedColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        labelColor: isDark ? Colors.white : const Color(0xFF111827),
        unselectedLabelColor:
            isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageCircle, size: 15),
                SizedBox(width: 6),
                Text('Feed'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 15),
                SizedBox(width: 6),
                Text('Groups'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient pill FAB ─────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  const _GradientFab({
    required this.idx,
    required this.onFeedTap,
    required this.onGroupTap,
  });

  final int idx;
  final VoidCallback onFeedTap;
  final VoidCallback onGroupTap;

  @override
  Widget build(BuildContext context) {
    final String label = idx == 0 ? 'Post' : 'New group';
    final IconData icon = idx == 0 ? LucideIcons.pencil : LucideIcons.users;
    final String semanticLabel = idx == 0
        ? 'Create a new community post'
        : 'Create a new community group';
    final AppResponsiveInfo responsive = context.responsive;

    return Semantics(
      button: true,
      label: semanticLabel,
      hint: idx == 0 ? 'Opens the post composer' : 'Opens the group creation sheet',
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            canRequestFocus: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              if (idx == 0) {
                onFeedTap();
              } else {
                onGroupTap();
              }
            },
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.space(
                  AppSpacing.xl,
                  minScale: 1,
                  maxScale: 1.15,
                ),
                vertical: responsive.space(
                  AppSpacing.md,
                  minScale: 1,
                  maxScale: 1.1,
                ),
              ),
              decoration: BoxDecoration(
                gradient: CommunityDecor.fabGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: CommunityDecor.lavender.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: responsive.space(AppSpacing.sm)),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey(idx))
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.25, end: 0, duration: 250.ms, curve: Curves.easeOut)
        .shimmer(
          delay: 1000.ms,
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.15),
        );
  }
}

// ── Community Drawer ──────────────────────────────────────────────────────────

class _CommunityDrawer extends StatelessWidget {
  const _CommunityDrawer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : Colors.white;
    final surface = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white60 : const Color(0xFF475569);

    return Drawer(
      backgroundColor: bg,
      width: MediaQuery.of(context).size.width * 0.80,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.18),
                    AppColors.teal.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.purple.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.teal],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.users,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'A safe space to share & grow',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x,
                        color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Community stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE9EBF0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCell(
                            label: 'Posts',
                            value: '2.4k',
                            icon: LucideIcons.fileText,
                            isDark: isDark),
                        _VerticalDivider(isDark: isDark),
                        _StatCell(
                            label: 'Members',
                            value: '1.1k',
                            icon: LucideIcons.users,
                            isDark: isDark),
                        _VerticalDivider(isDark: isDark),
                        _StatCell(
                            label: 'Active',
                            value: '148',
                            icon: LucideIcons.zap,
                            isDark: isDark),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 280.ms),

                  const SizedBox(height: 20),
                  _SectionLabel(text: 'Browse Topics', isDark: isDark),
                  const SizedBox(height: 10),

                  // Tag chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCommunityTagPresets
                        .map((tag) => _TopicChip(
                              tag: tag,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  backgroundColor: AppColors.purple,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Text(
                                    'Showing #$tag posts',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ));
                              },
                            ))
                        .toList(),
                  ).animate().fadeIn(delay: 120.ms, duration: 280.ms),

                  const SizedBox(height: 20),
                  _SectionLabel(text: 'Quick Links', isDark: isDark),
                  const SizedBox(height: 8),

                  _DrawerTile(
                    icon: LucideIcons.pencil,
                    label: 'Write a Post',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      FeedTab.openCompose(context);
                    },
                  ).animate().fadeIn(delay: 150.ms, duration: 250.ms),

                  _DrawerTile(
                    icon: LucideIcons.users,
                    label: 'Create a Group',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      CommunityGroupsTab.openCreateSheet(context);
                    },
                  ).animate().fadeIn(delay: 170.ms, duration: 250.ms),

                  const SizedBox(height: 20),
                  _SectionLabel(text: 'Community', isDark: isDark),
                  const SizedBox(height: 8),

                  _DrawerTile(
                    icon: LucideIcons.bookOpen,
                    label: 'Community Guidelines',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      _showGuidelinesSheet(context, isDark);
                    },
                  ).animate().fadeIn(delay: 200.ms, duration: 250.ms),

                  _DrawerTile(
                    icon: LucideIcons.heart,
                    label: 'Be Kind & Supportive',
                    isDark: isDark,
                    subtle: true,
                    onTap: () => Navigator.of(context).pop(),
                  ).animate().fadeIn(delay: 220.ms, duration: 250.ms),

                  const SizedBox(height: 20),
                  _SectionLabel(text: 'Navigate', isDark: isDark),
                  const SizedBox(height: 8),

                  ..._appNavItems.map((item) => _DrawerTile(
                        icon: item.$1,
                        label: item.$2,
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          item.$3.go(context);
                        },
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 240 + _appNavItems.indexOf(item) * 20),
                            duration: 220.ms,
                          )),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck,
                      size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Safe, moderated space',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuidelinesSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13131F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : const Color(0xFFDDE1EA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.teal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.bookOpen,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Community Guidelines',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._guidelines.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(g.$1, size: 14, color: AppColors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.$2,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            g.$3,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static const List<(IconData, String, AppRouteData)> _appNavItems = <(IconData, String, AppRouteData)>[
    (LucideIcons.home, 'Home', HomeRoute()),
    (LucideIcons.target, 'Challenges', ChallengesRoute()),
    (LucideIcons.gamepad2, 'Mini Games', MiniGamesRoute()),
    (LucideIcons.barChart3, 'Analytics', AnalyticsRoute()),
    (LucideIcons.moon, 'Sleep Tracker', SleepTrackerRoute()),
    (LucideIcons.footprints, 'Step Tracker', StepTrackerRoute()),
    (LucideIcons.brain, 'My Results', MyAssessmentRoute()),
    (LucideIcons.bookOpen, 'Journaling', JournalRoute()),
    (LucideIcons.user, 'Profile', ProfileRoute()),
  ];

  static const _guidelines = [
    (
      LucideIcons.heart,
      'Be Kind',
      'Treat everyone with respect. Healthy debate is welcome, but personal attacks are not.'
    ),
    (
      LucideIcons.shieldCheck,
      'Stay Safe',
      'Do not share personal information. Your privacy matters.'
    ),
    (
      LucideIcons.messageSquare,
      'Share Authentically',
      'Be honest and genuine. This is a judgment-free zone.'
    ),
    (
      LucideIcons.flag,
      'Report Issues',
      'If you see harmful content, report it. Help keep this space safe for everyone.'
    ),
    (
      LucideIcons.sparkles,
      'Support Growth',
      'Celebrate each other\'s wins, big and small. Encouragement goes a long way.'
    ),
  ];
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.label,
      required this.value,
      required this.icon,
      required this.isDark});
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.purple),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE4E7EE),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.subtle = false,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: subtle ? 0.03 : 0.05)
              : (subtle
                  ? const Color(0xFFFFFFFF)
                  : AppColors.purple.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFECEEF4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: subtle
                  ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                  : AppColors.purple,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: subtle ? FontWeight.w500 : FontWeight.w600,
                color: subtle
                    ? (isDark ? Colors.white54 : const Color(0xFF64748B))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const Spacer(),
            if (!subtle)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark
                    ? Colors.white30
                    : const Color(0xFFBCC3D0),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip(
      {required this.tag, required this.isDark, required this.onTap});
  final String tag;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          '#$tag',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.purple,
          ),
        ),
      ),
    );
  }
}

