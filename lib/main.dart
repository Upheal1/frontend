import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/community_supabase_env.dart';
import 'constants/app_colors.dart';
import 'theme/upheal_theme_data.dart';
import 'design_system/responsive/responsive.dart';
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
import 'features/community/services/community_repository.dart';
import 'features/community/services/community_supabase.dart';
import 'models/journal_model.dart';
import 'models/mood_model.dart';
import 'services/journal_service.dart';
import 'navigation/app_navigation_keys.dart';
import 'navigation/app_router.dart';
import 'navigation/app_routes.dart';
import 'services/mood_api_service.dart';
import 'services/mood_local_service.dart';
import 'services/mood_service.dart';
import 'services/screen_time_notification_service.dart';
import 'services/screen_time_service.dart';
import 'services/notification_service.dart';
import 'services/usage_cache_service.dart';
import 'models/hive/app_usage_cache.dart';
import 'models/hive/focus_session_history.dart';
import 'models/hive/block_rule.dart';
import 'models/focus_session_model.dart';
import 'services/app_blocking_service.dart';
import 'services/focus_session_service.dart';
import 'models/notification_types.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'widgets/common/error_snackbar.dart';
import 'services/reward_orchestrator.dart';
import 'services/challenge_service.dart';
import 'services/badge_provider.dart';
import 'widgets/rewards/reward_listener.dart';
import 'avatar/services/avatar_provider.dart';
import 'avatar/services/avatar_progression_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge so the system navigation bar is transparent
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

  // Initialize screen time notifications
  try {
    await ScreenTimeNotificationService.initialize();
    debugPrint('Screen time notifications initialized successfully');
  } catch (e) {
    debugPrint('Screen time notifications initialization error: $e');
  }

  // Initialize notification service for app usage limits
  try {
    await NotificationService.initialize();
    // Set up notification tap handler
    NotificationService.onNotificationTap = _handleNotificationTap;
    debugPrint('NotificationService initialized successfully');
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }

  await CommunitySupabaseEnv.tryLoadLocalKeysFile();
  await CommunitySupabase.initializeIfConfigured();

  try {
    // Ensure SharedPreferences is ready before starting the app
    await SharedPreferences.getInstance();
    runApp(const ProviderScope(child: UpHealApp()));
  } catch (e, stackTrace) {
    debugPrint('Error running app: $e');
    debugPrint('Stack trace: $stackTrace');
    // Try to show a minimal error screen
    runApp(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('App failed to start'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Handle notification taps and navigate to appropriate screen
void _handleNotificationTap(NotificationPayload payload) {
  debugPrint(
      'Notification tapped: ${payload.type}, appName: ${payload.appName}');

  final context = appNavigatorKey.currentContext;
  if (context == null) {
    debugPrint('No context available for navigation');
    return;
  }

  switch (payload.type) {
    case NotificationType.warning:
    case NotificationType.limit:
    case NotificationType.summary:
      const AnalyticsRoute().go(context);
      break;
    case NotificationType.achievement:
      const ProfileRoute().go(context);
      break;
    case NotificationType.info:
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
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
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
        Provider(create: (_) => CommunityRepository()),

        ChangeNotifierProvider(create: (_) => AuthModel()),
        ProxyProvider<AuthModel, AppRouter>(
          create: (_) => AppRouter(),
          update: (_, authModel, appRouter) =>
              (appRouter ?? AppRouter()).updateAuth(authModel),
          dispose: (_, appRouter) => appRouter.dispose(),
        ),

        // ✅ إضافة Threat Monitor لجميع أجزاء التطبيق
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => RewardOrchestrator()),
        ChangeNotifierProvider(create: (_) {
          final service = ChallengeService();
          // Initialize challenge state asynchronously
          service.init().catchError((e) {
            debugPrint('ChallengeService init error: $e');
          });
          return service;
        }),
        ChangeNotifierProvider(
          create: (context) {
            // Try to get username from Supabase Auth if user is already logged in
            final supabaseUser = CommunitySupabase.clientOrNull?.auth.currentUser;
            final initialUsername = supabaseUser?.userMetadata?['display_name'] as String? ??
                supabaseUser?.userMetadata?['name'] as String? ?? 'UpHeal User';

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
        ChangeNotifierProvider(create: (_) => MissionsModel()),
        // Streak State with service initialization
        ChangeNotifierProvider(create: (_) {
          final streakState = StreakState();
          // Initialize streak service asynchronously
          StreakService.initialize(streakState).catchError((e) {
            debugPrint('StreakService initialization error: $e');
          });
          return streakState;
        }),
        ChangeNotifierProxyProvider<UserModel, AvatarProgressionProvider>(
          create: (_) => AvatarProgressionProvider()..load(),
          update: (_, user, prev) {
            prev!.syncWithLevel(user.level);
            return prev;
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
          update: (context, streakState, challengeService, missionsModel,
              userModel, orchestrator, badgeProvider) {
            final provider =
                badgeProvider ?? BadgeProvider(orchestrator: orchestrator);
            final tasksCompleted = missionsModel.completedCount +
                challengeService.completedTotalCount;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.updateFrom(
                streakDays: userModel.streakDays,
                tasksCompleted: tasksCompleted,
                addictionFreeDays: userModel.streakDays,
              );
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ParentalControlModel()),
        ChangeNotifierProvider(create: (_) => SleepModel()),
        ChangeNotifierProvider(create: (_) {
          final stepState = StepTrackerState();
          // Initialize step tracker asynchronously
          stepState.initialize().catchError((e) {
            debugPrint('StepTrackerState initialization error: $e');
          });
          return stepState;
        }),
        ChangeNotifierProvider(create: (_) => ThemeModel()), // Theme management
        // Focus Session State with service initialization
        ChangeNotifierProvider(create: (_) {
          final focusSessionState = FocusSessionState();
          // Initialize focus session service asynchronously
          FocusSessionService.initialize(focusSessionState).catchError((e) {
            debugPrint('FocusSessionService initialization error: $e');
          });
          return focusSessionState;
        }),
        ChangeNotifierProvider(create: (_) {
          final screenTimeModel = ScreenTimeModel();
          // Initialize service asynchronously to not block app startup
          ScreenTimeService.initialize(screenTimeModel).catchError((e) {
            debugPrint('ScreenTimeService initialization error: $e');
          });
          return screenTimeModel;
        }),
        // Journal Model — writes/reads directly to Supabase
        ChangeNotifierProvider(create: (_) {
          return JournalModel(JournalService());
        }),
        // Mood Model with services
        ChangeNotifierProvider(create: (_) {
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
        }),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          final appRouter = context.read<AppRouter>();
          return MaterialApp.router(
            title: 'UpHeal',
            theme: UpHealTheme.light(),
            darkTheme: UpHealTheme.dark(),
            themeMode: themeModel.themeMode,
            routerConfig: appRouter.router,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            builder: (context, child) => AppResponsiveRoot(
              child: _SystemUIWrapper(
                child: RewardListener(
                  navigatorKey: appNavigatorKey,
                  child: ErrorListener(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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