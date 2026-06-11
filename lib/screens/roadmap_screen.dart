import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../models/upheal_roadmap.dart';
import '../services/roadmap_repository.dart';
import '../services/supabase_service.dart';
import '../services/upheal_api.dart';
import '../widgets/drawer_menu_button.dart';

const bool useMockRoadmap = String.fromEnvironment('USE_MOCK_ROADMAP', defaultValue: 'false') == 'true';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final RoadmapRepository _repo;

  RoadmapFullResponse? _roadmap;
  bool _loading = true;
  bool _generating = false;
  String? _error;
  int _selectedPhaseIndex = 0;

  static const _phases = ['Overview', 'Quick Wins', 'Ladder', 'Boss'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _phases.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _repo = RoadmapRepository(UphealApi(baseUrl: uphealBaseUrl));
    _loadRoadmap();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedPhaseIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadmap() async {
    final userId = SupabaseService.userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please sign in to view your roadmap.';
        });
      }
      return;
    }

    // DEBUG: Use mock data for UI testing
    if (useMockRoadmap) {
      if (mounted) {
        setState(() {
          _roadmap = _createMockRoadmap();
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    try {
      final roadmap = await _repo.getCurrentRoadmap(userId);
      if (mounted) {
        setState(() {
          _roadmap = roadmap;
          _loading = false;
          _error = null;
        });
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          _loading = false;
          // 404 or "No roadmap found" means no roadmap yet - don't show as error
          _error = msg.contains('404') || msg.contains('No roadmap found')
              ? null
              : msg.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _generateRoadmap() async {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final roadmap = await _repo.generateRoadmap(userId: userId);
      if (mounted) {
        setState(() {
          _roadmap = roadmap;
          _generating = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _onPhaseTap(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          if (_loading)
            const SliverFillRemaining(child: _LoadingState())
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorState(
                message: _error!,
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadRoadmap();
                },
                isDark: isDark,
              ),
            )
          else if (_roadmap == null)
            SliverFillRemaining(
              child: _EmptyState(
                onGenerate: _generating ? null : _generateRoadmap,
                generating: _generating,
                isDark: isDark,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _HeroSection(roadmap: _roadmap!, isDark: isDark),
            ),
            SliverToBoxAdapter(
              child: _SafetyBanner(status: _roadmap!.safetyStatus),
            ),
            SliverToBoxAdapter(
              child: _JourneyVisualization(roadmap: _roadmap!, isDark: isDark),
            ),
            SliverToBoxAdapter(
              child: _PhaseProgressSection(
                roadmap: _roadmap!,
                selectedIndex: _selectedPhaseIndex,
                isDark: isDark,
                onPhaseTap: _onPhaseTap,
              ),
            ),
            SliverToBoxAdapter(
              child: _MilestonesSection(roadmap: _roadmap!, isDark: isDark),
            ),
            if (_roadmap!.screenTimeInsights != null)
              SliverToBoxAdapter(
                child: _ScreenTimeSection(
                  insights: _roadmap!.screenTimeInsights!,
                  isDark: isDark,
                ),
              ),
            SliverToBoxAdapter(
              child: _OverviewCard(
                text: _roadmap!.overviewParagraph,
                nextCheckupDays: _roadmap!.nextCheckupDays,
                isDark: isDark,
              ),
            ),
            _buildTaskList(isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB),
      elevation: 0,
      leading: const DrawerMenuButton(),
      title: Text(
        'My Roadmap',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      actions: [
        if (_roadmap != null)
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Refresh',
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            onPressed: () {
              setState(() {
                _loading = true;
                _roadmap = null;
              });
              _loadRoadmap();
            },
          ),
      ],
      bottom: _roadmap != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: isDark ? Colors.white : AppColors.textPrimary,
                  unselectedLabelColor: isDark ? Colors.white38 : AppColors.textSecondary,
                  indicatorColor: AppColors.purple,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    for (int i = 0; i < _phases.length; i++)
                      _PhaseTab(label: _phases[i], count: _getPhaseCount(i), isSelected: _selectedPhaseIndex == i),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  int _getPhaseCount(int index) {
    if (_roadmap == null) return 0;
    switch (index) {
      case 0: return _roadmap!.suggestedTasks.length;
      case 1: return _roadmap!.quickWins.length;
      case 2: return _roadmap!.ladderTasks.length;
      case 3: return _roadmap!.bossTasks.length;
      default: return 0;
    }
  }

  Widget _buildTaskList(bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (_selectedPhaseIndex == 0) {
            return _buildOverviewTaskSection(index, isDark);
          }
          final tasks = _selectedPhaseIndex == 1
              ? _roadmap!.quickWins
              : _selectedPhaseIndex == 2
                  ? _roadmap!.ladderTasks
                  : _roadmap!.bossTasks;
          if (index >= tasks.length) return null;
          return _TaskCard(task: tasks[index], isDark: isDark, onTap: () => _showTaskDetail(context, tasks[index]));
        },
        childCount: _getTaskCount(),
      ),
    );
  }

  int _getTaskCount() {
    if (_roadmap == null) return 0;
    if (_selectedPhaseIndex == 0) return 3;
    switch (_selectedPhaseIndex) {
      case 1: return _roadmap!.quickWins.length;
      case 2: return _roadmap!.ladderTasks.length;
      case 3: return _roadmap!.bossTasks.length;
      default: return 0;
    }
  }

  Widget _buildOverviewTaskSection(int index, bool isDark) {
    switch (index) {
      case 0:
        return _TaskSection(title: 'Quick Wins', tasks: _roadmap!.quickWins, phase: 'Quick Win', isDark: isDark, onTaskTap: _showTaskDetail);
      case 1:
        return _TaskSection(title: 'Ladder', tasks: _roadmap!.ladderTasks, phase: 'Ladder', isDark: isDark, onTaskTap: _showTaskDetail);
      case 2:
        return _TaskSection(title: 'Boss Level', tasks: _roadmap!.bossTasks, phase: 'Boss', isDark: isDark, onTaskTap: _showTaskDetail);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showTaskDetail(BuildContext context, ClinicalTask task) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(task: task, isDark: isDarkMode),
    );
  }
}

// ─── Hero Section ────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.roadmap, required this.isDark});
  final RoadmapFullResponse roadmap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF14B8A6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.map, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('90-Day Journey', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              Text('${roadmap.totalDays} Days of Growth', style: GoogleFonts.inter(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
            ])),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _HeroStat(icon: LucideIcons.target, value: '${roadmap.suggestedTasks.length}', label: 'Tasks'),
            _HeroStat(icon: LucideIcons.zap, value: '${roadmap.totalXp}', label: 'Total XP'),
            _HeroStat(icon: LucideIcons.calendar, value: '${roadmap.nextCheckupDays}', label: 'Days Left'),
          ]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: 0.0, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8)),
          const SizedBox(height: 8),
          Text('Start your journey to see progress', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value, required this.label});
  final IconData icon; final String value; final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Row(children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
      ]),
    ]));
  }
}

// ─── Safety Banner ───────────────────────────────────────────────────────────

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'GREEN') return const SizedBox.shrink();
    final isRed = status == 'RED';
    final color = isRed ? AppColors.red : AppColors.warning;
    final icon = isRed ? LucideIcons.alertTriangle : LucideIcons.alertCircle;
    final title = isRed ? 'Safety Alert' : 'Attention Needed';
    final text = isRed ? 'Please speak with a mental health professional.' : 'Some tasks are flagged — check items with a ⚠ icon.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          Text(text, style: GoogleFonts.inter(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ])),
      ]),
    ).animate().fadeIn(delay: 100.ms);
  }
}

// ─── Journey Visualization ───────────────────────────────────────────────────

class _JourneyVisualization extends StatelessWidget {
  const _JourneyVisualization({required this.roadmap, required this.isDark});
  final RoadmapFullResponse roadmap; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Journey', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(children: [
          _JourneyPhase(phase: 'Quick Wins', days: '1-30', color: AppColors.green, icon: LucideIcons.rocket, isActive: true, isDark: isDark),
          Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
          _JourneyPhase(phase: 'Ladder', days: '31-60', color: AppColors.orange, icon: LucideIcons.trendingUp, isActive: false, isDark: isDark),
          Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
          _JourneyPhase(phase: 'Boss', days: '61-90', color: AppColors.pink, icon: LucideIcons.crown, isActive: false, isDark: isDark),
        ]),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _JourneyPhase extends StatelessWidget {
  const _JourneyPhase({required this.phase, required this.days, required this.color, required this.icon, required this.isActive, required this.isDark});
  final String phase; final String days; final Color color; final IconData icon; final bool isActive; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: isActive ? color : color.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: isActive ? color : color.withValues(alpha: 0.3), width: 2)), child: Icon(icon, size: 20, color: isActive ? Colors.white : color)),
      const SizedBox(height: 6),
      Text(phase, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? (isDark ? Colors.white : AppColors.textPrimary) : AppColors.textSecondary)),
      Text(days, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
    ]);
  }
}

// ─── Phase Progress Section ─────────────────────────────────────────────────

class _PhaseProgressSection extends StatelessWidget {
  const _PhaseProgressSection({required this.roadmap, required this.selectedIndex, required this.isDark, required this.onPhaseTap});
  final RoadmapFullResponse roadmap; final int selectedIndex; final bool isDark; final void Function(int) onPhaseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: _PhaseCard(title: 'Quick Wins', count: roadmap.quickWins.length, totalXp: roadmap.quickWins.fold(0, (sum, t) => sum + t.xpReward), color: AppColors.green, isSelected: selectedIndex == 1, isDark: isDark, onTap: () => onPhaseTap(1))),
        const SizedBox(width: 8),
        Expanded(child: _PhaseCard(title: 'Ladder', count: roadmap.ladderTasks.length, totalXp: roadmap.ladderTasks.fold(0, (sum, t) => sum + t.xpReward), color: AppColors.orange, isSelected: selectedIndex == 2, isDark: isDark, onTap: () => onPhaseTap(2))),
        const SizedBox(width: 8),
        Expanded(child: _PhaseCard(title: 'Boss', count: roadmap.bossTasks.length, totalXp: roadmap.bossTasks.fold(0, (sum, t) => sum + t.xpReward), color: AppColors.pink, isSelected: selectedIndex == 3, isDark: isDark, onTap: () => onPhaseTap(3))),
      ]),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.title, required this.count, required this.totalXp, required this.color, required this.isSelected, required this.isDark, required this.onTap});
  final String title; final int count; final int totalXp; final Color color; final bool isSelected; final bool isDark; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1A2030) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : (isDark ? Colors.white10 : Colors.black12), width: isSelected ? 2 : 1),
        ),
        child: Column(children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? color : (isDark ? Colors.white : AppColors.textPrimary))),
          const SizedBox(height: 4),
          Text('$count tasks', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('$totalXp XP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}

// ─── Milestones Section ───────────────────────────────────────────────────

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({required this.roadmap, required this.isDark});
  final RoadmapFullResponse roadmap; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.award, size: 18, color: AppColors.purple), const SizedBox(width: 8), Text('Milestones', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary))]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _MilestoneCard(emoji: '🌱', title: 'First Step', days: 1, isUnlocked: true, isDark: isDark),
            _MilestoneCard(emoji: '⚔️', title: 'Week Warrior', days: 7, isUnlocked: true, isDark: isDark),
            _MilestoneCard(emoji: '🏗️', title: 'Habit Builder', days: 14, isUnlocked: false, isDark: isDark),
            _MilestoneCard(emoji: '🏆', title: 'Month Master', days: 30, isUnlocked: false, isDark: isDark),
            _MilestoneCard(emoji: '👑', title: 'Quarter Champ', days: 90, isUnlocked: false, isDark: isDark),
          ]),
        ),
      ]),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.emoji, required this.title, required this.days, required this.isUnlocked, required this.isDark});
  final String emoji; final String title; final int days; final bool isUnlocked; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.purple.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1A2030) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? AppColors.purple.withValues(alpha: 0.3) : (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(children: [
        Text(emoji, style: TextStyle(fontSize: 24, color: isUnlocked ? null : Colors.grey)),
        const SizedBox(height: 6),
        Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isUnlocked ? (isDark ? Colors.white : AppColors.textPrimary) : AppColors.textSecondary), textAlign: TextAlign.center),
        Text('$days days', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
        if (!isUnlocked) ...[const SizedBox(height: 4), const Icon(LucideIcons.lock, size: 12, color: AppColors.textSecondary)],
      ]),
    );
  }
}

// ─── Screen Time Section ───────────────────────────────────────────────────

class _ScreenTimeSection extends StatelessWidget {
  const _ScreenTimeSection({required this.insights, required this.isDark});
  final ScreenTimeInsights insights; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2030) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(LucideIcons.smartphone, size: 18, color: AppColors.blue)),
          const SizedBox(width: 12),
          Text('Screen Time Insights', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
          const Spacer(),
          Text(insights.formattedTotalTime, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.blue)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(children: [
            Expanded(flex: (insights.socialRatio * 100).round(), child: Container(height: 12, color: AppColors.pink)),
            Expanded(flex: (insights.productivityRatio * 100).round(), child: Container(height: 12, color: AppColors.teal)),
            Expanded(flex: ((1 - insights.socialRatio - insights.productivityRatio) * 100).round().clamp(0, 100), child: Container(height: 12, color: isDark ? Colors.white10 : Colors.grey.shade300)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ScreenTimeLabel(color: AppColors.pink, label: 'Social', percent: '${(insights.socialRatio * 100).round()}%'),
          _ScreenTimeLabel(color: AppColors.teal, label: 'Productivity', percent: '${(insights.productivityRatio * 100).round()}%'),
          _ScreenTimeLabel(color: isDark ? Colors.white24 : Colors.grey.shade400, label: 'Other', percent: '${((1 - insights.socialRatio - insights.productivityRatio) * 100).round()}%'),
        ]),
      ]),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _ScreenTimeLabel extends StatelessWidget {
  const _ScreenTimeLabel({required this.color, required this.label, required this.percent});
  final Color color; final String label; final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(percent, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    ]);
  }
}

// ─── Overview Card ─────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.text, required this.nextCheckupDays, required this.isDark});
  final String text; final int nextCheckupDays; final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2030) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.sparkles, size: 18, color: AppColors.purple), const SizedBox(width: 8), Text('AI Insights', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary))]),
        const SizedBox(height: 12),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.calendarCheck, size: 14, color: AppColors.teal),
            const SizedBox(width: 6),
            Text('Next check-up in $nextCheckupDays days', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teal)),
          ]),
        ),
      ]),
    ).animate().fadeIn(delay: 600.ms);
  }
}

// ─── Task Section (Overview) ────────────────────────────────────────────────

class _TaskSection extends StatelessWidget {
  const _TaskSection({required this.title, required this.tasks, required this.phase, required this.isDark, required this.onTaskTap});
  final String title; final List<ClinicalTask> tasks; final String phase; final bool isDark; final void Function(BuildContext, ClinicalTask) onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final phaseConfig = PhaseConfig.fromPhase(phase);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Color(phaseConfig.color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Icon(phase == 'Quick Win' ? LucideIcons.rocket : phase == 'Ladder' ? LucideIcons.trendingUp : LucideIcons.crown, size: 14, color: Color(phaseConfig.color))),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Color(phaseConfig.color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text('${tasks.length}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Color(phaseConfig.color)))),
        ]),
        const SizedBox(height: 8),
        ...tasks.map((task) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _TaskCard(task: task, isDark: isDark, onTap: () => onTaskTap(context, task)))),
      ]),
    );
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.isDark, required this.onTap});
  final ClinicalTask task; final bool isDark; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final phaseConfig = PhaseConfig.fromPhase(task.phase);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2030) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(task.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary, height: 1.4))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Color(phaseConfig.color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(task.phase == 'Quick Win' ? LucideIcons.rocket : task.phase == 'Ladder' ? LucideIcons.trendingUp : LucideIcons.crown, size: 10, color: Color(phaseConfig.color)),
                const SizedBox(width: 4),
                Text(task.phase, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Color(phaseConfig.color))),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _DifficultyStars(difficulty: task.difficulty),
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.zap, size: 10, color: AppColors.orange), const SizedBox(width: 3), Text('${task.xpReward} XP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.orange))])),
            if (task.safetyRisk) ...[const SizedBox(width: 8), const Tooltip(message: 'Flagged for clinical review', child: Icon(LucideIcons.alertTriangle, size: 12, color: AppColors.warning))],
          ]),
          if (task.symptomTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: task.symptomTags.take(3).map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)), child: Text('#$tag', style: GoogleFonts.inter(fontSize: 9, color: AppColors.purple)))).toList()),
          ],
        ]),
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  const _DifficultyStars({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(LucideIcons.star, size: 10, color: i < difficulty ? AppColors.orange : AppColors.orange.withValues(alpha: 0.2))));
  }
}

// ─── Task Detail Sheet ───────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({required this.task, required this.isDark});
  final ClinicalTask task; final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2030) : Colors.white;
    final phaseConfig = PhaseConfig.fromPhase(task.phase);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Color(phaseConfig.color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(task.phase == 'Quick Win' ? LucideIcons.rocket : task.phase == 'Ladder' ? LucideIcons.trendingUp : LucideIcons.crown, size: 14, color: Color(phaseConfig.color)), const SizedBox(width: 6), Text(task.phase, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Color(phaseConfig.color)))])),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.zap, size: 12, color: AppColors.orange), const SizedBox(width: 4), Text('${task.xpReward} XP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange))])),
                ]),
                const SizedBox(height: 20),
                Text(task.content, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary, height: 1.6)),
                const SizedBox(height: 24),
                _DetailRow(icon: LucideIcons.star, label: 'Difficulty', child: Row(children: List.generate(5, (i) => Icon(LucideIcons.star, size: 16, color: i < task.difficulty ? AppColors.orange : AppColors.orange.withValues(alpha: 0.2)))..add(const SizedBox(width: 8))..add(Text('${task.difficulty}/5', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange))))),
                if (task.symptomTags.isNotEmpty) 
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _DetailRow(icon: LucideIcons.tag, label: 'Related Symptoms', child: Wrap(spacing: 6, runSpacing: 6, children: task.symptomTags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(tag, style: GoogleFonts.inter(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w500)))).toList())),
                  ),
                if (task.sourceReference.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _DetailRow(icon: LucideIcons.bookOpen, label: 'Source', child: Text(task.sourceReference, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary, fontStyle: FontStyle.italic))),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.play, size: 16),
                    label: Text('Start This Task', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.child});
  final IconData icon; final String label; final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: AppColors.textSecondary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)), const SizedBox(height: 6), child]))]);
  }
}

// ─── Loading State ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: AppColors.purple), const SizedBox(height: 16), Text('Loading your roadmap...', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))]));
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onGenerate, required this.generating, required this.isDark});
  final VoidCallback? onGenerate; final bool generating; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(LucideIcons.map, size: 48, color: AppColors.purple.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          Text('Your Journey Awaits', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text('Generate your personalized 90-day wellness roadmap powered by AI. Based on your assessment, we\'ll create tasks tailored to your goals.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purple, AppColors.teal]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onGenerate,
                borderRadius: BorderRadius.circular(16),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), child: Row(mainAxisSize: MainAxisSize.min, children: [generating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.sparkles, size: 18, color: Colors.white), const SizedBox(width: 10), Text(generating ? 'Generating...' : 'Generate My Roadmap', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))])),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Takes ~30 seconds • Completely personalized', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry, required this.isDark});
  final String message; final VoidCallback onRetry; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.wifiOff, size: 40, color: AppColors.red)),
      const SizedBox(height: 20),
      Text('Something went wrong', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.red)),
      const SizedBox(height: 24),
      OutlinedButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('Try Again'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.purple, side: const BorderSide(color: AppColors.purple), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    ])));
  }
}

// ─── Phase Tab ───────────────────────────────────────────────────────────────

class _PhaseTab extends StatelessWidget {
  const _PhaseTab({required this.label, required this.count, required this.isSelected});
  final String label; final int count; final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      if (count > 0) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isSelected ? AppColors.purple.withValues(alpha: 0.2) : AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)))],
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEBUG: Mock Data for UI Testing
// ═══════════════════════════════════════════════════════════════════════════════

RoadmapFullResponse _createMockRoadmap() {
  return RoadmapFullResponse(
    userId: 'user-123-uuid',
    overviewParagraph: "Based on your assessment, you're experiencing mild anxiety symptoms with some digital overload. Your 90-day roadmap focuses on building healthy habits through quick wins, gradual skill-building, and breakthrough challenges.",
    suggestedTasks: [
      const ClinicalTask(taskId: 'task-001', content: 'Practice the 4-7-8 breathing technique for 5 minutes when feeling anxious', symptomTags: ['anxiety', 'panic', 'breathing'], difficulty: 1, xpReward: 50, safetyRisk: false, utilityScore: 0.92, sourceReference: 'CBT_Techniques_Chapter_3', metadata: {'section': 'Breathing Exercises', 'pages': '45-47'}, phase: 'Quick Win'),
      const ClinicalTask(taskId: 'task-002', content: 'Set app timers for social media to limit daily usage to 30 minutes', symptomTags: ['digital-detox', 'screen-time', 'anxiety'], difficulty: 2, xpReward: 75, safetyRisk: false, utilityScore: 0.85, sourceReference: 'Digital_Wellness_Guide', metadata: {}, phase: 'Quick Win'),
      const ClinicalTask(taskId: 'task-003', content: 'Complete a thought record worksheet identifying cognitive distortions', symptomTags: ['anxiety', 'depression', 'cbt'], difficulty: 3, xpReward: 100, safetyRisk: false, utilityScore: 0.88, sourceReference: 'CBT_Workbook_Chapter_5', metadata: {}, phase: 'Ladder'),
      const ClinicalTask(taskId: 'task-004', content: 'Practice progressive muscle relaxation for 10 minutes before bed', symptomTags: ['sleep', 'anxiety', 'relaxation'], difficulty: 2, xpReward: 60, safetyRisk: false, utilityScore: 0.78, sourceReference: 'Sleep_Hygiene_Guide', metadata: {}, phase: 'Quick Win'),
      const ClinicalTask(taskId: 'task-005', content: 'Schedule and complete a 15-minute exposure to a social situation you\'ve been avoiding', symptomTags: ['anxiety', 'social', 'exposure-therapy'], difficulty: 4, xpReward: 150, safetyRisk: false, utilityScore: 0.91, sourceReference: 'Exposure_Therapy_Protocol', metadata: {}, phase: 'Boss'),
      const ClinicalTask(taskId: 'task-006', content: 'Journal about 3 things you\'re grateful for each morning for 1 week', symptomTags: ['gratitude', 'mindfulness', 'depression'], difficulty: 2, xpReward: 80, safetyRisk: false, utilityScore: 0.75, sourceReference: 'Positive_Psychology_Research', metadata: {}, phase: 'Quick Win'),
      const ClinicalTask(taskId: 'task-007', content: 'Create a worry time buffer - schedule 15 minutes daily to address worries', symptomTags: ['anxiety', 'worry-management', 'cbt'], difficulty: 3, xpReward: 90, safetyRisk: false, utilityScore: 0.82, sourceReference: 'CBT_Techniques_Chapter_7', metadata: {}, phase: 'Ladder'),
      const ClinicalTask(taskId: 'task-008', content: 'Complete a full body scan meditation (30 minutes)', symptomTags: ['meditation', 'mindfulness', 'anxiety'], difficulty: 3, xpReward: 110, safetyRisk: false, utilityScore: 0.79, sourceReference: 'Mindfulness_Based_Stress_Reduction', metadata: {}, phase: 'Ladder'),
      const ClinicalTask(taskId: 'task-009', content: 'Challenge a core belief by gathering evidence for and against it', symptomTags: ['cbt', 'cognitive-restructuring', 'anxiety'], difficulty: 5, xpReward: 200, safetyRisk: false, utilityScore: 0.94, sourceReference: 'CBT_Advanced_Techniques', metadata: {}, phase: 'Boss'),
      const ClinicalTask(taskId: 'task-010', content: 'Practice mindful eating - focus on one meal without distractions', symptomTags: ['mindfulness', 'eating-awareness', 'anxiety'], difficulty: 1, xpReward: 40, safetyRisk: false, utilityScore: 0.70, sourceReference: 'Mindful_Eating_Guide', metadata: {}, phase: 'Quick Win'),
    ],
    safetyStatus: 'GREEN',
    nextCheckupDays: 7,
    generatedAt: DateTime.now().toIso8601String(),
    screenTimeInsights: const ScreenTimeInsights(
      totalMinutes: 240.0,
      socialRatio: 0.75,
      productivityRatio: 0.15,
      topSocialApps: ['com.instagram.android', 'com.whatsapp', 'com.facebook.katana'],
      topProductivityApps: ['com.microsoft.office.word'],
      appBreakdown: [
        AppBreakdownItem(packageName: 'com.instagram.android', percentage: 50.0, category: 'social'),
        AppBreakdownItem(packageName: 'com.whatsapp', percentage: 15.0, category: 'social'),
        AppBreakdownItem(packageName: 'com.facebook.katana', percentage: 10.0, category: 'social'),
        AppBreakdownItem(packageName: 'com.microsoft.office.word', percentage: 15.0, category: 'productivity'),
        AppBreakdownItem(packageName: 'com.chrome', percentage: 10.0, category: 'other'),
      ],
    ),
    totalDays: 90,
    assessmentRequired: false,
  );
}