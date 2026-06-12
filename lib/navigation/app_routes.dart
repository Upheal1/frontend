import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

abstract class AppRouteData {
  const AppRouteData();

  String get location;

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context, {Object? extra}) =>
      context.push<T>(location, extra: extra);

  void replace(BuildContext context) => context.replace(location);
}

class AppBranchDestination {
  const AppBranchDestination({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final AppRouteData route;
}

class AppDrawerDestination {
  const AppDrawerDestination({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final AppRouteData route;
}

class AppDrawerSection {
  const AppDrawerSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AppDrawerDestination> items;
}

class WelcomeRoute extends AppRouteData {
  const WelcomeRoute();

  static const String name = 'welcome';
  static const String path = '/welcome';

  @override
  String get location => path;
}

class LoginRoute extends AppRouteData {
  const LoginRoute();

  static const String name = 'login';
  static const String path = '/auth/login';

  @override
  String get location => path;
}

class SignUpRoute extends AppRouteData {
  const SignUpRoute();

  static const String name = 'signUp';
  static const String path = '/auth/signup';

  @override
  String get location => path;
}

class ForgotPasswordRoute extends AppRouteData {
  const ForgotPasswordRoute();

  static const String name = 'forgotPassword';
  static const String path = '/auth/forgot-password';

  @override
  String get location => path;
}

class OnboardingStepRoute extends AppRouteData {
  const OnboardingStepRoute(this.step);

  static const String name = 'onboarding';
  final String step;

  @override
  String get location => '/onboarding/${Uri.encodeComponent(step)}';
}

class HomeRoute extends AppRouteData {
  const HomeRoute();

  static const String name = 'home';
  static const String path = '/app/home';

  @override
  String get location => path;
}

class ChallengesRoute extends AppRouteData {
  const ChallengesRoute();

  static const String name = 'challenges';
  static const String path = '/app/challenges';

  @override
  String get location => path;
}

class CommunityRoute extends AppRouteData {
  const CommunityRoute();

  static const String name = 'community';
  static const String path = '/app/community';

  @override
  String get location => path;
}

class GroupChatRoute extends AppRouteData {
  const GroupChatRoute(this.groupId);

  static const String name = 'groupChat';
  final String groupId;

  @override
  String get location =>
      '/app/community/groups/${Uri.encodeComponent(groupId)}/chat';
}

class CommunityPageRoute extends AppRouteData {
  const CommunityPageRoute(this.pageId);

  static const String name = 'communityPage';
  final String pageId;

  @override
  String get location => '/app/community/pages/${Uri.encodeComponent(pageId)}';
}

class ProfileRoute extends AppRouteData {
  const ProfileRoute();

  static const String name = 'profile';
  static const String path = '/app/profile';

  @override
  String get location => path;
}

class ProfileDeepLinkRoute extends AppRouteData {
  const ProfileDeepLinkRoute(this.profileId);

  static const String name = 'profileDeepLink';
  final String profileId;

  @override
  String get location => '/app/profile/u/${Uri.encodeComponent(profileId)}';
}

class AvatarRoute extends AppRouteData {
  const AvatarRoute();

  static const String name = 'avatar';
  static const String path = '/app/profile/avatar';

  @override
  String get location => path;
}

class BadgesRoute extends AppRouteData {
  const BadgesRoute();

  static const String name = 'badges';
  static const String path = '/app/profile/badges';

  @override
  String get location => path;
}

class StreakRoute extends AppRouteData {
  const StreakRoute();

  static const String name = 'streaks';
  static const String path = '/app/streaks';

  @override
  String get location => path;
}

class AchievementsRoute extends AppRouteData {
  const AchievementsRoute();

  static const String name = 'achievements';
  static const String path = '/app/profile/achievements';

  @override
  String get location => path;
}

class AnalyticsRoute extends AppRouteData {
  const AnalyticsRoute();

  static const String name = 'analytics';
  static const String path = '/app/analytics';

  @override
  String get location => path;
}

class MiniGamesRoute extends AppRouteData {
  const MiniGamesRoute();

  static const String name = 'miniGames';
  static const String path = '/app/mini-games';

  @override
  String get location => path;
}

class SleepTrackerRoute extends AppRouteData {
  const SleepTrackerRoute();

  static const String name = 'sleepTracker';
  static const String path = '/app/sleep';

  @override
  String get location => path;
}

class StepTrackerRoute extends AppRouteData {
  const StepTrackerRoute();

  static const String name = 'stepTracker';
  static const String path = '/app/steps';

  @override
  String get location => path;
}

class MyAssessmentRoute extends AppRouteData {
  const MyAssessmentRoute();

  static const String name = 'myAssessment';
  static const String path = '/app/assessment';

  @override
  String get location => path;
}

class GadPhqRoute extends AppRouteData {
  const GadPhqRoute();

  static const String name = 'gadPhq';
  static const String path = '/app/assessment/gad-phq';

  @override
  String get location => path;
}

class RoadmapRoute extends AppRouteData {
  const RoadmapRoute();

  static const String name = 'roadmap';
  static const String path = '/app/roadmap';

  @override
  String get location => path;
}

class Roadmap2Route extends AppRouteData {
  const Roadmap2Route();

  static const String name = 'roadmap2';
  static const String path = '/app/roadmap2';

  @override
  String get location => path;
}

class RoadmapWorldRoute extends AppRouteData {
  const RoadmapWorldRoute(this.worldId);

  static const String name = 'roadmapWorld';
  final String worldId;

  @override
  String get location => '/app/roadmap/world/${Uri.encodeComponent(worldId)}';
}

class JournalRoute extends AppRouteData {
  const JournalRoute();

  static const String name = 'journal';
  static const String path = '/app/journal';

  @override
  String get location => path;
}

class BlockAppsRoute extends AppRouteData {
  const BlockAppsRoute();

  static const String name = 'blockApps';
  static const String path = '/app/block-apps';

  @override
  String get location => path;
}

class NotificationSettingsRoute extends AppRouteData {
  const NotificationSettingsRoute();

  static const String name = 'notificationSettings';
  static const String path = '/app/settings/notifications';

  @override
  String get location => path;
}

class SettingsRoute extends AppRouteData {
  const SettingsRoute();

  static const String name = 'settings';
  static const String path = '/app/settings';

  @override
  String get location => path;
}

class MoodTrackingRoute extends AppRouteData {
  const MoodTrackingRoute();

  static const String name = 'moodTracking';
  static const String path = '/app/mood-tracking';

  @override
  String get location => path;
}

class InsightsRoute extends AppRouteData {
  const InsightsRoute();

  static const String name = 'insights';
  static const String path = '/app/insights';

  @override
  String get location => path;
}

class CoursesRoute extends AppRouteData {
  const CoursesRoute();

  static const String name = 'courses';
  static const String path = '/app/courses';

  @override
  String get location => path;
}

class SubscriptionRoute extends AppRouteData {
  const SubscriptionRoute();

  static const String name = 'subscription';
  static const String path = '/app/subscription';

  @override
  String get location => path;
}

class HelpSupportRoute extends AppRouteData {
  const HelpSupportRoute();

  static const String name = 'helpSupport';
  static const String path = '/app/help-support';

  @override
  String get location => path;
}

class AboutRoute extends AppRouteData {
  const AboutRoute();

  static const String name = 'about';
  static const String path = '/app/about';

  @override
  String get location => path;
}

class FocusSessionRoute extends AppRouteData {
  const FocusSessionRoute();

  static const String name = 'focusSession';
  static const String path = '/app/focus';

  @override
  String get location => path;
}

class AiChatRoute extends AppRouteData {
  const AiChatRoute();

  static const String name = 'aiChat';
  static const String path = '/app/ai-chat';

  @override
  String get location => path;
}

class AvatarTestRoute extends AppRouteData {
  const AvatarTestRoute();

  static const String name = 'avatarTest';
  static const String path = '/test/avatars';

  @override
  String get location => path;
}

const List<AppBranchDestination> appBottomNavDestinations = <AppBranchDestination>[
  AppBranchDestination(
    icon: LucideIcons.home,
    label: 'Home',
    route: HomeRoute(),
  ),
  AppBranchDestination(
    icon: LucideIcons.users,
    label: 'Community',
    route: CommunityRoute(),
  ),
  AppBranchDestination(
    icon: LucideIcons.sparkles,
    label: 'Chatbot',
    route: AiChatRoute(),
  ),
  AppBranchDestination(
    icon: LucideIcons.map,
    label: 'Roadmap',
    route: RoadmapRoute(),
  ),
  AppBranchDestination(
    icon: LucideIcons.user,
    label: 'Profile',
    route: ProfileRoute(),
  ),
];

const List<AppDrawerDestination> appDrawerDestinations = <AppDrawerDestination>[
  AppDrawerDestination(icon: LucideIcons.home, label: 'Home', route: HomeRoute()),
  AppDrawerDestination(icon: LucideIcons.target, label: 'Challenges', route: ChallengesRoute()),
  AppDrawerDestination(icon: LucideIcons.users, label: 'Community', route: CommunityRoute()),
  AppDrawerDestination(icon: LucideIcons.barChart3, label: 'Analytics', route: AnalyticsRoute()),
  AppDrawerDestination(icon: LucideIcons.gamepad2, label: 'Mini Games', route: MiniGamesRoute()),
  AppDrawerDestination(icon: LucideIcons.moon, label: 'Sleep Tracker', route: SleepTrackerRoute()),
  AppDrawerDestination(icon: LucideIcons.footprints, label: 'Step Tracker', route: StepTrackerRoute()),
  AppDrawerDestination(icon: LucideIcons.brain, label: 'My Results', route: MyAssessmentRoute()),
  AppDrawerDestination(icon: LucideIcons.map, label: 'Roadmap', route: RoadmapRoute()),
  AppDrawerDestination(icon: LucideIcons.play, label: 'Roadmap Demo', route: Roadmap2Route()),
  AppDrawerDestination(icon: LucideIcons.bookOpen, label: 'Journaling', route: JournalRoute()),
  AppDrawerDestination(icon: LucideIcons.ban, label: 'Block Apps', route: BlockAppsRoute()),
  AppDrawerDestination(icon: LucideIcons.settings, label: 'Settings', route: SettingsRoute()),
  AppDrawerDestination(icon: LucideIcons.user, label: 'Profile', route: ProfileRoute()),
];

const List<AppDrawerSection> appDrawerSections = <AppDrawerSection>[
  AppDrawerSection(
    title: 'Main Features',
    items: <AppDrawerDestination>[
      AppDrawerDestination(icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: HomeRoute()),
      AppDrawerDestination(icon: LucideIcons.checkSquare, label: 'Daily Tasks', route: HomeRoute()),
      AppDrawerDestination(icon: LucideIcons.target, label: 'Challenges', route: ChallengesRoute()),
      AppDrawerDestination(icon: LucideIcons.timer, label: 'Focus Mode', route: FocusSessionRoute()),
      AppDrawerDestination(icon: LucideIcons.bookOpen, label: 'Journaling', route: JournalRoute()),
      AppDrawerDestination(icon: LucideIcons.footprints, label: 'Habit Tracker', route: StepTrackerRoute()),
    ],
  ),
  AppDrawerSection(
    title: 'Mental Health',
    items: <AppDrawerDestination>[
      AppDrawerDestination(icon: LucideIcons.brain, label: 'Assessment', route: MyAssessmentRoute()),
      AppDrawerDestination(icon: LucideIcons.heartPulse, label: 'Mood Tracking', route: MoodTrackingRoute()),
      AppDrawerDestination(icon: LucideIcons.barChart3, label: 'Progress Reports', route: AnalyticsRoute()),
      AppDrawerDestination(icon: LucideIcons.barChart3, label: 'Insights', route: InsightsRoute()),
    ],
  ),
  AppDrawerSection(
    title: 'Learning & Growth',
    items: <AppDrawerDestination>[
      AppDrawerDestination(icon: LucideIcons.map, label: 'Roadmaps', route: RoadmapRoute()),
      AppDrawerDestination(icon: LucideIcons.play, label: 'Roadmap Demo', route: Roadmap2Route()),
      AppDrawerDestination(icon: LucideIcons.graduationCap, label: 'Courses', route: CoursesRoute()),
      AppDrawerDestination(icon: LucideIcons.users, label: 'Community', route: CommunityRoute()),
      AppDrawerDestination(icon: LucideIcons.sparkles, label: 'AI Coach', route: AiChatRoute()),
    ],
  ),
  AppDrawerSection(
    title: 'Account',
    items: <AppDrawerDestination>[
      AppDrawerDestination(icon: LucideIcons.settings, label: 'Settings', route: SettingsRoute()),
      AppDrawerDestination(icon: LucideIcons.bell, label: 'Notifications', route: NotificationSettingsRoute()),
      AppDrawerDestination(icon: LucideIcons.creditCard, label: 'Subscription', route: SubscriptionRoute()),
      AppDrawerDestination(icon: LucideIcons.lifeBuoy, label: 'Help & Support', route: HelpSupportRoute()),
      AppDrawerDestination(icon: LucideIcons.info, label: 'About', route: AboutRoute()),
    ],
  ),
];

AppRouteData routeForLegacyIndex(int index) {
  switch (index) {
    case 0:
      return const HomeRoute();
    case 1:
      return const ChallengesRoute();
    case 2:
      return const MiniGamesRoute();
    case 3:
      return const CommunityRoute();
    case 4:
      return const AnalyticsRoute();
    case 5:
      return const SleepTrackerRoute();
    case 6:
      return const StepTrackerRoute();
    case 7:
      return const MyAssessmentRoute();
    case 8:
      return const RoadmapRoute();
    case 9:
      return const JournalRoute();
    case 10:
      return const JournalRoute();
    case 11:
      return const BlockAppsRoute();
    case 12:
      return const BlockAppsRoute();
    case 13:
      return const ProfileRoute();
    default:
      return const HomeRoute();
  }
}

const Set<String> publicRoutePrefixes = <String>{
  '/',
  WelcomeRoute.path,
  LoginRoute.path,
  SignUpRoute.path,
  ForgotPasswordRoute.path,
  '/onboarding',
  '/onboarding-flow',
  AvatarTestRoute.path,
};
