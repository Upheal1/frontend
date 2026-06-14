import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:upheal/screens/settings_screen.dart';
import 'package:upheal/screens/signup_screen.dart';

import '../screens/avatar_showcase_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/community/data/community_models.dart';
import '../features/community/services/community_repository.dart';
import '../features/community/state/community_notifiers.dart';
import '../features/community/ui/community_hub_screen.dart';
import '../features/community/ui/group_chat_screen.dart';
import '../models/achievement.dart';
import '../models/auth_model.dart';
import '../models/mission_model.dart';
import '../models/user_model.dart';
import '../screens/achievements_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/badges_screen.dart';
import '../screens/block_apps_screen.dart';
import '../screens/challenges_screen.dart';
import '../screens/focus_session_screen.dart';
import '../screens/gad_phq_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/mini_games_screen.dart';
import '../screens/my_assessment_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/roadmap2_screen.dart';
import '../screens/sleep_tracker_screen.dart';
import '../screens/streak_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/mood_tracker_screen.dart';
import '../features/steps/ui/screens/step_tracker_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/challenge_service.dart';
import 'app_navigation_keys.dart';
import 'app_route_placeholder_screen.dart';
import 'app_route_transitions.dart';
import 'app_routes.dart';
import 'app_shell_scaffold.dart';
import '../shared/navigation/placeholder_detail_screen.dart';
import '../screens/avatar_test_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';

class AppRouter {
  AppRouter();

  final _RouterRefreshNotifier _refreshNotifier = _RouterRefreshNotifier();
  AuthModel? _authModel;

  late final GoRouter router = GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/',
    refreshListenable: _refreshNotifier,
    redirect: _redirect,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (BuildContext context, GoRouterState state) {
          final bool isAuthenticated = _authModel?.isAuthenticated ?? false;
          return isAuthenticated ? HomeRoute.path : WelcomeRoute.path;
        },
      ),
      GoRoute(
        path: WelcomeRoute.path,
        name: WelcomeRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding-flow',
        name: 'onboarding-flow',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: LoginRoute.path,
        name: LoginRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: SignUpRoute.path,
        name: SignUpRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: ForgotPasswordRoute.path,
        name: ForgotPasswordRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AvatarTestRoute.path,
        name: AvatarTestRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: const AvatarTestScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/:step',
        name: OnboardingStepRoute.name,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppRouteTransitions.buildPage<void>(
          state: state,
          child: AppRoutePlaceholderScreen(
            title: 'Onboarding',
            message:
                'Onboarding step "${state.pathParameters['step']}" is wired for future deep-link flows.',
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Branch 0: Home
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeRoute.path,
                name: HomeRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
              GoRoute(
                path: AnalyticsRoute.path,
                name: AnalyticsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const AnalyticsScreen(),
                ),
              ),
              GoRoute(
                path: MiniGamesRoute.path,
                name: MiniGamesRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const MiniGamesScreen(),
                ),
              ),
              GoRoute(
                path: SleepTrackerRoute.path,
                name: SleepTrackerRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const SleepTrackerScreen(),
                ),
              ),
              GoRoute(
                path: StepTrackerRoute.path,
                name: StepTrackerRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const StepTrackerScreen(),
                ),
              ),
              GoRoute(
                path: MyAssessmentRoute.path,
                name: MyAssessmentRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const MyAssessmentScreen(),
                ),
              ),
              GoRoute(
                path: GadPhqRoute.path,
                name: GadPhqRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const GadPhqFormScreen(),
                ),
              ),
              GoRoute(
                path: JournalRoute.path,
                name: JournalRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const JournalScreen(),
                ),
              ),
              GoRoute(
                path: BlockAppsRoute.path,
                name: BlockAppsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const BlockAppsScreen(),
                ),
              ),
              GoRoute(
                path: SettingsRoute.path,
                name: SettingsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
              GoRoute(
                path: NotificationSettingsRoute.path,
                name: NotificationSettingsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const NotificationSettingsScreen(),
                ),
              ),
              GoRoute(
                path: MoodTrackingRoute.path,
                name: MoodTrackingRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const MoodTrackerScreen(),
                ),
              ),
              GoRoute(
                path: InsightsRoute.path,
                name: InsightsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const InsightsScreen(),
                ),
              ),
              GoRoute(
                path: CoursesRoute.path,
                name: CoursesRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const PlaceholderDetailScreen(
                    title: 'Courses',
                    description:
                        'Course learning paths can be connected here without affecting the primary tab shell.',
                  ),
                ),
              ),
              GoRoute(
                path: SubscriptionRoute.path,
                name: SubscriptionRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const PlaceholderDetailScreen(
                    title: 'Subscription',
                    description:
                        'Subscription management is ready to be connected to billing and entitlement flows.',
                  ),
                ),
              ),
              GoRoute(
                path: HelpSupportRoute.path,
                name: HelpSupportRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const PlaceholderDetailScreen(
                    title: 'Help & Support',
                    description:
                        'Support resources, FAQs, and contact actions can be attached here without changing the shell.',
                  ),
                ),
              ),
              GoRoute(
                path: AboutRoute.path,
                name: AboutRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const PlaceholderDetailScreen(
                    title: 'About',
                    description:
                        'App information, versioning, and legal content can be surfaced here.',
                  ),
                ),
              ),
              GoRoute(
                path: FocusSessionRoute.path,
                name: FocusSessionRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const FocusSessionScreen(),
                ),
              ),
              GoRoute(
                path: Roadmap2Route.path,
                name: Roadmap2Route.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const Roadmap2Screen(),
                ),
              ),
              GoRoute(
                path: ChallengesRoute.path,
                name: ChallengesRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const ChallengesScreen(),
                ),
              ),
            ],
          ),
          // Branch 1: Community
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: CommunityRoute.path,
                name: CommunityRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const CommunityHubScreen(),
                ),
              ),
              GoRoute(
                path: '/app/community/pages/:pageId',
                name: CommunityPageRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: AppRoutePlaceholderScreen(
                    title: 'Community Page',
                    message:
                        'Community page ${state.pathParameters['pageId']} is ready for future deep links.',
                  ),
                ),
              ),
              GoRoute(
                path: '/app/community/groups/:groupId/chat',
                name: GroupChatRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) {
                  final CommunityGroup? group = state.extra is CommunityGroup
                      ? state.extra! as CommunityGroup
                      : null;

                  final Widget child;
                  if (group == null) {
                    child = AppRoutePlaceholderScreen(
                      title: 'Group Chat',
                      message:
                          'Deep link ${state.pathParameters['groupId']} is wired, but this build still needs group hydration before entering chat.',
                    );
                  } else {
                    final CommunityRepository repo =
                        context.read<CommunityRepository>();
                    final UserModel user = context.read<UserModel>();
                    child = MultiProvider(
                      providers: <SingleChildWidget>[
                        Provider<CommunityRepository>.value(value: repo),
                        ChangeNotifierProvider<UserModel>.value(value: user),
                        ChangeNotifierProvider<GroupChatNotifier>(
                          create: (_) =>
                              GroupChatNotifier(repo, group.id, user.username),
                        ),
                      ],
                      child: GroupChatScreen(group: group),
                    );
                  }

                  return AppRouteTransitions.buildPage<void>(
                    state: state,
                    child: child,
                  );
                },
              ),
            ],
          ),
          // Branch 2: AiChat / Chatbot
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AiChatRoute.path,
                name: AiChatRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const AiChatScreen(),
                ),
              ),
            ],
          ),
          // Branch 3: Roadmap
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoadmapRoute.path,
                name: RoadmapRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const RoadmapScreen(),
                ),
              ),
              GoRoute(
                path: '/app/roadmap/world/:worldId',
                name: RoadmapWorldRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: AppRoutePlaceholderScreen(
                    title: 'Roadmap World',
                    message:
                        'World ${state.pathParameters['worldId']} is reserved for future roadmap deep links.',
                  ),
                ),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: ProfileRoute.path,
                name: ProfileRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
              GoRoute(
                path: AvatarRoute.path,
                name: AvatarRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const AvatarShowcaseScreen(),
                ),
              ),
              GoRoute(
                path: BadgesRoute.path,
                name: BadgesRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const BadgesScreen(),
                ),
              ),
              GoRoute(
                path: StreakRoute.path,
                name: StreakRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const StreakScreen(),
                ),
              ),
              GoRoute(
                path: AchievementsRoute.path,
                name: AchievementsRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) {
                  final UserModel user = context.watch<UserModel>();
                  final MissionsModel missions = context.watch<MissionsModel>();
                  final ChallengeService challenges =
                      context.watch<ChallengeService>();
                  final int tasksCompleted =
                      missions.completedCount + challenges.completedTotalCount;

                  int progressFor(Achievement achievement) {
                    switch (achievement.type) {
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

                  final List<Achievement> computed = Achievement
                      .getDefaultAchievements()
                      .map((Achievement achievement) {
                    final int progress = progressFor(achievement);
                    final bool unlocked = progress >= achievement.requirement;
                    return achievement.copyWith(
                      currentProgress: progress,
                      isUnlocked: unlocked,
                      unlockedAt: unlocked
                          ? (achievement.unlockedAt ?? DateTime.now())
                          : null,
                    );
                  }).toList(growable: false);

                  return AppRouteTransitions.buildPage<void>(
                    state: state,
                    child: AchievementsScreen(achievements: computed),
                  );
                },
              ),
              GoRoute(
                path: '/app/profile/u/:profileId',
                name: ProfileDeepLinkRoute.name,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    AppRouteTransitions.buildPage<void>(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  AppRouter updateAuth(AuthModel authModel) {
    _authModel = authModel;
    _refreshNotifier.markNeedsRefresh();
    return this;
  }

  void dispose() {
    _refreshNotifier.dispose();
    router.dispose();
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final bool isAuthenticated = _authModel?.isAuthenticated ?? false;
    final String location = state.uri.path;
    final bool isPublic = publicRoutePrefixes.any(
      (String prefix) => location == prefix || location.startsWith('$prefix/'),
    );

    if (!isAuthenticated && !isPublic) {
      return const WelcomeRoute().location;
    }

    if (isAuthenticated &&
        (location == '/' ||
            location == WelcomeRoute.path ||
            location == LoginRoute.path ||
            location == SignUpRoute.path)) {
      return const HomeRoute().location;
    }

    return null;
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void markNeedsRefresh() {
    notifyListeners();
  }
}
