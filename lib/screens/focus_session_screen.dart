import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/focus_session_model.dart';
import '../models/hive/focus_session_history.dart';
import '../services/focus_session_service.dart';
import '../widgets/focus/session_timer_widget.dart';
import '../widgets/focus/blocked_apps_selector.dart';
import '../widgets/drawer_menu_button.dart';
import '../design_system/tokens/design_tokens.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';
import 'premium_focus_timer_screen.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  FocusSessionType _selectedType = FocusSessionType.focus;
  bool _showBlockedAppsSelector = false;
  List<String> _tempSelectedApps = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedApps();
  }

  void _loadBlockedApps() {
    final state = context.read<FocusSessionState>();
    _tempSelectedApps = List.from(state.defaultBlockedApps);
  }

  void _startSession() {
    final state = context.read<FocusSessionState>();
    FocusSessionService.saveDefaultBlockedApps(_tempSelectedApps);
    state.startSession(
      type: _selectedType,
      blockedApps: _tempSelectedApps,
    );
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PremiumFocusTimerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _pauseSession() {
    context.read<FocusSessionState>().pauseSession();
  }

  void _resumeSession() {
    context.read<FocusSessionState>().resumeSession();
  }

  void _stopSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F26)
            : Colors.white,
        title: Text(
          'End Session?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to end this focus session early?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(color: const Color(0xFF7C3AED)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FocusSessionState>().stopSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: Text(
              'End Session',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Consumer<FocusSessionState>(
      builder: (context, state, child) {
        return UpHealScaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, isDark, tokens)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildSessionCounter(state, isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Center(
                    child: SessionTimerWidget(
                      session: state.currentSession,
                      status: state.status,
                      selectedType: _selectedType,
                      onStart: _startSession,
                      onPause: _pauseSession,
                      onResume: _resumeSession,
                      onStop: _stopSession,
                    ),
                  ),
                ),
              ),
              if (state.isIdle) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                    child: _buildSectionHeader(
                      context,
                      icon: LucideIcons.clock,
                      label: 'Session Type',
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: SessionTypeSelector(
                      selectedType: _selectedType,
                      enabled: state.isIdle,
                      onChanged: (type) => setState(() => _selectedType = type),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                    child: _buildBlockedAppsSection(state, isDark, tokens),
                  ),
                ),
              ],
              if (state.isActive || state.isPaused) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                    child: _buildActiveSessionInfo(state, isDark, tokens),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                  child: _buildSectionHeader(
                    context,
                    icon: LucideIcons.barChart2,
                    label: "Today's Progress",
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: _buildTodaysStats(state, isDark, tokens),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                  child: _buildSectionHeader(
                    context,
                    icon: LucideIcons.history,
                    label: 'Recent Sessions',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
                  child: _buildSessionHistoryPreview(state, isDark, tokens),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UpHealHomeTheme tokens) {
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
                    LucideIcons.history,
                    color: isDark ? Colors.white : tokens.primaryText,
                    size: 20,
                  ),
                  onPressed: _showSessionHistory,
                  tooltip: 'History',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Focus Session',
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
            'Deep work without distractions',
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

  Widget _buildSessionCounter(FocusSessionState state, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Session ${state.currentSessionNumber} of ${state.totalSessionsInCycle}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(height: 8),
        SessionCounter(
          currentSession: state.currentSessionNumber,
          totalSessions: state.totalSessionsInCycle,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBlockedAppsSection(
      FocusSessionState state, bool isDark, UpHealHomeTheme tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showBlockedAppsSelector)
          BlockedAppsSummary(
            blockedApps: _tempSelectedApps,
            onEdit: () => setState(() => _showBlockedAppsSelector = true),
          )
        else
          Container(
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
              children: [
                BlockedAppsSelector(
                  selectedApps: _tempSelectedApps,
                  onSelectionChanged: (apps) {
                    setState(() => _tempSelectedApps = apps);
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showBlockedAppsSelector = false),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: Text(
                      'Done',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActiveSessionInfo(
      FocusSessionState state, bool isDark, UpHealHomeTheme tokens) {
    if (state.currentSession == null) return const SizedBox.shrink();

    final session = state.currentSession!;
    final blockedCount = session.blockedApps.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B69), Color(0xFF1A1035)],
              )
            : null,
        color: isDark ? null : tokens.cardFill,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                child: Icon(
                  state.isPaused ? LucideIcons.pause : LucideIcons.flame,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isPaused ? 'Session Paused' : 'Stay Focused!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : tokens.primaryText,
                      ),
                    ),
                    Text(
                      blockedCount > 0
                          ? '$blockedCount apps blocked'
                          : 'No apps blocked',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.60)
                            : tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).fade(
                        duration: 1.seconds,
                        begin: 0.3,
                        end: 1,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (blockedCount > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : tokens.dividerColor,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.blockedApps.take(5).map((app) {
                final displayName = _getAppDisplayName(app);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.ban,
                        size: 12,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (blockedCount > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${blockedCount - 5} more',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : tokens.faintText,
                  ),
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTodaysStats(
      FocusSessionState state, bool isDark, UpHealHomeTheme tokens) {
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Sessions',
              '${state.sessionsCompletedToday}',
              LucideIcons.target,
              const Color(0xFF7C3AED),
              isDark,
              tokens,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              'Focus Time',
              state.formattedTotalFocusTime,
              LucideIcons.clock,
              const Color(0xFF10B981),
              isDark,
              tokens,
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    UpHealHomeTheme tokens,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.sm,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : tokens.primaryText,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.50)
                      : tokens.faintText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHistoryPreview(
      FocusSessionState state, bool isDark, UpHealHomeTheme tokens) {
    final todaysSessions = state.todaysSessions.reversed.take(3).toList();

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
          if (state.todaysSessions.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showSessionHistory,
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          if (todaysSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 32,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.24)
                          : tokens.faintText,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions yet today',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : tokens.secondaryText,
                      ),
                    ),
                    Text(
                      'Start your first focus session!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.38)
                            : tokens.faintText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todaysSessions
                .map((session) => _buildSessionHistoryItem(session, isDark, tokens)),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildSessionHistoryItem(
      FocusSessionHistory session, bool isDark, UpHealHomeTheme tokens) {
    Color typeColor;
    IconData typeIcon;

    switch (session.type) {
      case FocusSessionType.focus:
        typeColor = const Color(0xFF7C3AED);
        typeIcon = LucideIcons.target;
        break;
      case FocusSessionType.shortBreak:
        typeColor = const Color(0xFF10B981);
        typeIcon = LucideIcons.coffee;
        break;
      case FocusSessionType.longBreak:
        typeColor = const Color(0xFF3B82F6);
        typeIcon = LucideIcons.palmtree;
        break;
    }

    final timeStr =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : tokens.cardFill,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : tokens.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.typeDisplayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : tokens.primaryText,
                    ),
                  ),
                  Text(
                    session.formattedDuration,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.50)
                          : tokens.faintText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : tokens.faintText,
                  ),
                ),
                if (session.completed)
                  Icon(
                    LucideIcons.checkCircle,
                    size: 14,
                    color: const Color(0xFF10B981),
                  )
                else
                  Icon(
                    LucideIcons.xCircle,
                    size: 14,
                    color: Colors.red.shade400,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionHistory() {
    final state = context.read<FocusSessionState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.24)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Session History',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : tokens.primaryText,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.todaysSessions.length} today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : tokens.faintText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tokens.dividerColor),
                Expanded(
                  child: state.todaysSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 48,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.24)
                                    : tokens.faintText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sessions today',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : tokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.todaysSessions.length,
                          itemBuilder: (context, index) {
                            final session =
                                state.todaysSessions.reversed.toList()[index];
                            return _buildSessionHistoryItem(
                                session, isDark, tokens);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getAppDisplayName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      return parts.last.substring(0, 1).toUpperCase() + parts.last.substring(1);
    }
    return packageName;
  }
}
