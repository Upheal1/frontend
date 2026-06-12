# UpHeal Flutter Frontend — Project Report

## 1. Project Overview

| Field | Value |
|-------|-------|
| **App Name** | UpHeal |
| **Type** | Gamified mental health & wellness platform |
| **Version** | 1.0.0+1 |
| **SDK** | Flutter >=3.3.0, Dart >=3.3.0 |
| **Platform Targets** | Android, iOS, Web, Windows, macOS, Linux |
| **State Management** | Provider + Riverpod (ProviderScope) |
| **Navigation** | GoRouter (StatefulShellRoute.indexedStack) |
| **Local DB** | Hive, SharedPreferences, FlutterSecureStorage |
| **Remote DB** | Supabase (PostgreSQL) |
| **Project Path** | `frontend-main/frontend-main/` |

---

## 2. Directory Structure

```
frontend-main/                                       # Outer wrapper
  .github/java-upgrade/                              # Java upgrade tooling
  .vscode/launch.json                                # Debug configs
  └── frontend-main/                                 # ACTUAL FLUTTER PROJECT
        ├── android/                                 # Android platform (Kotlin)
        ├── ios/                                     # iOS platform (Swift)
        ├── linux/                                   # Linux desktop (C++)
        ├── macos/                                   # macOS desktop (Swift)
        ├── windows/                                 # Windows desktop (C++)
        ├── web/                                     # Web (HTML/JS)
        ├── assets/                                  # Static resources
        ├── lib/                                     # Main Dart source (~180 files)
        ├── test/                                    # Tests (6 files)
        ├── test_data/                               # Hive test fixtures
        ├── supabase/                                # Supabase config & migrations
        ├── docs/                                    # Internal reports
        ├── pubspec.yaml                             # Dependencies (60+)
        └── analysis_options.yaml                    # Lint rules
```

---

## 3. Source Code Breakdown (`lib/`)

### 3.1 Root Files

| File | Lines | Purpose |
|------|-------|---------|
| `main.dart` | 420 | App entry: Hive init, MultiProvider (30+ providers), GoRouter |
| `config.dart` | 28 | SMTP/Supabase/API configuration constants |
| `clinical_forms.dart` | 154 | GAD-7/PHQ-9 form definitions (unused — dead code candidate) |

### 3.2 Navigation (`lib/navigation/` — 8 files, ~2,337 lines)

| File | Lines | Role |
|------|-------|------|
| `app_router.dart` | 583 | GoRouter config: auth redirects, 4-tab shell |
| `app_routes.dart` | 554 | All route path constants & route configs |
| `app_shell_scaffold.dart` | 614 | Bottom nav shell with StatefulShellRoute |
| `custom_bottom_nav.dart` | 269 | Custom animated bottom navigation bar |
| `app_route_transitions.dart` | 188 | Custom route transition animations |
| `upheal_scaffold.dart` | 75 | Shared scaffold wrapper |
| `app_route_placeholder_screen.dart` | 48 | Placeholder for unimplemented routes |
| `app_navigation_keys.dart` | 6 | Global navigator keys |

### 3.3 Screens (`lib/screens/` — 43 entries, ~27 Dart files + 3 subdirectories)

**Largest screens (critical size):**

| File | Lines | Issues |
|------|-------|--------|
| `analytics_screen.dart` | **2,789** | Massive; business logic mixed with UI |
| `challenges_screen.dart` | **2,147** | Multiple class definitions (merge artifact?) |
| `assessment_results_screen.dart` | 1,501 | Very large result display |
| `settings_screen.dart` | 1,354 | Comprehensive settings UI |
| `home_screen.dart` | 1,282 | Dashboard with streaks, mood, stats |
| `insights_screen.dart` | 1,226 | AI-generated insight display |
| `journal_screen.dart` | 1,080 | Journal entries list & editor |
| `profile_screen.dart` | 997 | User profile & stats |
| `comparison_screen.dart` | 955 | Peer comparison views |
| `roadmap_screen.dart` | 936 | 90-day clinical roadmap display |
| `mood_tracker_screen.dart` | 863 | Mood logging calendar |
| `notification_settings_screen.dart` | 869 | Permission & notification config |
| `sleep_tracker_screen.dart` | 801 | Sleep tracking dashboard |
| `focus_session_screen.dart` | 796 | Focus timer UI |
| `my_assessment_screen.dart` | 794 | GAD-7/PHQ-9 assessment results |
| `achievements_screen.dart` | 775 | Badge & achievement gallery |
| `parental_control_screen.dart` | 762 | Parental restriction settings |
| `block_apps_screen.dart` | 679 | App blocking management |
| `gad_phq_form_screen.dart` | 696 | GAD-7/PHQ-9 questionnaire form |
| `streak_screen.dart` | 693 | Streak history & calendar |
| `login_screen.dart` | 650 | Email/password login |
| `signup_screen.dart` | 626 | Registration form |
| `ai_chat_screen.dart` | 444 | AI conversational chat |
| `community_screen.dart` | 454 | Community hub |
| `premium_focus_timer_screen.dart` | 395 | Premium timer variant |

**Subdirectories:**

| Directory | Files | Purpose |
|-----------|-------|---------|
| `screens/challenges/` | 3 | Avatar header, challenge card, progress card |
| `screens/games/` | 3 | Journaling history, Sudoku, Tic-tac-toe |
| `screens/onboarding/` | 1 | Analytics permission onboarding |

### 3.4 Services (`lib/services/` — 36 files, ~7,158 lines total)

| File | Lines | Role |
|------|-------|------|
| `screen_time_service.dart` | 1,082 | Usage stats, native MethodChannel, duplicate methods |
| `insights_service.dart` | 926 | AI insight generation logic |
| `upheal_api.dart` | 833 | REST API client for backend |
| `ai_insight_generator.dart` | 761 | LLM-based insight generation |
| `notification_service.dart` | 485 | Push notifications (local + remote) |
| `streak_service.dart` | 493 | Daily streak calculation & persistence |
| `screen_time_notification_service.dart` | 458 | Screen time limit alerts |
| `focus_session_service.dart` | 378 | Pomodoro session management |
| `comparison_service.dart` | 345 | Peer comparison data |
| `app_blocking_service.dart` | 281 | Native app blocking bridge |
| `challenge_service.dart` | 284 | Gamified challenge lifecycle |
| `roadmap_repository.dart` | 247 | Roadmap API fetch & cache |
| `usage_cache_service.dart` | 241 | Offline-first Hive cache layer |
| `mood_api_service.dart` | 195 | Mood API client |
| `export_service.dart` | 194 | Data export (CSV/JSON) |
| `sleep_service.dart` | 160 | Sleep tracking logic |
| `journal_local_service.dart` | 158 | Local journal storage |
| `badge_provider.dart` | 155 | Badge unlock conditions |
| `mood_local_service.dart` | 143 | Local mood storage |
| `onboarding_service.dart` | 144 | Onboarding progress |
| `journal_api_service.dart` | 135 | Journal API client |
| `mood_service.dart` | 117 | Mood data orchestrator |
| `journal_service.dart` | 94 | Journal CRUD orchestrator |
| `reward_orchestrator.dart` | 97 | XP/level/gamification hub |
| `comeback_reward_service.dart` | 92 | Re-engagement rewards |
| `email_service.dart` | 87 | SMTP email sender |
| `activity_detection_service.dart` | 70 | Physical activity detection |
| `error_handler_service.dart` | 68 | Global error handling |
| `ai_chat_service.dart` | 66 | AI chat API client |
| `auth_service.dart` | 42 | Authentication wrapper |
| `secure_storage_service.dart` | 36 | Encrypted storage |
| `vpn_controller.dart` | 23 | VPN detection |
| `threat_monitor_service.dart` | 22 | Security monitoring |
| `supabase_service.dart` | 21 | Supabase client wrapper |
| `firebase_auth_service.dart` | 3 | Firebase auth (stub) |
| `api_client.dart` | 0 | Empty file |

### 3.5 Models (`lib/models/` — 28 files + 6 Hive generated)

| File | Lines | Role |
|------|-------|------|
| `streak_model.dart` | 543 | Streak state & logic |
| `upheal_roadmap.dart` | 526 | Roadmap data model |
| `screen_time_model.dart` | 407 | Screen time state |
| `comparison_data.dart` | 364 | Peer comparison model |
| `achievement.dart` | 361 | Achievement definitions |
| `challenge_model.dart` | 371 | Challenge definitions |
| `parental_control_model.dart` | 371 | Parental controls state |
| `insight_model.dart` | 315 | AI insight model |
| `focus_session_model.dart` | 324 | Focus session state |
| `auth_model.dart` | 230 | Authentication state machine |
| `notification_types.dart` | 244 | Notification payload types |
| `screen_time_settings_model.dart` | 182 | Screen time settings |
| `mood_model.dart` | 163 | Mood state |
| `badge_model.dart` | 152 | Badge definitions |
| `journal_model.dart` | 150 | Journal state |
| `assessment_model.dart` | 133 | Assessment form state |
| `user_model.dart` | 122 | User profile & XP |
| `chat_model.dart` | 117 | Chat message model |
| `mood_entry.dart` | 105 | Mood entry data |
| `theme_model.dart` | 99 | Light/dark theme state |
| `journal_entry.dart` | 97 | Journal entry data |
| `sleep_model.dart` | 133 | Sleep tracking state |
| `sleep_session.dart` | 81 | Sleep session data |
| `focus_session.dart` | 63 | Focus session data |
| `mission_model.dart` | 48 | Mission/gamification state |
| `blocked_app.dart` | 23 | Blocked app model |

**Hive models (`lib/models/hive/`):**

| File | Lines | Role |
|------|-------|------|
| `focus_session_history.dart` | 166 | Session history Hive model |
| `block_rule.dart` | 104 | Block rule Hive model |
| `app_usage_cache.dart` | 78 | App usage cache Hive model |
| `*.g.dart` | 53-106 | Hive generated adapters (3 files) |

### 3.6 Widgets (`lib/widgets/` — ~60 files across subdirectories)

| Subdirectory | Files | Purpose |
|-------------|-------|---------|
| `widgets/common/` | 5 | AppIcon, EmptyState, ErrorSnackbar, Loading, Skeleton |
| `widgets/rewards/` | 7 | XP burst, level up, badge/avatar unlock overlays, streak milestone |
| `widgets/streak/` | 6 | Calendar, celebration, freeze dialog, milestone & stats cards |
| `widgets/analytics/` | 3 | Export bottom sheet, limited functionality banner, offline indicator |
| `widgets/comparison/` | 1 | Comparison data card |
| `widgets/focus/` | 2 | Blocked apps selector, session timer |
| `widgets/insights/` | 1 | Insight card (838 lines) |
| `widgets/onboarding/` | 1 | Permission step widget |

**Root-level widget files (19):** Achievement card, avatar card, distraction modal, focus mode card, timer, mission card, mood calendar, stat cards, theme switcher, XP bar, 3D traveler viewer, roadmap demo video, etc.

### 3.7 Design System (`lib/design_system/` — 29 files)

| Component | Files | Lines |
|-----------|-------|-------|
| `tokens/` | 12 | Colors, spacing, radii, shadows, gradients, typography, elevations, icon sizes, motion, effects |
| `responsive/` | 2 | AppResponsiveRoot (231 lines), barrel export |
| `components/` | 14 | AppButton (236), AppAvatar (166), AppDialog (144), AppInput (132), AppBottomSheet (120), AppAchievementCard (106), AppGlassContainer (103), AppCard (96), AppEmptyState (83), AppChip (80), AppLoadingState (72), AppSectionHeader (56), AppErrorState (30) |

### 3.8 Features (`lib/features/`)

| Feature | Files | Lines | Description |
|---------|-------|-------|-------------|
| `community/` | 17 | Social hub: feed, groups, chat, posts, focus rooms |
| `onboarding/` | 4 | Welcome flow: data, screens, widgets |
| `steps/` | 11 | Pedometer: sensors, Samsung Health, permissions, goals |
| `ui_system/` | 4 | Premium UI: home screen, bottom nav, side menu, components |

### 3.9 Other Directories

| Directory | Files | Purpose |
|-----------|-------|---------|
| `avatar/` | 6 | Avatar provider, progression, screen, widget, configs |
| `theme/` | 1 | UpHealThemeData (light/dark) |
| `constants/` | 2 | AppColors (263 lines), Animations (132 lines) |
| `config/` | 3 | Supabase community env & key loaders |
| `core/` | 3 | Supabase config, error boundary, navigation service |
| `shared/` | 9 | Shared navigation, theme, widgets |
| `gamification/` | 2 | XP config, wellness activity models |
| `security/` | 1 | Tamper check |
| `utils/` | 2 | Crypto utils, API exceptions |
| `viewmodels/` | 1 | Blocked app viewmodel |
| `use_cases/` | 1 | Evaluate blocking use case |

---

## 4. Key Metrics

| Metric | Count |
|--------|-------|
| **Total Dart files** | ~180 |
| **Total lines of Dart** | ~55,000+ |
| **Screens** | ~40 |
| **Services** | 36 |
| **Models** | 28 (data) + 6 (Hive generated) |
| **Widgets** | ~60 |
| **Test files** | 6 |
| **Root markdown files** | 11 |
| **Dependencies (pubspec.yaml)** | 60+ |
| **Platform targets** | 6 (Android, iOS, Web, Windows, macOS, Linux) |

---

## 5. State Management Architecture

```
ProviderScope (Riverpod root)
  └── MultiProvider (DI container)
        ├── ErrorHandlerModel         → Global error state
        ├── CommunityRepository       → Community data
        ├── AuthModel                 → Auth state machine
        ├── ProxyProvider             → AppRouter (depends on AuthModel)
        ├── AvatarProvider            → Avatar selection state
        ├── RewardOrchestrator        → XP/gamification hub
        ├── ChallengeService          → Challenge lifecycle
        ├── ProxyProvider             → AvatarProgressionProvider
        ├── ProxyProvider5            → BadgeProvider
        ├── MissionsModel             → Mission state
        ├── ParentalControlModel      → Parental controls
        ├── SleepModel                → Sleep tracking
        ├── StepTrackerState          → Pedometer
        ├── ThemeModel                → Light/dark mode
        ├── StreakState               → Daily streaks
        ├── FocusSessionState         → Focus sessions
        ├── ScreenTimeModel           → Screen time
        ├── JournalModel              → Journal entries
        └── MoodModel                 → Mood entries
```

**Data flow:** Screen → Model (ChangeNotifier) ↔ Service → API/Hive/MethodChannel → notifyListeners() → UI rebuild

---

## 6. Navigation Architecture

```
GoRouter
├── /welcome              → WelcomeScreen
├── /auth/login           → LoginScreen
├── /auth/signup          → SignUpScreen
├── /onboarding-flow      → OnboardingFlow
│
└── StatefulShellRoute.indexedStack (4 tabs)
    ├── Tab 0: Home
    │   ├── /                     → HomeScreen (dashboard)
    │   ├── /analytics            → AnalyticsScreen
    │   ├── /mini-games           → MiniGamesScreen
    │   ├── /mood                 → MoodTrackerScreen
    │   ├── /journal              → JournalScreen
    │   ├── /roadmap              → RoadmapScreen
    │   ├── /sleep                → SleepTrackerScreen
    │   └── /ai-chat              → AIChatScreen
    │
    ├── Tab 1: Challenges
    │   ├── /                     → ChallengesScreen
    │   ├── /badges               → BadgesScreen
    │   └── /missions             → MissionsScreen
    │
    ├── Tab 2: Community
    │   ├── /                     → CommunityHubScreen
    │   ├── /groups/:id           → GroupChatScreen
    │   ├── /feed                 → FeedScreen
    │   └── /leaderboard          → LeaderboardScreen
    │
    └── Tab 3: Profile
        ├── /                     → ProfileScreen
        ├── /badges               → BadgesScreen
        ├── /streaks              → StreakScreen
        ├── /settings             → SettingsScreen
        └── /parental-controls    → ParentalControlsScreen
```

---

## 7. Assets

| Type | Count | Details |
|------|-------|---------|
| **3D Models (GLB)** | 6 | 5 traveler evolution stages + 1 junior |
| **Images (PNG)** | 8 | App icon, 4 avatars (boy/girl), 3 onboarding |
| **Videos** | 1 | `roadmap_demo.mp4` |

---

## 8. Dependencies

### State Management
`provider`, `flutter_riverpod`

### Routing
`go_router`

### UI & Animation
`google_fonts`, `flex_color_scheme`, `lucide_icons`, `lottie`, `animated_text_kit`, `flutter_animate`, `shimmer`, `confetti`, `fl_chart`

### Storage
`hive` (×2), `sqflite`, `shared_preferences`, `flutter_secure_storage`

### Networking
`dio`, `http`, `supabase_flutter`, `json_rpc_2`

### Native Bridge
`device_info_plus`, `package_info_plus`, `sensors_plus`, `pedometer`, `local_auth`, `permission_handler`, `usage_stats`, `url_launcher`, `share_plus`, `path_provider`, `image_picker`, `video_player`, `o3d`

### Notifications
`flutter_local_notifications`, `awesome_notifications`, `elegant_notification`, `timezone`

### Security
`crypto`, `local_auth`

### Utilities
`intl`, `responsive_framework`, `mailer`, `stack_trace`

### Dev
`build_runner`, `hive_generator`, `flutter_launcher_icons`, `flutter_lints`

---

## 9. Platform Configurations

### Android (`android/`)
- **Kotlin sources**: 15 files (MainActivity, accessibility service, VPN service, device admin, boot receiver, guard service, usage stats, health data, edge AI classifiers, security event bus)
- **ML Model**: `nsfw_model.tflite` (NSFW content detection)
- **Permissions**: Usage stats, notification listener, device admin, accessibility service, system alert window
- **minSdk**: 26, **JDK**: 17

### iOS (`ios/`)
- **Swift + ObjC** sources
- **Permissions**: Motion, Health, Notifications, Speech
- **Storyboards**: Main + LaunchScreen

### Windows (`windows/`)
- **C++** runner (main.cpp, flutter_window.cpp, win32_window.cpp)
- **CMake** build system

### macOS (`macos/`)
- **Swift** sources (AppDelegate, MainFlutterWindow)
- **App icons**: 16px–1024px

### Linux (`linux/`)
- **C++** runner (main.cc, my_application.cc)
- **CMake** build system

### Web (`web/`)
- **PWA** manifest with icons (192px, 512px, maskable)
- **HTML/JS** entry point

---

## 10. Supabase Integration

### Migrations (7 files)
| Migration | Purpose |
|-----------|---------|
| `001_upheal_community.sql` | Community schema |
| `002_community_public_users_sync.sql` | User sync |
| `003_timeline_moderation.sql` | Content moderation |
| `004_group_messages_realtime_broadcast.sql` | Real-time chat |
| `005_public_read_posts.sql` | Public read policy |
| `006_perf_indexes_constraints_ratelimit.sql` | Performance + rate limiting |
| `007_group_members_upsert_policy.sql` | Member upsert policy |

### Edge Functions (2)
| Function | Stack |
|----------|-------|
| `send-message` | Deno/TypeScript |
| `create-post` | Deno/TypeScript |

---

## 11. Test Coverage

| Test File | What It Tests |
|-----------|--------------|
| `widget_test.dart` | Basic widget smoke test |
| `models/upheal_roadmap_test.dart` | Roadmap model parsing |
| `screens/gad_phq_screen_time_payload_test.dart` | Screen time payload with GAD/PHQ |
| `services/upheal_api_test.dart` | API client behavior |
| `services/supabase_service_test.dart` | Supabase integration |
| `use_cases/evaluate_blocking_test.dart` | Blocking logic |

**Note**: 6 test files for ~180 Dart source files — significantly under-tested.

---

## 12. Known Issues (from Reports)

### Critical
1. **Oversized screens**: `analytics_screen.dart` (2,789 lines), `challenges_screen.dart` (2,147 lines)
2. **Duplicate methods**: `ScreenTimeService` has 3+ nearly identical methods
3. **Static service pattern**: Most services use static methods (not testable)
4. **Multiple class definitions** in `challenges_screen.dart` (merge artifact)

### Important
5. **Inconsistent organization**: Mix of feature-based and type-based directory structure
6. **Provider sprawl**: 30+ providers in `main.dart`
7. **Design system inconsistency**: Hardcoded colors mixed with design tokens
8. **Dead code**: `clinical_forms.dart` (unused), `api_client.dart` (empty)
9. **Naming inconsistencies**: camelCase, snake_case, PascalCase mixed

---

## 13. Architecture Patterns

### Offline-First (Screen Time)
```
API Call → Network Try → Success? → Cache to Hive → Display
                          No
                          ↓
                    Read Hive Cache → Display with offline indicator
```

### Gamification Flow
```
User Action → RewardOrchestrator → XP added → Level up?
                                      ↓
                                  BadgeProvider → AvatarProgression
                                      ↓
                                  StreakService → ChallengeService
```

### API Data Flow
```
Screen → Model (ChangeNotifier) → Service → UphealApi (Dio) → Backend
                                                          ↓
                                                    Cache to Hive
                                                          ↓
                                         ← AssessGatewayResponse
```
