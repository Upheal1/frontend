import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../design_system/tokens/design_tokens.dart';
import '../features/community/services/community_supabase.dart';
import '../models/auth_model.dart';
import '../models/focus_session_model.dart';
import '../navigation/app_navigation_keys.dart';
import '../navigation/upheal_scaffold.dart';
import '../screens/app_blocked_screen.dart';
import '../services/app_blocking_service.dart';
import '../services/threat_monitor_service.dart';
import '../services/vpn_controller.dart';
import '../use_cases/evaluate_blocking_use_case.dart';
import '../viewmodels/blocked_app_view_model.dart';
import '../widgets/theme_toggle.dart';
import 'app_routes.dart';

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  static const MethodChannel _platform =
      MethodChannel('com.appguard.native_calls');

  final ThreatMonitorService _threatMonitor = ThreatMonitorService();

  bool _isBlockedScreenVisible = false;
  bool _assessmentCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _threatMonitor.startMonitoring();
    startUnifiedSecurityShield();
    _platform.setMethodCallHandler(_handleNativeCall);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assessmentCheckScheduled) {
      _assessmentCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _maybeShowAssessment();
        }
      });
    }
  }

  @override
  void dispose() {
    _platform.setMethodCallHandler(null);
    _threatMonitor.stopMonitoring();
    super.dispose();
  }

  Future<void> _maybeShowAssessment() async {
    final AuthModel authModel = context.read<AuthModel>();
    if (!authModel.isAuthenticated) {
      return;
    }

    final user = CommunitySupabase.clientOrNull?.auth.currentUser;
    if (user == null) {
      return;
    }

    final String currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == GadPhqRoute.path) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userKey = 'has_completed_assessment_${user.id}';
    bool hasCompleted = prefs.getBool(userKey) ?? false;

    if (!hasCompleted) {
      try {
        final row = await CommunitySupabase.clientOrNull
            ?.from('assessment_responses')
            .select('id')
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle();
        if (row != null) {
          hasCompleted = true;
          await prefs.setBool(userKey, true);
        }
      } catch (_) {}
    }

    if (!hasCompleted && mounted) {
      await const GadPhqRoute().push<void>(context);
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onThreatDetected') {
      final Map<String, dynamic> args =
          Map<String, dynamic>.from(call.arguments as Map);
      final double confidence = args['confidence'] as double? ?? 0;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Security Alert: Harmful text detected '
                  '(${(confidence * 100).toStringAsFixed(1)}%)',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          duration: AppMotion.messageVisible,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (call.method != 'onBlockEvent') {
      return;
    }

    final AppLifecycleState? lifecycleState =
        WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final BuildContext? appContext = appNavigatorKey.currentContext;
    if (!mounted || appContext == null || _isBlockedScreenVisible) {
      return;
    }

    final Map<String, dynamic> args =
        Map<String, dynamic>.from(call.arguments as Map);
    final String packageName = args['packageName'] as String? ?? '';

    final Map<String, dynamic> evaluation =
        EvaluateBlockingUseCase().execute(packageName);
    if (evaluation['isBlocked'] != true) {
      return;
    }

    final String? reasonStr = evaluation['reason'] as String?;
    final int remainingMinutes = evaluation['remainingMinutes'] as int? ?? 0;
    final bool canEmergency =
        evaluation['canEmergencyAllow'] as bool? ?? false;
    final bool hasUsedEmergency =
        evaluation['hasUsedEmergencyToday'] as bool? ?? false;

    BlockReasonType resolvedReason;
    if (reasonStr == 'daily_limit_reached') {
      resolvedReason = BlockReasonType.dailyLimitReached;
    } else if (reasonStr == 'blocked_by_user') {
      resolvedReason = BlockReasonType.blockedByUser;
    } else {
      final FocusSessionState focusState = appContext.read<FocusSessionState>();
      resolvedReason = focusState.isActive
          ? BlockReasonType.focusSessionActive
          : BlockReasonType.blockedByUser;
    }

    final rule = AppBlockingService.getRule(packageName);
    final String appName = rule?.appName ?? packageName.split('.').last;

    final BlockedAppViewModel viewModel = BlockedAppViewModel(
      packageName: packageName,
      appName: appName,
      reason: resolvedReason,
      remaining: Duration(minutes: remainingMinutes),
      canEmergencyAllow: canEmergency,
      hasUsedEmergencyToday: hasUsedEmergency,
      showTakeBreath: true,
      showReturnHome: true,
      onEmergencyAllow: () async {
        final allowResult = await EmergencyAllowUseCase().execute(packageName);
        if (allowResult['success'] != true) {
          throw Exception(allowResult['error'] as String? ?? 'Failed');
        }
      },
    );

    _isBlockedScreenVisible = true;
    Navigator.of(appContext)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AppBlockedScreen(
              viewModel: viewModel,
              onTakeBreath: () {
                rootScaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Take a slow breath in… and out.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              onReturnHome: () {
                const HomeRoute().go(appContext);
                Navigator.of(appContext).pop();
              },
            ),
            fullscreenDialog: true,
          ),
        )
        .then((_) => _isBlockedScreenVisible = false);
  }

  Future<void> startUnifiedSecurityShield() async {
    try {
      await _platform.invokeMethod('startGuardService');
      final List<String> blockedApps = AppBlockingService.getBlockedPackages();
      final List<String> domainsToBlock = <String>[];

      for (final String pkg in blockedApps) {
        if (pkg.contains('facebook')) {
          domainsToBlock.addAll(<String>[
            'facebook.com',
            'www.facebook.com',
            'm.facebook.com',
          ]);
        }
        if (pkg.contains('instagram')) {
          domainsToBlock.addAll(<String>[
            'instagram.com',
            'www.instagram.com',
          ]);
        }
        if (pkg.contains('tiktok')) {
          domainsToBlock.addAll(<String>[
            'tiktok.com',
            'www.tiktok.com',
            'm.tiktok.com',
          ]);
        }
        if (pkg.contains('youtube')) {
          domainsToBlock.addAll(<String>[
            'youtube.com',
            'www.youtube.com',
            'm.youtube.com',
            'youtu.be',
          ]);
        }
      }

      if (domainsToBlock.isNotEmpty) {
        await VpnController.startVpn(domainsToBlock);
      }
    } on PlatformException catch (e) {
      debugPrint('Unified Shield initialization failed: ${e.message}');
    } catch (e) {
      debugPrint('Shield error: $e');
    }
  }

  void _goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _goToDrawerRoute(AppRouteData route) {
    Navigator.of(context).pop();
    route.go(context);
  }

  void _goToRoute(AppRouteData route) {
    route.go(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppResponsiveInfo responsive = context.responsive;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = isDark ? AppColors.purple : AppColors.teal;
    final String location = GoRouterState.of(context).uri.path;
    final bool isAssessment = location.startsWith('/app/assessment');
    final bool useSidebar = responsive.useSidebarNavigation;

    final Widget shellBody = widget.navigationShell;

    if (useSidebar) {
      return Scaffold(
        key: rootScaffoldKey,
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Row(
          children: <Widget>[
            SizedBox(
              width: responsive.space(280, minScale: 1, maxScale: 1.2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161922) : Colors.white,
                  border: Border(
                    right: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: _ShellNavigationPanel(
                  location: location,
                  selectedColor: selectedColor,
                  isDark: isDark,
                  currentIndex: widget.navigationShell.currentIndex,
                  onBranchSelected: _goToBranch,
                  onRouteSelected: _goToRoute,
                ),
              ),
            ),
            Expanded(child: shellBody),
          ],
        ),
      );
    }

    return UpHealScaffold(
      hideNav: isAssessment,
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        child: _ShellNavigationPanel(
          location: location,
          selectedColor: selectedColor,
          isDark: isDark,
          currentIndex: widget.navigationShell.currentIndex,
          onBranchSelected: _goToBranch,
          onRouteSelected: _goToDrawerRoute,
        ),
      ),
      body: shellBody,
      currentIndex: widget.navigationShell.currentIndex,
      onTap: _goToBranch,
      onFab: () => _goToBranch(2),
    );
  }
}

class _ShellNavigationPanel extends StatelessWidget {
  const _ShellNavigationPanel({
    required this.location,
    required this.selectedColor,
    required this.isDark,
    required this.currentIndex,
    required this.onBranchSelected,
    required this.onRouteSelected,
  });

  final String location;
  final Color selectedColor;
  final bool isDark;
  final int currentIndex;
  final ValueChanged<int> onBranchSelected;
  final ValueChanged<AppRouteData> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    final AppResponsiveInfo responsive = context.responsive;
    final Set<String> primaryLocations = appBottomNavDestinations
        .map((AppBranchDestination item) => item.route.location)
        .toSet();
    final List<AppDrawerDestination> secondaryDestinations = appDrawerDestinations
        .where((AppDrawerDestination item) =>
            !primaryLocations.contains(item.route.location))
        .toList(growable: false);

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(
                responsive.space(AppSpacing.xxl, minScale: 1, maxScale: 1.2),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? <Color>[
                          AppColors.purple.withValues(alpha: 0.3),
                          AppColors.purple.withValues(alpha: 0.08),
                        ]
                      : <Color>[
                          AppColors.teal.withValues(alpha: 0.2),
                          AppColors.orange.withValues(alpha: 0.04),
                        ],
                ),
              ),
              child: Semantics(
                container: true,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: responsive.space(52, minScale: 1, maxScale: 1.05),
                      height: responsive.space(52, minScale: 1, maxScale: 1.05),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pill,
                        gradient: LinearGradient(
                          colors: isDark
                              ? <Color>[AppColors.purple, AppColors.orange]
                              : <Color>[AppColors.teal, AppColors.orange],
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: AppIconSizes.xl,
                      ),
                    ),
                    SizedBox(width: responsive.space(AppSpacing.lg)),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'UpHeal',
                              style: GoogleFonts.inter(
                                fontSize: responsive.isTabletOrWider ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              responsive.useSidebarNavigation
                                  ? 'Your calm control center'
                                  : 'Navigation menu',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.md),
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.sm),
              ),
              child: const ThemeToggle(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.sm),
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.xs),
              ),
              child: Text(
                'Primary',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final AppBranchDestination item = appBottomNavDestinations[index];
                final bool isSelected = currentIndex == index;
                return _NavigationTile(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  selectedColor: selectedColor,
                  isDark: isDark,
                  onTap: () => onBranchSelected(index),
                );
              },
              childCount: appBottomNavDestinations.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.lg),
                responsive.space(AppSpacing.xs),
              ),
              child: Text(
                'Tools',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: responsive.space(AppSpacing.lg)),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final AppDrawerDestination item = secondaryDestinations[index];
                  final bool isSelected = location.startsWith(item.route.location);
                  return _NavigationTile(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    selectedColor: selectedColor,
                    isDark: isDark,
                    onTap: () => onRouteSelected(item.route),
                  );
                },
                childCount: secondaryDestinations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppResponsiveInfo responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.space(AppSpacing.md),
        vertical: responsive.space(AppSpacing.xxxs, maxScale: 1.1),
      ),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: ListTile(
          minTileHeight: responsive.space(52, minScale: 1, maxScale: 1.08),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          leading: Icon(
            icon,
            color: isSelected
                ? selectedColor
                : (isDark ? Colors.white70 : AppColors.textPrimary),
            size: AppIconSizes.lg,
          ),
          title: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected
                  ? selectedColor
                  : (isDark ? Colors.white : AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: responsive.isTabletOrWider ? 16 : 15,
            ),
          ),
          selected: isSelected,
          selectedTileColor: selectedColor.withValues(alpha: 0.1),
          onTap: onTap,
        ),
      ),
    );
  }
}
