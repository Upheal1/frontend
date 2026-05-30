import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'models/mission_model.dart';
import 'models/user_model.dart';
import 'models/auth_model.dart';
import 'models/parental_control_model.dart';
import 'models/screen_time_model.dart';
import 'models/sleep_model.dart';
import 'models/theme_model.dart';
import 'models/streak_model.dart';
import 'services/error_handler_service.dart';
import 'services/streak_service.dart';
import 'features/steps/state/step_tracker_state.dart';
import 'features/steps/ui/screens/step_tracker_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/your_insights_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parental_control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/sleep_tracker_screen.dart';
import 'screens/block_apps_screen.dart';
import 'screens/app_blocked_screen.dart';
import 'screens/gad_phq_form_screen.dart'; // Used in optional auto-push (see initState)
import 'screens/my_assessment_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'models/journal_model.dart';
import 'services/journal_service.dart';
import 'services/journal_local_service.dart';
import 'services/journal_api_service.dart';
import 'models/mood_model.dart';
import 'services/mood_service.dart';
import 'services/mood_local_service.dart';
import 'services/mood_api_service.dart';
import 'screens/mood_tracker_screen.dart';
import 'services/screen_time_service.dart';
import 'services/screen_time_notification_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/usage_cache_service.dart';
import 'models/hive/app_usage_cache.dart';
import 'models/hive/focus_session_history.dart';
import 'models/hive/block_rule.dart';
import 'models/focus_session_model.dart';
import 'services/focus_session_service.dart';
import 'services/app_blocking_service.dart';
import 'use_cases/evaluate_blocking_use_case.dart';
import 'models/notification_types.dart';
import 'widgets/theme_switcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'widgets/common/error_snackbar.dart';
import 'models/navigation_model.dart';
import 'viewmodels/blocked_app_view_model.dart';
import 'services/reward_orchestrator.dart';
import 'services/challenge_service.dart';
import 'services/badge_provider.dart';
import 'widgets/rewards/reward_listener.dart';
import 'screens/achievements_screen.dart';
import 'models/achievement.dart';
import 'avatar/ui/avatar_screen.dart';
import 'avatar/services/avatar_provider.dart';
import 'screens/badges_screen.dart';

/// ✅ NEW SERVICES
import 'services/threat_monitor_service.dart';
import 'services/vpn_controller.dart';

/// Global navigator key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// Global key to control the root Scaffold (for opening the drawer from child screens)
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Initialize Hive for local storage
  try {
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(AppUsageCacheAdapter());
    Hive.registerAdapter(FocusSessionTypeAdapter());
    Hive.registerAdapter(FocusSessionHistoryAdapter());
    Hive.registerAdapter(BlockRuleAdapter());
    Hive.registerAdapter(DailyUsageAdapter());

    debugPrint('Hive initialized and adapters registered');
  } catch (e) {
    debugPrint('Hive initialization error: $e');
    // Continue even if Hive fails to initialize
  }

  // Initialize usage cache service
  final cacheService = UsageCacheService();
  try {
    await cacheService.initialize();
    ScreenTimeService.setCacheService(cacheService);

    // Clear old cache (keep last 30 days)
    await cacheService.clearOldCache(daysToKeep: 30);

    debugPrint('UsageCacheService initialized');
  } catch (e) {
    debugPrint('UsageCacheService initialization error: $e');
  }

  // Initialize app blocking service
  try {
    await AppBlockingService.initialize();
    // Clear old usage data (keep last 30 days)
    await AppBlockingService.clearOldUsage(daysToKeep: 30);
    debugPrint('AppBlockingService initialized');
  } catch (e) {
    debugPrint('AppBlockingService initialization error: $e');
  }

  try {
    await SupabaseAuthService.initialize();
    if (SupabaseAuthService.isInitialized) {
      debugPrint('Supabase auth initialized successfully');
    }
  } catch (e) {
    debugPrint('Supabase auth initialization error: $e');
  }

  try {
    await ScreenTimeNotificationService.initialize();
    debugPrint('Screen time notifications initialized successfully');
  } catch (e) {
    debugPrint('Screen time notifications initialization error: $e');
  }

  try {
    await NotificationService.initialize();
    NotificationService.onNotificationTap = _handleNotificationTap;
    debugPrint('NotificationService initialized successfully');
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }

  try {
    // Ensure SharedPreferences is ready before starting the app
    await SharedPreferences.getInstance();
    runApp(const UpHealApp());
  } catch (e, stackTrace) {
    debugPrint('Error running app: $e');
    debugPrint('Stack trace: $stackTrace');
    // Try to show a minimal error screen
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

/// Handle notification taps and navigate to appropriate screen
void _handleNotificationTap(NotificationPayload payload) {
  debugPrint(
    'Notification tapped: ${payload.type}, appName: ${payload.appName}',
  );

  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint('No context available for navigation');
    return;
  }

  // Use NavigationModel to switch to the appropriate screen
  final navModel = context.read<NavigationModel>();

  switch (payload.type) {
    case NotificationType.warning:
    case NotificationType.limit:
    case NotificationType.summary:

      // Navigate to analytics screen (index 5 in RootNav _screens)
      navModel.setIndex(5);
      break;
    case NotificationType.achievement:
      // Navigate to profile screen (index 13 in RootNav _screens)
      navModel.setIndex(13);

      break;
    case NotificationType.info:
      // No navigation needed
      break;
  }
}

/// Wrapper to set SystemUIOverlayStyle based on current theme
class _SystemUIWrapper extends StatefulWidget {
  final Widget child;
  const _SystemUIWrapper({required this.child});

  @override
  State<_SystemUIWrapper> createState() => _SystemUIWrapperState();
}

class _SystemUIWrapperState extends State<_SystemUIWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? const Color(0xFF111318) : const Color(0xFFF4F7F5),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class UpHealApp extends StatelessWidget {
  const UpHealApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.interTextTheme();
    } catch (e) {
      textTheme = ThemeData.light().textTheme;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ErrorHandlerModel()),
        ChangeNotifierProvider(create: (_) => AuthModel()),

        // ✅ إضافة Threat Monitor لجميع أجزاء التطبيق
        Provider(create: (_) => ThreatMonitorService()),

        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => RewardOrchestrator()),
        ChangeNotifierProvider(
          create: (_) {
            final service = ChallengeService();
            // Initialize challenge state asynchronously
            service.init().catchError((e) {
              debugPrint('ChallengeService init error: $e');
            });
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final auth = context.read<AuthModel>();
            final initialUsername = auth.userName ?? 'UpHeal User';

            return UserModel(
              username: initialUsername,
              xp: 120,
              level: 3,
              streakDays: 0,
              badges: 5,
              rank: 42,
            );
          },
        ),
        ChangeNotifierProxyProvider5<StreakState, ChallengeService,
            MissionsModel, UserModel, RewardOrchestrator, BadgeProvider>(
          create: (context) {
            final orchestrator = context.read<RewardOrchestrator>();
            final provider = BadgeProvider(orchestrator: orchestrator);
            provider.init().catchError((e) {
              debugPrint('BadgeProvider init error: $e');
            });
            return provider;
          },
          update: (
            context,
            streakState,
            challengeService,
            missionsModel,
            userModel,
            orchestrator,
            badgeProvider,
          ) {
            final provider =
                badgeProvider ?? BadgeProvider(orchestrator: orchestrator);
            final tasksCompleted = missionsModel.completedCount +
                challengeService.completedTotalCount;
            provider.updateFrom(
              streakDays: userModel.streakDays,
              tasksCompleted: tasksCompleted,
              addictionFreeDays: userModel.streakDays,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => MissionsModel()),
        ChangeNotifierProvider(create: (_) => ParentalControlModel()),
        ChangeNotifierProvider(create: (_) => SleepModel()),
        ChangeNotifierProvider(
          create: (_) {
            final stepState = StepTrackerState();
            // Initialize step tracker asynchronously
            stepState.initialize().catchError((e) {
              debugPrint('StepTrackerState initialization error: $e');
            });
            return stepState;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeModel()), // Theme management
        ChangeNotifierProvider(
          create: (_) => NavigationModel(),
        ), // Top-level navigation index
        // Streak State with service initialization
        ChangeNotifierProvider(
          create: (_) {
            final streakState = StreakState();
            // Initialize streak service asynchronously
            StreakService.initialize(streakState).catchError((e) {
              debugPrint('StreakService initialization error: $e');
            });
            return streakState;
          },
        ),
        // Focus Session State with service initialization
        ChangeNotifierProvider(
          create: (_) {
            final focusSessionState = FocusSessionState();
            // Initialize focus session service asynchronously
            FocusSessionService.initialize(focusSessionState).catchError((e) {
              debugPrint('FocusSessionService initialization error: $e');
            });
            return focusSessionState;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final screenTimeModel = ScreenTimeModel();
            // Initialize service asynchronously to not block app startup
            ScreenTimeService.initialize(screenTimeModel).catchError((e) {
              debugPrint('ScreenTimeService initialization error: $e');
            });
            return screenTimeModel;
          },
        ),
        // Journal Model with services
        ChangeNotifierProvider(
          create: (_) {
            final localService = JournalLocalService();
            final apiService = JournalApiService();
            final journalService = JournalService(
              localService: localService,
              apiService: apiService,
            );
            // Initialize local service asynchronously
            localService.init().catchError((e) {
              debugPrint('JournalLocalService initialization error: $e');
            });
            return JournalModel(journalService);
          },
        ),
        // Mood Model with services
        ChangeNotifierProvider(
          create: (_) {
            final localService = MoodLocalService();
            final apiService = MoodApiService();
            final moodService = MoodService(
              localService: localService,
              apiService: apiService,
            );
            // Initialize local service asynchronously
            localService.init().catchError((e) {
              debugPrint('MoodLocalService initialization error: $e');
            });
            return MoodModel(moodService);
          },
        ),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            title: 'UpHeal',
            navigatorKey: navigatorKey,
            theme: buildTheme(Brightness.light).copyWith(textTheme: textTheme),
            darkTheme: buildTheme(
              Brightness.dark,
            ).copyWith(textTheme: textTheme),
            themeMode:
                themeModel.themeMode, // Dynamic theme based on user choice
            home: const _SystemUIWrapper(child: AuthWrapper()),
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            builder: (context, child) => RewardListener(
              navigatorKey: navigatorKey,
              child: ErrorListener(child: child ?? const SizedBox.shrink()),
            ),
            routes: {
              '/analytics': (context) => const AnalyticsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/notification-settings': (context) =>
                  const NotificationSettingsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/block-apps': (context) => const BlockAppsScreen(),
              '/achievements': (context) {
                final user = context.watch<UserModel>();
                final missions = context.watch<MissionsModel>();
                final challenges = context.watch<ChallengeService>();
                final tasksCompleted =
                    missions.completedCount + challenges.completedTotalCount;

                int progressFor(Achievement a) {
                  switch (a.type) {
                    case AchievementType.focusStreak:
                      return user.streakDays;
                    case AchievementType.totalSessions:
                      return user.totalSessions;
                    case AchievementType.totalTime:
                      return user.totalFocusMinutes;
                    case AchievementType.level:
                      return user.level;
                    case AchievementType.special:
                      return tasksCompleted;
                  }
                }

                final computed = Achievement.getDefaultAchievements().map((a) {
                  final p = progressFor(a);
                  final unlocked = p >= a.requirement;
                  return a.copyWith(
                    currentProgress: p,
                    isUnlocked: unlocked,
                    unlockedAt:
                        unlocked ? (a.unlockedAt ?? DateTime.now()) : null,
                  );
                }).toList(growable: false);

                return AchievementsScreen(achievements: computed);
              },
              '/avatar': (context) => const AvatarScreen(),
              '/badges': (context) => const BadgesScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // ✅ تعريف خدمة المراقبة
  final ThreatMonitorService _threatMonitor = ThreatMonitorService();

  @override
  void initState() {
    super.initState();

    // ✅ بدء مراقبة التهديدات والحماية
    _threatMonitor.startMonitoring();

    // Auto-push the GAD‑7/PHQ‑9 assessment screen on first launch
    // Users can access the assessment from the navigation drawer anytime
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check if current user has completed assessment (per-user tracking)
      final authModel = Provider.of<AuthModel>(context, listen: false);
      if (!authModel.isAuthenticated) return;

      final userId = authModel.userId;
      if (userId == null) return;

      // Check per-user completion status in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'has_completed_assessment_$userId';
      bool hasCompleted = prefs.getBool(userKey) ?? false;

      // Show assessment screen if user hasn't completed it
      if (!hasCompleted && mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GadPhqFormScreen()));
      }
    });
  }

  @override
  void dispose() {
    // ✅ إيقاف المراقبة عند تدمير الواجهة
    _threatMonitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (context, authModel, child) {
        // Sync UserModel username when authenticated (do this once, not in postFrameCallback)
        if (authModel.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final userModel = Provider.of<UserModel>(context, listen: false);
              final usernameToUse = authModel.userName;

              if (usernameToUse != null &&
                  usernameToUse.isNotEmpty &&
                  userModel.username != usernameToUse) {
                userModel.updateUsername(usernameToUse);
              }
            } catch (e) {
              debugPrint('Error syncing username: $e');
            }
          });
        }
        try {
          if (authModel.isAuthenticated) {
            return const RootNav();
          } else {
            return const LoginScreen();
          }
        } catch (e, stackTrace) {
          debugPrint('Error in AuthWrapper build: $e');
          debugPrint('Stack trace: $stackTrace');
          // Return a safe fallback widget
          return Scaffold(body: Center(child: Text('Error: $e')));
        }
      },
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class _RootNavState extends State<RootNav> {
  // Index now managed by NavigationModel provider
  static const platform = MethodChannel('com.appguard.native_calls');
  /// Primary tabs shown on the bottom bar (subset of `_screens` indices).
  static const List<int> _bottomNavScreenIndices = [0, 1, 2, 4, 13];
  bool _isBlockedScreenVisible = false;

  final _screens = [
    const HomeScreen(),
    const YourInsightsScreen(),
    const ChallengesScreen(),
    const MiniGamesScreen(),
    const CommunityScreen(),
    const AnalyticsScreen(),
    const SleepTrackerScreen(),
    const StepTrackerScreen(),
    const MyAssessmentScreen(),
    const JournalScreen(),
    const MoodTrackerScreen(),
    const ParentalControlScreen(),
    const BlockAppsScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: LucideIcons.home, label: 'Home', index: 0),
    _NavItem(icon: LucideIcons.lightbulb, label: 'Insight', index: 1),
    _NavItem(icon: LucideIcons.target, label: 'Challenges', index: 2),
    _NavItem(icon: LucideIcons.gamepad2, label: 'Mini Games', index: 3),
    _NavItem(icon: LucideIcons.users, label: 'Community', index: 4),
    _NavItem(icon: LucideIcons.barChart3, label: 'Analytics', index: 5),
    _NavItem(icon: LucideIcons.moon, label: 'Sleep Tracker', index: 6),
    _NavItem(icon: LucideIcons.footprints, label: 'Step Tracker', index: 7),
    _NavItem(icon: LucideIcons.brain, label: 'My Results', index: 8),
    _NavItem(icon: LucideIcons.bookOpen, label: 'Journaling', index: 9),
    _NavItem(icon: LucideIcons.smile, label: 'Mood Tracker', index: 10),
    _NavItem(icon: LucideIcons.shield, label: 'Parental', index: 11),
    _NavItem(icon: LucideIcons.ban, label: 'Block Apps', index: 12),
    _NavItem(icon: LucideIcons.user, label: 'Profile', index: 13),
    _NavItem(
        icon: LucideIcons.settings,
        label: 'Settings',
        index: -1), // -1 means open settings screen directly
  ];

  void _navigateTo(BuildContext context, int index) {
    if (index == -1) {
      // Settings - open directly via route
      Navigator.of(context).pop(); // Close drawer first
      Navigator.of(context).pushNamed('/settings');
      return;
    }
    context.read<NavigationModel>().setIndex(index);
    Navigator.of(context).pop(); // Close drawer
  }

  int _bottomNavSelectedIndex(int screenIndex) {
    final i = _bottomNavScreenIndices.indexOf(screenIndex);
    return i >= 0 ? i : 0;
  }

  @override
  void initState() {
    super.initState();
    // ✅ تشغيل الخدمة الموحدة للدرع عند فتح التطبيق بدلاً من startGuardService
    startUnifiedSecurityShield();
    platform.setMethodCallHandler(_handleNativeCall);
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    // #region agent log
    debugPrint('DEBUG_H4: Flutter _handleNativeCall method=${call.method}');
    // #endregion

    // ✅ [إضافة] استقبال تحذير الذكاء الاصطناعي (Edge AI) من الأندرويد
    if (call.method == 'onThreatDetected') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final confidence = args['confidence'] as double? ?? 0.0;
      debugPrint(
        '⚠️ [EdgeAI] Cyberbullying/Threat detected! Confidence: $confidence',
      );

      // إظهار تنبيه داخل التطبيق يوضح وجود خطر (يمكن ربط هذا الحدث بقاعدة البيانات لتبليغ الآباء)
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Security Alert: Harmful text detected! (Confidence: ${(confidence * 100).toStringAsFixed(1)}%)',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Native Android GuardService notifies us when a blocked app is opened.
    if (call.method != 'onBlockEvent') return;
    // #region agent log
    debugPrint(
      'DEBUG_H4: Flutter onBlockEvent received, lifecycle=${WidgetsBinding.instance.lifecycleState}',
    );
    // #endregion
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (!mounted || context == null) return;
    if (_isBlockedScreenVisible) return;

    final args = Map<String, dynamic>.from(call.arguments as Map);
    final packageName = args['packageName'] as String? ?? '';
    // #region agent log
    debugPrint('DEBUG_H5: Flutter evaluating block for package=$packageName');
    // #endregion

    // Evaluate blocking using the service
    final evaluation = EvaluateBlockingUseCase().execute(packageName);
    // #region agent log
    debugPrint('DEBUG_H5: Flutter evaluation result: ${evaluation.toString()}');
    // #endregion
    if (evaluation['isBlocked'] != true) {
      debugPrint('[main] App $packageName not blocked by rules, skipping');
      return;
    }

    // Determine reason and remaining time
    final reasonStr = evaluation['reason'] as String?;
    final remainingMinutes = evaluation['remainingMinutes'] as int? ?? 0;
    final canEmergency = evaluation['canEmergencyAllow'] as bool? ?? false;
    final hasUsedEmergency =
        evaluation['hasUsedEmergencyToday'] as bool? ?? false;

    // Map reason string to enum
    BlockReasonType resolvedReason;
    if (reasonStr == 'daily_limit_reached') {
      resolvedReason = BlockReasonType.dailyLimitReached;
    } else if (reasonStr == 'blocked_by_user') {
      resolvedReason = BlockReasonType.blockedByUser;
    } else {
      // Check if focus session is active
      final focusState = context.read<FocusSessionState>();
      if (focusState.isActive) {
        resolvedReason = BlockReasonType.focusSessionActive;
      } else {
        resolvedReason = BlockReasonType.blockedByUser;
      }
    }

    // Get app name from rule or fallback
    final rule = AppBlockingService.getRule(packageName);
    final appName = rule?.appName ?? packageName.split('.').last;

    final viewModel = BlockedAppViewModel(
      packageName: packageName,
      appName: appName,
      reason: resolvedReason,
      remaining: Duration(minutes: remainingMinutes),
      canEmergencyAllow: canEmergency,
      hasUsedEmergencyToday: hasUsedEmergency,
      showTakeBreath: true,
      showReturnHome: true,
      onEmergencyAllow: () async {
        // Grant emergency allow via use case
        final allowResult = await EmergencyAllowUseCase().execute(packageName);
        if (allowResult['success'] != true) {
          final error = allowResult['error'] as String? ?? 'Failed';
          throw Exception(error);
        }
      },
    );

    _isBlockedScreenVisible = true;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
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
            context.read<NavigationModel>().setIndex(0);
            Navigator.of(context).pop();
          },
        ),
        fullscreenDialog: true,
      ),
    )
        .then((_) {
      _isBlockedScreenVisible = false;
    });
  }

  /// ✅ دالة تشغيل الدرع الأمني الموحد (Guard + VPN)
  Future<void> startUnifiedSecurityShield() async {
    try {
      // 1. تشغيل خدمة الحرس الأصلية (الخاصة بحظر التطبيقات)
      await platform.invokeMethod('startGuardService');
      debugPrint("Native GuardService started successfully");

      // 2. الحصول على قائمة التطبيقات المحظورة لتفعيل حماية الويب
      final blockedApps = AppBlockingService.getBlockedPackages();
      List<String> domainsToBlock = [];

      for (var pkg in blockedApps) {
        if (pkg.contains('facebook')) {
          domainsToBlock.addAll([
            'facebook.com',
            'www.facebook.com',
            'm.facebook.com',
          ]);
        }
        if (pkg.contains('instagram')) {
          domainsToBlock.addAll(['instagram.com', 'www.instagram.com']);
        }
        if (pkg.contains('tiktok')) {
          domainsToBlock.addAll([
            'tiktok.com',
            'www.tiktok.com',
            'm.tiktok.com',
          ]);
        }
        if (pkg.contains('youtube')) {
          domainsToBlock.addAll([
            'youtube.com',
            'www.youtube.com',
            'm.youtube.com',
            'youtu.be',
          ]);
        }
      }

      // 3. تشغيل VPN الـ DNS في الخلفية إذا وجدت تطبيقات محظورة
      if (domainsToBlock.isNotEmpty) {
        await VpnController.startVpn(domainsToBlock);
        debugPrint("DNS Sinkhole active for: $domainsToBlock");
      }
    } on PlatformException catch (e) {
      debugPrint("Unified Shield initialization failed: ${e.message}");
    } catch (e) {
      debugPrint("Shield error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.purple
        : AppColors.teal;

    final currentIndex = context.watch<NavigationModel>().index;
    return Scaffold(
      key: rootScaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B1B)
            : Colors.white,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Fixed header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              AppColors.purple.withOpacity(0.3),
                              AppColors.purple.withOpacity(0.1),
                            ]
                          : [
                              AppColors.teal.withOpacity(0.2),
                              AppColors.teal.withOpacity(0.05),
                            ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? [AppColors.purple, const Color(0xFFF97316)]
                                : [AppColors.teal, AppColors.orange],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UpHeal',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Navigation Menu',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable theme switcher
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : AppColors.textPrimary.withOpacity(0.1),
                    ),
                    const ThemeSwitcher(),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : AppColors.textPrimary.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              // Scrollable navigation items
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = _navItems[i];
                    final isSelected = currentIndex == item.index;
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? selectedColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppColors.textPrimary),
                        size: 24,
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? selectedColor
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppColors.textPrimary),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: selectedColor.withOpacity(0.1),
                      onTap: () => _navigateTo(context, item.index),
                    );
                  }, childCount: _navItems.length),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _bottomNavSelectedIndex(currentIndex),
        onTap: (i) {
          context.read<NavigationModel>().setIndex(_bottomNavScreenIndices[i]);
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B1B)
            : Theme.of(context).colorScheme.surface,
        selectedItemColor: selectedColor,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : AppColors.textPrimary.withOpacity(0.55),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.lightbulb),
            label: 'Insight',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.target),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class ErrorListener extends StatefulWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  State<ErrorListener> createState() => _ErrorListenerState();
}

class _ErrorListenerState extends State<ErrorListener> {
  ErrorMessage? _lastMessage;

  @override
  Widget build(BuildContext context) {
    final handler = Provider.of<ErrorHandlerModel>(context);
    final active = handler.activeMessage;

    if (active != null && active != _lastMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final snackBar = ErrorSnackBar.build(
          type: active.type,
          message: active.message,
        );
        rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
        Future.delayed(active.duration, handler.consumeActive);
      });
      _lastMessage = active;
    }

    return widget.child;
  }
}
