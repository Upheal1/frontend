import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/screen_time_service.dart';
import '../services/onboarding_service.dart';
import '../main.dart';
import '../services/error_handler_service.dart';
import '../services/export_service.dart';
import '../widgets/common/loading_overlay.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/analytics/offline_indicator.dart';
import '../widgets/analytics/export_bottom_sheet.dart';
import '../widgets/analytics/limited_functionality_banner.dart';
import 'onboarding/analytics_permission_onboarding.dart';
import '../widgets/drawer_menu_button.dart';
import 'comparison_screen.dart';
import 'insights_screen.dart';
import '../models/insight_model.dart';
import '../services/insights_service.dart';
import '../widgets/insights/insight_card.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.appguard.native_calls');
  
  bool _hasPermission = false;
  bool _isLoading = false;
  bool _hasCompletedOnboarding = true; // Assume completed until checked
  bool _showLimitedBanner = false;
  bool _pendingPermissionCheck = false; // Track if we need to recheck after resume
  List<Map<String, dynamic>> usageData = [];
  int totalScreenTime = 0;
  String _selectedTimePeriod = 'daily'; // 'daily', 'yesterday', 'weekly', 'monthly', '3months', '6months', '1year'
  
  // Insights preview
  List<Insight> _previewInsights = [];
  InsightsSummary? _insightsSummary;
  
  // GlobalKeys for charts (for export)
  final _weeklyChartKey = GlobalKey();
  
  // Blocked apps and time limits
  Set<String> blockedPackages = {};
  Map<String, int> appTimeLimits = {}; // packageName -> minutes

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
    // Re-check permission when app resumes from settings
    if (state == AppLifecycleState.resumed && _pendingPermissionCheck) {
      _pendingPermissionCheck = false;
      _checkPermission();
    }
  }

  Future<void> _checkOnboardingAndPermission() async {
    // First check if onboarding has been completed
    final hasCompletedOnboarding = await OnboardingService.hasCompletedAnalyticsOnboarding();
    
    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = hasCompletedOnboarding;
      });
    }
    
    if (!hasCompletedOnboarding) {
      // Show onboarding flow
      _showOnboardingFlow();
    } else {
      // Check permission directly
      await _checkPermission();
    }
  }

  Future<void> _showOnboardingFlow() async {
    if (!mounted) return;
    
    final result = await AnalyticsOnboardingDialog.show(context);
    
    if (result == true) {
      // User completed onboarding and wants to grant permission
      await _requestPermission();
    } else {
      // User skipped onboarding
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
      final hasPermission = await ScreenTimeService.checkUsageStatsPermission();
      if (!mounted) return;
      setState(() {
        _hasPermission = hasPermission;
        // Show limited banner if no permission and onboarding is complete
        _showLimitedBanner = !hasPermission && _hasCompletedOnboarding;
      });
      if (hasPermission) {
        setState(() {
          _showLimitedBanner = false;
        });
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
      // Set flag to recheck permission when app resumes
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
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
      }

      // Note: Period selection is handled by the service internally

      List<Map<String, dynamic>> realUsageStats;
      if (_selectedTimePeriod == 'weekly') {
        realUsageStats = await ScreenTimeService.getBetterWeeklyUsage();
      } else {
        realUsageStats = await ScreenTimeService.getUltraAccurateUsageStats(period: _selectedTimePeriod);
      }
      
      // Debug: Print detailed information about the data
      print('=== USAGE STATS DEBUG ===');
      print('Total apps found: ${realUsageStats.length}');
      
      if (realUsageStats.isNotEmpty) {
        print('Sample usage data: ${realUsageStats.first}');
        
        // Show top 5 apps with their raw data
        final sortedStats = List.from(realUsageStats)
          ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
        
        print('Top 5 apps by usage:');
        for (int i = 0; i < 5 && i < sortedStats.length; i++) {
          final app = sortedStats[i];
          final rawTime = app['usageTime'] as int;
          final timeInSeconds = rawTime ~/ 1000;
          final timeInMinutes = timeInSeconds ~/ 60;
          final timeInHours = timeInMinutes ~/ 60;
          
          print('${i + 1}. ${app['appName']}: $rawTime ms = $timeInSeconds sec = $timeInMinutes min = $timeInHours hours');
        }
      }
      
      if (mounted) {
        setState(() {
          usageData = realUsageStats.where((d) => d['usageTime'] > 0).toList()
            ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
          // Convert milliseconds to seconds for display
          totalScreenTime = realUsageStats.fold(0, (sum, item) => sum + ((item['usageTime'] as int) ~/ 1000));
          
          // Debug: Print the calculated total time
          print('=== CALCULATED TOTALS ===');
          print('Total screen time (seconds): $totalScreenTime');
          print('Total screen time (minutes): ${totalScreenTime / 60}');
          print('Total screen time (hours): ${totalScreenTime / 3600}');
          print('Apps with usage: ${usageData.length}');
        });
      }
    } catch (e) {
      errors.showError('Failed to load usage stats: $e');
    } finally {
      if (showSpinner) {
        errors.hideLoading();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      // Load insights preview after usage data is loaded
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InsightsScreen(),
      ),
    );
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
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To view real screen time data, please:',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Tap "Open Settings" below',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Look for "my_app" in the list',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3. If you don\'t see "my_app", scroll down or search',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '4. Toggle "Permit usage access" ON',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '5. Return to the app',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUsageStatsSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openUsageStatsSettings() {
    // Set flag to recheck permission when app resumes
    _pendingPermissionCheck = true;
    ScreenTimeService.requestUsageStatsPermission();
  }

  @override
  Widget build(BuildContext context) {
    final handler = context.watch<ErrorHandlerModel>();
    final isBusy = handler.isLoading || _isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111318) : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardColor = isDark ? const Color(0xFF1A1F26) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const DrawerMenuButton(iconColor: Colors.white),
        title: Text(
          'Screen Time Analytics',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToInsights,
            icon: Icon(LucideIcons.sparkles, color: textColor),
            tooltip: 'AI Insights',
          ),
          IconButton(
            onPressed: _navigateToComparison,
            icon: Icon(LucideIcons.gitCompare, color: textColor),
            tooltip: 'Compare Trends',
          ),
          IconButton(
            onPressed: () async {
              await _loadUsageStats();
            },
            icon: Icon(LucideIcons.refreshCw, color: textColor),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: _showExportOptions,
            icon: Icon(LucideIcons.share2, color: textColor),
            tooltip: 'Export & Share',
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show limited functionality banner if onboarding was completed but permission denied
            if (_showLimitedBanner)
              LimitedFunctionalityBanner(
                onEnablePressed: _showOnboardingFlow,
                onDismiss: () {
                  setState(() {
                    _showLimitedBanner = false;
                  });
                },
              ),
            if (_showLimitedBanner) const SizedBox(height: 16),
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
            subtitle: 'Use your device for a bit or refresh to pull today\'s stats.',
            actionText: 'Refresh',
            onAction: _onRefresh,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTimePeriodSelector(),
          const SizedBox(height: 20),
          _buildInsightsPreviewCard(),
          const SizedBox(height: 20),
          _buildOverviewCards(),
          const SizedBox(height: 20),
          _buildUsageChart(),
          const SizedBox(height: 20),
          _buildAppUsageBarChart(),
          const SizedBox(height: 20),
          _buildTopApps(),
        ],
      ),
    );
  }

  Widget _buildInsightsPreviewCard() {
    if (_insightsSummary == null && _previewInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.15),
            const Color(0xFF2563EB).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (_insightsSummary != null)
                      Text(
                        'Wellness Score: ${_insightsSummary!.overallHealthScore.toStringAsFixed(0)}/100',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _insightsSummary!.healthColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // View All button
              TextButton.icon(
                onPressed: _navigateToInsights,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  LucideIcons.arrowRight,
                  size: 14,
                  color: textColor,
                ),
                label: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Preview insights
          if (_previewInsights.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._previewInsights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInsightPreviewItem(insight),
            )),
          ],
          
          // Summary stats
          if (_insightsSummary != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInsightStatChip(
                  '${_insightsSummary!.positiveCount} positive',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _buildInsightStatChip(
                  '${_insightsSummary!.warningCount} warnings',
                  const Color(0xFFFF9800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightPreviewItem(Insight insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    final bgColor = isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade100;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: insight.categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.categoryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  insight.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: subtextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1F26) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F36) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        border: Border.all(color: borderColor),
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
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  border: Border.all(
                    color: const Color(0xFF7C3AED),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      color: Color(0xFF7C3AED),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(totalScreenTime),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePeriodButton('Today', 'daily', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Yesterday', 'yesterday', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Weekly', 'weekly', LucideIcons.calendarDays),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Monthly', 'monthly', LucideIcons.calendarRange),
                const SizedBox(width: 8),
                _buildTimePeriodButton('3 Months', '3months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('6 Months', '6months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('1 Year', '1year', LucideIcons.calendar),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedTimePeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF2A2F36) : Colors.grey.shade100;
    final unselectedBorder = isDark ? const Color(0xFF3A3F46) : Colors.grey.shade300;
    final unselectedText = isDark ? Colors.grey.shade400 : const Color(0xFF475569);
    
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedTimePeriod = value;
        });
        // Force fresh data for new period
        ScreenTimeService.invalidateCaches();
        await _loadUsageStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF7C3AED) : unselectedBg,
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : unselectedBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : unselectedText,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : unselectedText,
              ),
            ),
          ],
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
              Text(
                'Usage Data Debug Info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Permission Status: ${_hasPermission ? "Granted" : "Not Granted"}',
            style: GoogleFonts.inter(fontSize: 12, color: textColor),
          ),
          Text(
            'Data Count: ${usageData.length} apps',
            style: GoogleFonts.inter(fontSize: 12, color: textColor),
          ),
          Text(
            'Total Time: ${_formatTime(totalScreenTime)}',
            style: GoogleFonts.inter(fontSize: 12, color: textColor),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final realStats = await ScreenTimeService.getUltraAccurateUsageStats(period: _selectedTimePeriod);
                final totalTimeMs = realStats.fold(0, (sum, item) => sum + (item['usageTime'] as int));
                final totalTimeHours = totalTimeMs / (1000 * 60 * 60);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found ${realStats.length} apps. Total time: ${totalTimeHours.toStringAsFixed(2)} hours'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Validation failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 32),
            ),
            child: Text(
              'Validate Data Accuracy',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
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
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
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
                child: const Icon(
                  LucideIcons.shield,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enable Usage Access',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To view real screen time data, please enable usage access permission.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.shield),
                  label: Text(
                    _isLoading ? 'Requesting...' : 'Enable Usage Access',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,  // Keep white for button
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    String timeLabel;
    switch (_selectedTimePeriod) {
      case 'yesterday':
        timeLabel = 'Yesterday';
        break;
      case 'weekly':
        timeLabel = 'This Week';
        break;
      case 'monthly':
        timeLabel = 'This Month';
        break;
      case '3months':
        timeLabel = 'Last 3 Months';
        break;
      case '6months':
        timeLabel = 'Last 6 Months';
        break;
      case '1year':
        timeLabel = 'Last Year';
        break;
      default:
        timeLabel = 'Today';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: timeLabel,
            value: _formatTime(totalScreenTime),
            icon: LucideIcons.clock,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Apps Used',
            value: '${usageData.length}',
            icon: LucideIcons.smartphone,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor1 = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50;
    final cardBgColor2 = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgColor1,
            cardBgColor2,
          ],
        ),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusScoreCard() {
    final focusScore = _calculateFocusScore();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final progressBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isDark ? 0.1 : 0.05),
            Colors.white.withOpacity(isDark ? 0.05 : 0.02),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.2 : 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(LucideIcons.target, color: textColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Focus Score',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: focusScore / 100,
                      strokeWidth: 8,
                      backgroundColor: progressBgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(focusScore),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$focusScore',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getScoreMessage(focusScore),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1F26) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F36) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF475569);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadComparisonData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cardColor,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data['current'] == null) {
          return const SizedBox.shrink();
        }

        final currentData = data['current'] as List<Map<String, dynamic>>;
        final previousData = data['previous'] as List<Map<String, dynamic>>? ?? [];

        // Find max value for Y axis
        double maxY = 0;
        for (final point in currentData) {
          final hours = point['usageHours'] as double;
          if (hours > maxY) maxY = hours;
        }
        for (final point in previousData) {
          final hours = point['usageHours'] as double;
          if (hours > maxY) maxY = hours;
        }
        maxY = (maxY * 1.2).ceilToDouble();
        if (maxY < 1) maxY = 1;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cardColor,
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.lineChart,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Usage Trend',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Legend
              Row(
                children: [
                  _buildLegendItem('This Week', const Color(0xFF7C3AED)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Last Week', const Color(0xFF9CA3AF)),
                ],
              ),
              const SizedBox(height: 20),
              RepaintBoundary(
                key: _weeklyChartKey,
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxY / 4,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toStringAsFixed(1)}h',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : const Color(0xFF64748B),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < currentData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  currentData[index]['dayLabel'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (currentData.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      // Current week line
                      LineChartBarData(
                        spots: List.generate(currentData.length, (i) {
                          return FlSpot(
                              i.toDouble(), currentData[i]['usageHours'] as double);
                        }),
                        isCurved: true,
                        color: const Color(0xFF7C3AED),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF7C3AED),
                              strokeWidth: 2,
                              strokeColor: isDark ? Colors.white : const Color(0xFFFFFFFF),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                        ),
                      ),
                      // Previous week line
                      if (previousData.isNotEmpty)
                        LineChartBarData(
                          spots: List.generate(previousData.length, (i) {
                            return FlSpot(
                                i.toDouble(), previousData[i]['usageHours'] as double);
                          }),
                          isCurved: true,
                          color: const Color(0xFF9CA3AF),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dashArray: [5, 5],
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFF9CA3AF),
                                strokeWidth: 0,
                              );
                            },
                          ),
                        ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            const Color(0xFF3A3A3A),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isCurrentPeriod = spot.barIndex == 0;
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}h',
                              GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCurrentPeriod
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFF9CA3AF),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
           ) ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white54 
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadComparisonData() async {
    try {
      // Load current week (last 7 days)
      final currentWeekData = await ScreenTimeService.getDailyUsageForTrend();
      
      // Load previous week (8-14 days ago)
      final previousWeekData = await ScreenTimeService.getDailyUsageForPreviousWeek();
      
      // Format the data for the chart
      final List<Map<String, dynamic>> current = [];
      final List<Map<String, dynamic>> previous = [];
      
      const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      // Process current week
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
      
      // Process previous week
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
      
      return {
        'current': current,
        'previous': previous,
      };
    } catch (e) {
      print('Error loading comparison data: $e');
      // Return empty data on error
      const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return {
        'current': List.generate(7, (i) => {
          'dayLabel': daysOfWeek[i],
          'usageHours': 0.0,
        }),
        'previous': [],
      };
    }
  }

  Widget _buildAppUsageBarChart() {
    if (usageData.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor1 = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50;
    final cardBgColor2 = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;

    // Get top 10 apps for the chart
    final topApps = usageData.take(10).toList();
    final maxUsage = topApps.isNotEmpty 
        ? (topApps[0]['usageTime'] as int) ~/ 1000 
        : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgColor1,
            cardBgColor2,
          ],
        ),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'App Usage Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxUsage.toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final app = topApps[group.x.toInt()];
                      return BarTooltipItem(
                        '${app['appName']}\n',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: _formatTime((app['usageTime'] as int) ~/ 1000),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= topApps.length) {
                          return const SizedBox.shrink();
                        }
                        final app = topApps[value.toInt()];
                        final appName = app['appName'] as String;
                        // Show first 3 characters of app name
                        final displayName = appName.length > 3 
                            ? appName.substring(0, 3) 
                            : appName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final hours = value ~/ 3600;
                        final minutes = (value % 3600) ~/ 60;
                        if (hours > 0) {
                          return Text(
                            '${hours}h',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          );
                        } else {
                          return Text(
                            '${minutes}m',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxUsage / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topApps.length, (index) {
                  final app = topApps[index];
                  final usageSeconds = (app['usageTime'] as int) ~/ 1000;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: usageSeconds.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7C3AED),
                            const Color(0xFF2563EB),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopApps() {
    final topApps = _getTopApps();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor1 = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50;
    final cardBgColor2 = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgColor1,
            cardBgColor2,
          ],
        ),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.smartphone, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Most Used Apps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topApps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _AppIconWidget(
                  packageName: app['packageName'] as String,
                  appName: app['name'] as String,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        app['time'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time limit indicator
                    if (appTimeLimits.containsKey(app['packageName']))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF7C3AED),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              color: Color(0xFF7C3AED),
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${appTimeLimits[app['packageName']]}m',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Blocked indicator
                    if (blockedPackages.contains(app['packageName']))
                      const Icon(
                        LucideIcons.shieldOff,
                        color: Colors.red,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    // Options button
                    IconButton(
                      onPressed: () {
                        _showAppOptionsDialog(
                          app['packageName'] as String,
                          app['name'] as String,
                          app['time'] as String,
                        );
                      },
                      icon: const Icon(
                        LucideIcons.shield,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }



  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds secs';
    final int minutes = totalSeconds ~/ 60;
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours} hr ${remainingMinutes} mins';
    } else if (minutes > 0) {
      return '${minutes} mins';
    } else {
      return '$totalSeconds secs';
    }
  }

  int _calculateFocusScore() {
    if (usageData.isEmpty) return 0;
    
    // Simple focus score calculation based on app diversity and total time
    final productiveApps = usageData.where((app) {
      final appName = app['appName'] as String;
      return appName.toLowerCase().contains('chrome') ||
        appName.toLowerCase().contains('notes') ||
        appName.toLowerCase().contains('calendar') ||
        appName.toLowerCase().contains('email');
    }).length;
    
    final totalApps = usageData.length;
    final productiveRatio = totalApps > 0 ? productiveApps / totalApps : 0;
    
    // Base score from productive ratio, adjusted by total time
    final baseScore = (productiveRatio * 100).round();
    final timeAdjustment = totalScreenTime > 3600 ? -10 : 0; // Penalty for excessive usage
    
    return (baseScore + timeAdjustment).clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent focus! Keep it up!';
    if (score >= 60) return 'Good focus, room for improvement';
    if (score >= 40) return 'Moderate focus, try to reduce distractions';
    return 'Low focus, consider blocking more apps';
  }


  List<FlSpot> _generateWeeklyData() {
    // This will be replaced with real data loading
    return List.generate(7, (index) {
      final baseHours = (totalScreenTime / 3600) / 7; // Distribute current usage across week
      final randomVariation = (index % 3 - 1) * 0.5;
      return FlSpot(index.toDouble(), (baseHours + randomVariation).clamp(0.0, 12.0));
    });
  }

  // Load real weekly trend data
  Future<List<FlSpot>> _loadWeeklyTrendData() async {
    try {
      final dailyData = await ScreenTimeService.getDailyUsageForTrend();
      
      if (dailyData.isEmpty) {
        // Fallback to generated data if no real data available
        return _generateWeeklyData();
      }
      
      // Convert real daily data to chart spots
      List<FlSpot> spots = [];
      for (var day in dailyData) {
        final dayNumber = day['day'] as int;
        final totalHours = day['totalHours'] as double;
        spots.add(FlSpot(dayNumber.toDouble(), totalHours));
      }
      
      print('=== WEEKLY TREND CHART DATA ===');
      for (int i = 0; i < spots.length; i++) {
        print('Day ${i + 1}: ${spots[i].y.toStringAsFixed(2)} hours');
      }
      
      return spots;
    } catch (e) {
      print('Error loading weekly trend data: $e');
      return _generateWeeklyData();
    }
  }

  List<Map<String, dynamic>> _getTopApps() {
    return usageData.take(5).map((app) => {
          'name': app['appName'] as String,
          'packageName': app['packageName'] as String,
          'time': _formatTime((app['usageTime'] as int) ~/ 1000), // Convert ms to seconds
        }).toList();
  }

  // Load blocked apps from native
  Future<void> _loadBlockedApps() async {
    try {
      final blocked = await platform.invokeMethod('getBlockedApps');
      setState(() {
        blockedPackages = Set<String>.from(blocked);
      });
    } catch (e) {
      print('Error loading blocked apps: $e');
    }
  }

  // Load time limits from SharedPreferences
  Future<void> _loadTimeLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limitsJson = prefs.getString('app_time_limits');
      if (limitsJson != null) {
        final Map<String, dynamic> decoded = json.decode(limitsJson);
        setState(() {
          appTimeLimits = decoded.map((key, value) => MapEntry(key, value as int));
        });
      }
    } catch (e) {
      print('Error loading time limits: $e');
    }
  }

  // Save time limits to SharedPreferences
  Future<void> _saveTimeLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_time_limits', json.encode(appTimeLimits));
    } catch (e) {
      print('Error saving time limits: $e');
    }
  }

  // Toggle app blocking
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
            content: Text(isBlocked ? 'App blocked successfully' : 'App unblocked successfully'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      print('Error toggling app block: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show app options dialog (block/time limit)
  void _showAppOptionsDialog(String packageName, String appName, String usageTime) {
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
          // Apply block status
          if (blocked != isBlocked) {
            await _toggleAppBlock(packageName, blocked);
          }
          
          // Apply time limit
          setState(() {
            if (minutes > 0) {
              appTimeLimits[packageName] = minutes;
            } else {
              appTimeLimits.remove(packageName);
            }
          });
          await _saveTimeLimits();
          
          Navigator.of(context).pop();
          
          // Show success message
          String message = '';
          if (blocked != isBlocked && minutes > 0) {
            message = blocked 
                ? 'App blocked and time limit set to $minutes minutes'
                : 'App unblocked and time limit set to $minutes minutes';
          } else if (blocked != isBlocked) {
            message = blocked ? 'App blocked successfully' : 'App unblocked successfully';
          } else if (minutes > 0) {
            message = 'Time limit set to $minutes minutes';
          } else {
            message = 'Time limit removed';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF7C3AED),
            ),
          );
        },
      ),
    );
  }

  /// Show export options bottom sheet
  void _showExportOptions() {
    if (usageData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No data available to export',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
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
          chartFilename: 'analytics-chart-${DateTime.now().millisecondsSinceEpoch}.png',
          onSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.check, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Export successful!',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
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
                      const Icon(LucideIcons.alertCircle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMsg,
                          style: GoogleFonts.inter(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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



// Widget to display actual app icons
class _AppIconWidget extends StatefulWidget {
  final String packageName;
  final String appName;
  final double size;

  const _AppIconWidget({
    required this.packageName,
    required this.appName,
    required this.size,
  });

  @override
  State<_AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<_AppIconWidget> {
  static const MethodChannel _platform = MethodChannel('com.appguard.native_calls');
  static final Map<String, Uint8List?> _iconCache = {};

  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    // Try cache first
    _iconBytes = _iconCache[widget.packageName];
    if (_iconBytes == null) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    try {
      final bytes = await _platform.invokeMethod('getAppIcon', {
        'packageName': widget.packageName,
      });
      if (!mounted) return;
      if (bytes != null) {
        setState(() {
          _iconBytes = bytes as Uint8List;
          _iconCache[widget.packageName] = _iconBytes;
        });
      }
    } catch (e) {
      // Fallback to placeholder icon
      debugPrint('Icon load failed for ${widget.packageName}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getAppColor(widget.appName).withOpacity(0.3);
    final bgColor = _getAppColor(widget.appName).withOpacity(0.1);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.18),
        child: _iconBytes != null
            ? Image.memory(
                _iconBytes!,
                fit: BoxFit.cover,
              )
            : Icon(
                _getAppIcon(widget.appName),
                size: widget.size * 0.6,
                color: _getAppColor(widget.appName),
              ),
      ),
    );
  }

  Color _getAppColor(String appName) {
    if (appName.contains('Instagram')) return Colors.blueAccent;
    if (appName.contains('YouTube')) return Colors.red;
    if (appName.contains('Chrome')) return Colors.orange;
    if (appName.contains('Discord')) return Colors.purple;
    if (appName.contains('Spotify')) return Colors.green;
    if (appName.contains('TikTok')) return Colors.black;
    if (appName.contains('Facebook')) return Colors.blue;
    if (appName.contains('Twitter')) return Colors.lightBlue;
    if (appName.contains('Snapchat')) return Colors.yellow;
    if (appName.contains('WhatsApp')) return Colors.green;
    if (appName.contains('Telegram')) return Colors.blue;
    if (appName.contains('Netflix')) return Colors.red;
    if (appName.contains('Gmail')) return Colors.red;
    if (appName.contains('Maps')) return Colors.green;
    if (appName.contains('Photos')) return Colors.blue;
    if (appName.contains('Calendar')) return Colors.blue;
    if (appName.contains('Drive')) return Colors.blue;
    if (appName.contains('Zoom')) return Colors.blue;
    if (appName.contains('Slack')) return Colors.purple;
    if (appName.contains('Uber')) return Colors.black;
    if (appName.contains('Airbnb')) return Colors.red;
    if (appName.contains('Pinterest')) return Colors.red;
    if (appName.contains('Reddit')) return Colors.orange;
    if (appName.contains('LinkedIn')) return Colors.blue;
    if (appName.contains('GitHub')) return Colors.black;
    if (appName.contains('Medium')) return Colors.black;
    if (appName.contains('Quora')) return Colors.red;
    if (appName.contains('Tumblr')) return Colors.blue;
    if (appName.contains('Flickr')) return Colors.pink;
    if (appName.contains('VSCO')) return Colors.black;
    if (appName.contains('Lightroom')) return Colors.purple;
    if (appName.contains('Snapseed')) return Colors.blue;
    if (appName.contains('Canva')) return Colors.blue;
    if (appName.contains('Adobe')) return Colors.red;
    if (appName.contains('Kindle')) return Colors.orange;
    if (appName.contains('Audible')) return Colors.orange;
    if (appName.contains('Podcasts')) return Colors.purple;
    if (appName.contains('SoundCloud')) return Colors.orange;
    if (appName.contains('Pandora')) return Colors.pink;
    if (appName.contains('iHeartRadio')) return Colors.red;
    if (appName.contains('Fitness')) return Colors.green;
    if (appName.contains('Strava')) return Colors.orange;
    if (appName.contains('Nike')) return Colors.black;
    if (appName.contains('Stack')) return Colors.orange;
    if (appName.contains('Teams')) return Colors.blue;
    if (appName.contains('Skype')) return Colors.blue;
    if (appName.contains('Trello')) return Colors.blue;
    if (appName.contains('Notion')) return Colors.black;
    if (appName.contains('Evernote')) return Colors.green;
    if (appName.contains('Keep')) return Colors.yellow;
    if (appName.contains('Duo')) return Colors.blue;
    if (appName.contains('Messages')) return Colors.green;
    if (appName.contains('Firefox')) return Colors.orange;
    if (appName.contains('Opera')) return Colors.red;
    if (appName.contains('Edge')) return Colors.blue;
    if (appName.contains('Samsung')) return Colors.blue;
    if (appName.contains('Books')) return Colors.orange;
    if (appName.contains('Meet')) return Colors.green;
    if (appName.contains('Translate')) return Colors.blue;
    if (appName.contains('Docs')) return Colors.blue;
    if (appName.contains('Excel')) return Colors.green;
    if (appName.contains('Word')) return Colors.blue;
    if (appName.contains('PowerPoint')) return Colors.orange;
    if (appName.contains('DoorDash')) return Colors.red;
    if (appName.contains('Grubhub')) return Colors.orange;
    if (appName.contains('Booking')) return Colors.blue;
    if (appName.contains('Layout')) return Colors.purple;
    if (appName.contains('Boomerang')) return Colors.blue;
    if (appName.contains('Hyperlapse')) return Colors.purple;
    
    return Colors.teal;
  }

  IconData _getAppIcon(String appName) {
    final lowerName = appName.toLowerCase();
    
    if (lowerName.contains('tiktok')) return LucideIcons.music;
    if (lowerName.contains('instagram')) return LucideIcons.camera;
    if (lowerName.contains('youtube')) return LucideIcons.play;
    if (lowerName.contains('facebook')) return LucideIcons.facebook;
    if (lowerName.contains('twitter')) return LucideIcons.twitter;
    if (lowerName.contains('snapchat')) return LucideIcons.camera;
    if (lowerName.contains('whatsapp')) return LucideIcons.messageCircle;
    if (lowerName.contains('telegram')) return LucideIcons.send;
    if (lowerName.contains('discord')) return LucideIcons.messageSquare;
    if (lowerName.contains('spotify')) return LucideIcons.music;
    if (lowerName.contains('netflix')) return LucideIcons.tv;
    if (lowerName.contains('chrome')) return LucideIcons.globe;
    if (lowerName.contains('gmail')) return LucideIcons.mail;
    if (lowerName.contains('maps')) return LucideIcons.mapPin;
    if (lowerName.contains('photos')) return LucideIcons.image;
    if (lowerName.contains('calendar')) return LucideIcons.calendar;
    if (lowerName.contains('drive')) return LucideIcons.folder;
    if (lowerName.contains('zoom')) return LucideIcons.video;
    if (lowerName.contains('slack')) return LucideIcons.messageSquare;
    if (lowerName.contains('uber')) return LucideIcons.car;
    if (lowerName.contains('airbnb')) return LucideIcons.home;
    if (lowerName.contains('pinterest')) return LucideIcons.pin;
    if (lowerName.contains('reddit')) return LucideIcons.messageCircle;
    if (lowerName.contains('linkedin')) return LucideIcons.linkedin;
    if (lowerName.contains('github')) return LucideIcons.github;
    if (lowerName.contains('medium')) return LucideIcons.bookOpen;
    if (lowerName.contains('quora')) return LucideIcons.helpCircle;
    if (lowerName.contains('tumblr')) return LucideIcons.messageSquare;
    if (lowerName.contains('flickr')) return LucideIcons.image;
    if (lowerName.contains('vsco')) return LucideIcons.camera;
    if (lowerName.contains('lightroom')) return LucideIcons.image;
    if (lowerName.contains('snapseed')) return LucideIcons.image;
    if (lowerName.contains('canva')) return LucideIcons.palette;
    if (lowerName.contains('adobe')) return LucideIcons.image;
    if (lowerName.contains('kindle')) return LucideIcons.book;
    if (lowerName.contains('audible')) return LucideIcons.headphones;
    if (lowerName.contains('podcasts')) return LucideIcons.podcast;
    if (lowerName.contains('soundcloud')) return LucideIcons.music;
    if (lowerName.contains('pandora')) return LucideIcons.music;
    if (lowerName.contains('iheartradio')) return LucideIcons.radio;
    if (lowerName.contains('fitness')) return LucideIcons.activity;
    if (lowerName.contains('strava')) return LucideIcons.activity;
    if (lowerName.contains('nike')) return LucideIcons.activity;
    if (lowerName.contains('stack')) return LucideIcons.code;
    if (lowerName.contains('teams')) return LucideIcons.users;
    if (lowerName.contains('skype')) return LucideIcons.video;
    if (lowerName.contains('trello')) return LucideIcons.trello;
    if (lowerName.contains('notion')) return LucideIcons.fileText;
    if (lowerName.contains('evernote')) return LucideIcons.fileText;
    if (lowerName.contains('keep')) return LucideIcons.stickyNote;
    if (lowerName.contains('duo')) return LucideIcons.video;
    if (lowerName.contains('messages')) return LucideIcons.messageCircle;
    if (lowerName.contains('firefox')) return LucideIcons.globe;
    if (lowerName.contains('opera')) return LucideIcons.globe;
    if (lowerName.contains('edge')) return LucideIcons.globe;
    if (lowerName.contains('samsung')) return LucideIcons.globe;
    if (lowerName.contains('books')) return LucideIcons.book;
    if (lowerName.contains('meet')) return LucideIcons.video;
    if (lowerName.contains('translate')) return LucideIcons.languages;
    if (lowerName.contains('docs')) return LucideIcons.fileText;
    if (lowerName.contains('excel')) return LucideIcons.table;
    if (lowerName.contains('word')) return LucideIcons.fileText;
    if (lowerName.contains('powerpoint')) return LucideIcons.presentation;
    if (lowerName.contains('doordash')) return LucideIcons.truck;
    if (lowerName.contains('grubhub')) return LucideIcons.truck;
    if (lowerName.contains('booking')) return LucideIcons.bed;
    if (lowerName.contains('layout')) return LucideIcons.layout;
    if (lowerName.contains('boomerang')) return LucideIcons.rotateCcw;
    if (lowerName.contains('hyperlapse')) return LucideIcons.fastForward;
    
    // Default icon for unknown apps
    return LucideIcons.smartphone;
  }
}

// App Options Dialog Widget
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    color: Color(0xFF7C3AED),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Current usage: ${widget.usageTime}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Block Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isBlocked ? Colors.red : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isBlocked ? LucideIcons.shieldOff : LucideIcons.shield,
                    color: _isBlocked ? Colors.red : const Color(0xFF7C3AED),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Block App',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _isBlocked ? 'App is currently blocked' : 'Prevent app from opening',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isBlocked,
                    onChanged: (value) {
                      setState(() {
                        _isBlocked = value;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Time Limit Section
            Text(
              'Daily Time Limit',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Preset limits
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
            
            // Custom time input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeLimitController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Custom limit (minutes)',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(
                        LucideIcons.clock,
                        color: Colors.grey,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedPresetLimit = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Remove limit and apply
                      widget.onApply(_isBlocked, 0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    child: Text(
                      'Remove Limit',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Get the limit value
                      final limit = _selectedPresetLimit ?? 
                          (int.tryParse(_timeLimitController.text) ?? 0);
                      
                      // Call single callback with both values
                      widget.onApply(_isBlocked, limit);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    final label = hours.isEmpty ? mins : (mins.isEmpty ? hours : '$hours $mins');

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
