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
    
    // Save blocked apps preference
    FocusSessionService.saveDefaultBlockedApps(_tempSelectedApps);
    
    // Start session
    state.startSession(
      type: _selectedType,
      blockedApps: _tempSelectedApps,
    );
    
    // Open premium full-screen timer
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8F5FF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Focus Session',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.history,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _showSessionHistory,
            tooltip: 'History',
          ),
        ],
      ),
      body: Consumer<FocusSessionState>(
        builder: (context, state, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Session counter
                _buildSessionCounter(state, isDark),
                const SizedBox(height: 24),

                // Timer widget
                Center(
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
                const SizedBox(height: 32),

                // Session type selector (only when idle)
                if (state.isIdle) ...[
                  SessionTypeSelector(
                    selectedType: _selectedType,
                    enabled: state.isIdle,
                    onChanged: (type) => setState(() => _selectedType = type),
                  ),
                  const SizedBox(height: 24),

                  // Blocked apps section
                  _buildBlockedAppsSection(state, isDark),
                  const SizedBox(height: 24),
                ],

                // Active session info
                if (state.isActive || state.isPaused) ...[
                  _buildActiveSessionInfo(state, isDark),
                  const SizedBox(height: 24),
                ],

                // Today's stats
                _buildTodaysStats(state, isDark),
                const SizedBox(height: 24),

                // Session history
                _buildSessionHistoryPreview(state, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCounter(FocusSessionState state, bool isDark) {
    return Column(
      children: [
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

  Widget _buildBlockedAppsSection(FocusSessionState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showBlockedAppsSelector)
          BlockedAppsSummary(
            blockedApps: _tempSelectedApps,
            onEdit: () => setState(() => _showBlockedAppsSelector = true),
          )
        else
          Column(
            children: [
              BlockedAppsSelector(
                selectedApps: _tempSelectedApps,
                onSelectionChanged: (apps) {
                  setState(() {
                    _tempSelectedApps = apps;
                  });
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showBlockedAppsSelector = false),
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: Text(
                    'Done',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActiveSessionInfo(FocusSessionState state, bool isDark) {
    if (state.currentSession == null) return const SizedBox.shrink();

    final session = state.currentSession!;
    final blockedCount = session.blockedApps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  state.isPaused ? LucideIcons.pause : LucideIcons.flame,
                  color: const Color(0xFF7C3AED),
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
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      blockedCount > 0
                          ? '$blockedCount apps blocked'
                          : 'No apps blocked',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.blockedApps.take(5).map((app) {
                final displayName = _getAppDisplayName(app);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTodaysStats(FocusSessionState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart2,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Progress',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Sessions',
                  '${state.sessionsCompletedToday}',
                  LucideIcons.target,
                  const Color(0xFF7C3AED),
                  isDark,
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
                ),
              ),
            ],
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
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
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
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistoryPreview(FocusSessionState state, bool isDark) {
    final todaysSessions = state.todaysSessions.reversed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
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
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recent Sessions',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (state.todaysSessions.isNotEmpty)
                TextButton(
                  onPressed: _showSessionHistory,
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (todaysSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 32,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions yet today',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    Text(
                      'Start your first focus session!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todaysSessions.map((session) => _buildSessionHistoryItem(session, isDark)),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildSessionHistoryItem(FocusSessionHistory session, bool isDark) {
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

    final timeStr = '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    session.formattedDuration,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
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
                    color: isDark ? Colors.white54 : Colors.black54,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
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
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
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
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.todaysSessions.length} today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.todaysSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sessions today',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: isDark ? Colors.white54 : Colors.black54,
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
                            final session = state.todaysSessions.reversed.toList()[index];
                            return _buildSessionHistoryItem(session, isDark);
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
    // Extract app name from package name
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      return parts.last.substring(0, 1).toUpperCase() + parts.last.substring(1);
    }
    return packageName;
  }
}
