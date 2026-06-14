import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/screen_time_service.dart';
import '../services/onboarding_service.dart';
import '../services/error_handler_service.dart';
import '../widgets/common/loading_overlay.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/analytics/offline_indicator.dart';
import '../widgets/analytics/export_bottom_sheet.dart';
import '../widgets/analytics/limited_functionality_banner.dart';
import '../widgets/analytics/wellness_hero_card.dart';
import '../widgets/analytics/quick_stats_row.dart';
import '../widgets/analytics/screen_limit_meter.dart';
import '../widgets/analytics/usage_trend_chart.dart';
import '../widgets/analytics/app_usage_breakdown.dart';
import '../widgets/analytics/most_used_apps_list.dart';
import '../widgets/analytics/ai_insights_list.dart';
import 'onboarding/analytics_permission_onboarding.dart';
import '../widgets/drawer_menu_button.dart';
import 'comparison_screen.dart';
import '../navigation/app_routes.dart';
import '../models/insight_model.dart';
import '../services/insights_service.dart';
import '../models/dashboard_data.dart';
import '../design_system/tokens/design_tokens.dart';
import '../shared/theme/upheal_home_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('com.appguard.native_calls');

  bool _hasPermission = false;
  bool _isLoading = false;
  bool _hasCompletedOnboarding = true;
  bool _showLimitedBanner = false;
  bool _pendingPermissionCheck = false;
  List<Map<String, dynamic>> usageData = [];
  String _selectedTimePeriod = 'daily';

  List<Insight> _previewInsights = [];
  InsightsSummary? _insightsSummary;

  final _weeklyChartKey = GlobalKey();

  Set<String> blockedPackages = {};
  Map<String, int> appTimeLimits = {};

  DashboardData get _dashboardData => DashboardData(
        usageData: usageData,
        focusScore: _calculateFocusScore(),
        blockedCount: blockedPackages.length,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingAndPermission();
      _loadBlockedApps();
      _loadTimeLimits();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _pendingPermissionCheck) {
      _pendingPermissionCheck = false;
      _checkPermission();
    }
  }

  Future<void> _checkOnboardingAndPermission() async {
    final hasCompletedOnboarding =
        await OnboardingService.hasCompletedAnalyticsOnboarding();
    if (mounted) {
      setState(() => _hasCompletedOnboarding = hasCompletedOnboarding);
    }
    if (!hasCompletedOnboarding) {
      _showOnboardingFlow();
    } else {
      await _checkPermission();
    }
  }

  Future<void> _showOnboardingFlow() async {
    if (!mounted) return;
    final result = await AnalyticsOnboardingDialog.show(context);
    if (result == true) {
      await _requestPermission();
    } else {
      await OnboardingService.markAnalyticsOnboardingComplete();
      setState(() {
        _hasCompletedOnboarding = true;
        _showLimitedBanner = true;
      });
    }
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;
    final errors = context.read<ErrorHandlerModel>();
    try {
      errors.showLoading('Checking permission...');
      final hasPermission =
          await ScreenTimeService.checkUsageStatsPermission();
      if (!mounted) return;
      setState(() {
        _hasPermission = hasPermission;
        _showLimitedBanner = !hasPermission && _hasCompletedOnboarding;
      });
      if (hasPermission) {
        setState(() => _showLimitedBanner = false);
        await _loadUsageStats(showSpinner: false);
      }
    } catch (e) {
      errors.showError('Permission check failed: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _showLimitedBanner = _hasCompletedOnboarding;
        });
      }
    } finally {
      errors.hideLoading();
    }
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    final errors = context.read<ErrorHandlerModel>();
    errors.showLoading('Opening settings...');
    try {
      _pendingPermissionCheck = true;
      await ScreenTimeService.requestUsageStatsPermission();
      errors.showSuccess('Usage access requested');
      _showPermissionDialog();
    } catch (e) {
      errors.showError('Error requesting permission: $e');
      _showPermissionDialog();
    } finally {
      errors.hideLoading();
    }
  }

  Future<void> _loadUsageStats({bool showSpinner = true}) async {
    final errors = context.read<ErrorHandlerModel>();
    try {
      if (showSpinner) {
        errors.showLoading('Loading screen time...');
        if (mounted) setState(() => _isLoading = true);
      }

      List<Map<String, dynamic>> realUsageStats;
      if (_selectedTimePeriod == 'weekly') {
        realUsageStats = await ScreenTimeService.getBetterWeeklyUsage();
      } else {
        realUsageStats = await ScreenTimeService.getUltraAccurateUsageStats(
            period: _selectedTimePeriod);
      }

      if (mounted) {
        setState(() {
          usageData = realUsageStats
              .where((d) => d['usageTime'] > 0)
              .toList()
            ..sort((a, b) =>
                (b['usageTime'] as int).compareTo(a['usageTime'] as int));
        });
      }
    } catch (e) {
      errors.showError('Failed to load usage stats: $e');
    } finally {
      if (showSpinner) {
        errors.hideLoading();
        if (mounted) setState(() => _isLoading = false);
      }
      _loadInsightsPreview();
    }
  }

  Future<void> _loadInsightsPreview() async {
    try {
      final weeklyTrend = await ScreenTimeService.getDailyUsageForTrend();
      final insights = await InsightsService.generateAllInsights(
        usageData: usageData,
        weeklyTrend: weeklyTrend,
      );
      if (mounted) {
        setState(() {
          _previewInsights = insights.take(3).toList();
          _insightsSummary = InsightsService.createSummary(insights);
        });
      }
    } catch (e) {
      print('Error loading insights preview: $e');
    }
  }

  void _navigateToInsights() {
    const InsightsRoute().push(context);
  }

  Future<void> _onRefresh() async {
    await _loadUsageStats();
  }

  void _navigateToComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ComparisonScreen(),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Enable Usage Access',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To view real screen time data, please:',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              Text('1. Tap "Open Settings" below',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('2. Look for "my_app" in the list',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                  '3. If you don\'t see "my_app", scroll down or search',
                  style: GoogleFonts.inter(
                      color: Colors.orange, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('4. Toggle "Permit usage access" ON',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('5. Return to the app',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUsageStatsSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Open Settings',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openUsageStatsSettings() {
    _pendingPermissionCheck = true;
    ScreenTimeService.requestUsageStatsPermission();
  }

  @override
  Widget build(BuildContext context) {
    final handler = context.watch<ErrorHandlerModel>();
    final isBusy = handler.isLoading || _isLoading;
    final tokens = Theme.of(context).upHealHome;

    return Scaffold(
      backgroundColor: tokens.pageBackground,
      body: Column(
        children: [
          OfflineIndicator(
            isVisible: ScreenTimeService.isUsingCachedData,
            message: 'Using offline data - permission not available',
            onRetry: () async => await _checkPermission(),
          ),
          Expanded(
            child: LoadingOverlay(
              isLoading: isBusy,
              message: handler.loadingMessage,
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _buildBodyContent(isBusy),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(bool isBusy) {
    if (isBusy) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: const [
            SkeletonLoader.cardSkeleton(),
            SizedBox(height: 16),
            SkeletonLoader.cardSkeleton(),
            SizedBox(height: 16),
            SkeletonLoader.chartSkeleton(),
            SizedBox(height: 16),
            SkeletonLoader.listItemSkeleton(),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            if (_showLimitedBanner)
              LimitedFunctionalityBanner(
                onEnablePressed: _showOnboardingFlow,
                onDismiss: () => setState(() => _showLimitedBanner = false),
              ),
            if (_showLimitedBanner) const SizedBox(height: 16),
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTimePeriodSelector(),
            const SizedBox(height: 20),
            _buildDebugInfo(),
            const SizedBox(height: 20),
            _buildPermissionRequestCard(),
          ],
        ),
      );
    }

    if (usageData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: EmptyStateWidget(
            iconData: LucideIcons.barChart3,
            title: 'No screen time data yet',
            subtitle:
                'Use your device for a bit or refresh to pull today\'s stats.',
            actionText: 'Refresh',
            onAction: _onRefresh,
          ),
        ),
      );
    }

    final data = _dashboardData;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildTimePeriodSelector(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: WellnessHeroCard(data: data),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: QuickStatsRow(data: data),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: ScreenLimitMeter(data: data),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: _buildSectionHeader(
              context,
              icon: LucideIcons.lineChart,
              label: 'Usage Trend',
              color: const Color(0xFF7C3AED),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: _buildUsageChart(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: _buildSectionHeader(
              context,
              icon: LucideIcons.barChart,
              label: 'App Usage Breakdown',
              color: const Color(0xFF5B7CFA),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: AppUsageBreakdown(data: data),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: _buildSectionHeader(
              context,
              icon: LucideIcons.smartphone,
              label: 'Most Used Apps',
              color: const Color(0xFFF97316),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: MostUsedAppsList(
              data: data,
              blockedPackages: blockedPackages,
              appTimeLimits: appTimeLimits,
              onAppOptions: _showAppOptionsDialog,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: _buildSectionHeader(
              context,
              icon: LucideIcons.sparkles,
              label: 'AI Insights',
              color: const Color(0xFF10B981),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
            child: AiInsightsList(
              insights: _previewInsights,
              summary: _insightsSummary,
              onViewAll: _navigateToInsights,
            ),
          ),
        ),
      ],
    );
  }

  String get _timePeriodLabel {
    switch (_selectedTimePeriod) {
      case 'yesterday':
        return 'Yesterday';
      case 'weekly':
        return 'This Week';
      case 'monthly':
        return 'This Month';
      default:
        return 'Today';
    }
  }

  Widget _buildHeader(BuildContext context) {
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Screen Time Analytics',
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
            _timePeriodLabel,
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

  Widget _buildHeaderAction(IconData icon, String tooltip,
      VoidCallback onTap, bool isDark, UpHealHomeTheme tokens) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.sm,
        color: isDark ? const Color(0xFF1C1F26) : tokens.cardFill,
        boxShadow: context.appShadows.soft,
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isDark ? Colors.white : tokens.primaryText, size: 18),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
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

  Widget _buildTimePeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Period',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : tokens.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeTab('Today', 'daily'),
              const SizedBox(width: AppSpacing.sm),
              _buildTimeTab('Yesterday', 'yesterday'),
              const SizedBox(width: AppSpacing.sm),
              _buildTimeTab('Weekly', 'weekly'),
              const SizedBox(width: AppSpacing.sm),
              _buildTimeTab('Monthly', 'monthly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String label, String value) {
    final isSelected = _selectedTimePeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _selectedTimePeriod = value);
          ScreenTimeService.invalidateCaches();
          await _loadUsageStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            color: isSelected
                ? tokens.accentGradient.colors.first
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade100),
            border: Border.all(
              color: isSelected
                  ? tokens.accentGradient.colors.first
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.grey.shade300),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text('Usage Data Debug Info',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'Permission Status: ${_hasPermission ? "Granted" : "Not Granted"}',
              style: GoogleFonts.inter(fontSize: 12, color: textColor)),
          Text('Data Count: ${usageData.length} apps',
              style: GoogleFonts.inter(fontSize: 12, color: textColor)),
          Text('Total Time: ${_dashboardData.formattedTotal}',
              style: GoogleFonts.inter(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: const Icon(LucideIcons.shield,
                    color: Colors.orange, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Enable Usage Access',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              Text(
                'To view real screen time data, please enable usage access permission.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _requestPermission,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.shield),
                  label: Text(
                    _isLoading ? 'Requesting...' : 'Enable Usage Access',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    final tokens = Theme.of(context).upHealHome;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadComparisonData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              color: tokens.cardFill,
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Center(
              child: CircularProgressIndicator(
                  color: tokens.accentGradient.colors.first),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data['current'] == null) {
          return const SizedBox.shrink();
        }

        final currentData = data['current'] as List<Map<String, dynamic>>;
        final previousData =
            data['previous'] as List<Map<String, dynamic>>? ?? [];

        return UsageTrendChart(
          currentWeek: currentData,
          previousWeek: previousData,
          chartKey: _weeklyChartKey,
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadComparisonData() async {
    try {
      final currentWeekData = await ScreenTimeService.getDailyUsageForTrend();
      final previousWeekData =
          await ScreenTimeService.getDailyUsageForPreviousWeek();

      final List<Map<String, dynamic>> current = [];
      final List<Map<String, dynamic>> previous = [];

      const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < 7; i++) {
        final dayData = currentWeekData.firstWhere(
          (d) => d['day'] == i,
          orElse: () => {'day': i, 'totalHours': 0.0},
        );
        current.add({
          'dayLabel': daysOfWeek[i],
          'usageHours': (dayData['totalHours'] as num).toDouble(),
        });
      }

      for (int i = 0; i < 7; i++) {
        final dayData = previousWeekData.firstWhere(
          (d) => d['day'] == i,
          orElse: () => {'day': i, 'totalHours': 0.0},
        );
        previous.add({
          'dayLabel': daysOfWeek[i],
          'usageHours': (dayData['totalHours'] as num).toDouble(),
        });
      }

      return {'current': current, 'previous': previous};
    } catch (e) {
      print('Error loading comparison data: $e');
      const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return {
        'current':
            List.generate(7, (i) => {'dayLabel': daysOfWeek[i], 'usageHours': 0.0}),
        'previous': [],
      };
    }
  }

  int _calculateFocusScore() {
    if (usageData.isEmpty) return 0;
    final productiveApps = usageData.where((app) {
      final appName = app['appName'] as String;
      return appName.toLowerCase().contains('chrome') ||
          appName.toLowerCase().contains('notes') ||
          appName.toLowerCase().contains('calendar') ||
          appName.toLowerCase().contains('email');
    }).length;
    final totalApps = usageData.length;
    final productiveRatio = totalApps > 0 ? productiveApps / totalApps : 0;
    final baseScore = (productiveRatio * 100).round();
    final totalSeconds = usageData.fold<int>(0, (sum, item) => sum + ((item['usageTime'] as int) ~/ 1000));
    final timeAdjustment = totalSeconds > 3600 ? -10 : 0;
    return (baseScore + timeAdjustment).clamp(0, 100);
  }

  Future<void> _loadBlockedApps() async {
    try {
      final blocked = await platform.invokeMethod('getBlockedApps');
      setState(() => blockedPackages = Set<String>.from(blocked));
    } catch (e) {
      print('Error loading blocked apps: $e');
    }
  }

  Future<void> _loadTimeLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limitsJson = prefs.getString('app_time_limits');
      if (limitsJson != null) {
        final Map<String, dynamic> decoded = json.decode(limitsJson);
        setState(() {
          appTimeLimits =
              decoded.map((key, value) => MapEntry(key, value as int));
        });
      }
    } catch (e) {
      print('Error loading time limits: $e');
    }
  }

  Future<void> _saveTimeLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'app_time_limits', json.encode(appTimeLimits));
    } catch (e) {
      print('Error saving time limits: $e');
    }
  }

  Future<void> _toggleAppBlock(String packageName, bool isBlocked) async {
    try {
      final success = await platform.invokeMethod('setAppBlockStatus', {
        'packageName': packageName,
        'isBlocked': isBlocked,
      });
      if (success) {
        setState(() {
          if (isBlocked) {
            blockedPackages.add(packageName);
          } else {
            blockedPackages.remove(packageName);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isBlocked ? 'App blocked successfully' : 'App unblocked successfully'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      print('Error toggling app block: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAppOptionsDialog(
      String packageName, String appName, String usageTime) {
    final bool isBlocked = blockedPackages.contains(packageName);
    final int? currentLimit = appTimeLimits[packageName];

    showDialog(
      context: context,
      builder: (context) => _AppOptionsDialog(
        packageName: packageName,
        appName: appName,
        usageTime: usageTime,
        isBlocked: isBlocked,
        currentTimeLimit: currentLimit,
        onApply: (blocked, minutes) async {
          if (blocked != isBlocked) {
            await _toggleAppBlock(packageName, blocked);
          }
          setState(() {
            if (minutes > 0) {
              appTimeLimits[packageName] = minutes;
            } else {
              appTimeLimits.remove(packageName);
            }
          });
          await _saveTimeLimits();
          Navigator.of(context).pop();

          String message = '';
          if (blocked != isBlocked && minutes > 0) {
            message = blocked
                ? 'App blocked and time limit set to $minutes minutes'
                : 'App unblocked and time limit set to $minutes minutes';
          } else if (blocked != isBlocked) {
            message = blocked
                ? 'App blocked successfully'
                : 'App unblocked successfully';
          } else if (minutes > 0) {
            message = 'Time limit set to $minutes minutes';
          } else {
            message = 'Time limit removed';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFF7C3AED)),
          );
        },
      ),
    );
  }

  void _showExportOptions() {
    if (usageData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('No data available to export',
                      style: GoogleFonts.inter(fontSize: 14))),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ExportBottomSheet(
          usageData: usageData,
          chartKey: _weeklyChartKey,
          chartFilename:
              'analytics-chart-${DateTime.now().millisecondsSinceEpoch}.png',
          onSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.check, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('Export successful!',
                              style: GoogleFonts.inter(fontSize: 14))),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onError: (errorMsg) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(errorMsg,
                              style: GoogleFonts.inter(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B1B1B)
          : Colors.white,
      isScrollControlled: true,
    );
  }
}

class _AppOptionsDialog extends StatefulWidget {
  final String packageName;
  final String appName;
  final String usageTime;
  final bool isBlocked;
  final int? currentTimeLimit;
  final Function(bool blocked, int minutes) onApply;

  const _AppOptionsDialog({
    required this.packageName,
    required this.appName,
    required this.usageTime,
    required this.isBlocked,
    this.currentTimeLimit,
    required this.onApply,
  });

  @override
  State<_AppOptionsDialog> createState() => _AppOptionsDialogState();
}

class _AppOptionsDialogState extends State<_AppOptionsDialog> {
  late bool _isBlocked;
  late TextEditingController _timeLimitController;
  int? _selectedPresetLimit;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.isBlocked;
    _timeLimitController = TextEditingController(
      text: widget.currentTimeLimit?.toString() ?? '',
    );
    _selectedPresetLimit = widget.currentTimeLimit;
  }

  @override
  void dispose() {
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.shield,
                      color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appName,
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : Colors.black)),
                      Text('Current usage: ${widget.usageTime}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x,
                      color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isBlocked ? Colors.red : Colors.transparent,
                    width: 2),
              ),
              child: Row(
                children: [
                  Icon(_isBlocked ? LucideIcons.shieldOff : LucideIcons.shield,
                      color: _isBlocked
                          ? Colors.red
                          : const Color(0xFF7C3AED),
                      size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Block App',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Colors.black)),
                        Text(
                            _isBlocked
                                ? 'App is currently blocked'
                                : 'Prevent app from opening',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isBlocked,
                    onChanged: (value) =>
                        setState(() => _isBlocked = value),
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Daily Time Limit',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(15, isDark),
                _buildPresetChip(30, isDark),
                _buildPresetChip(60, isDark),
                _buildPresetChip(120, isDark),
                _buildPresetChip(180, isDark),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeLimitController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Custom limit (minutes)',
                      labelStyle: GoogleFonts.inter(color: Colors.grey),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon:
                          const Icon(LucideIcons.clock, color: Colors.grey),
                    ),
                    onChanged: (value) =>
                        setState(() => _selectedPresetLimit = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onApply(_isBlocked, 0),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: Text('Remove Limit',
                        style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final limit = _selectedPresetLimit ??
                          (int.tryParse(_timeLimitController.text) ?? 0);
                      widget.onApply(_isBlocked, limit);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Apply',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(int minutes, bool isDark) {
    final isSelected = _selectedPresetLimit == minutes;
    final hours = minutes >= 60 ? '${minutes ~/ 60}h' : '';
    final mins = minutes % 60 > 0 ? '${minutes % 60}m' : '';
    final label =
        hours.isEmpty ? mins : (mins.isEmpty ? hours : '$hours $mins');

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPresetLimit = selected ? minutes : null;
          _timeLimitController.text = selected ? minutes.toString() : '';
        });
      },
      selectedColor: const Color(0xFF7C3AED),
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.1),
      labelStyle: GoogleFonts.inter(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
