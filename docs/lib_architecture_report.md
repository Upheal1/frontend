# Flutter Lib Architecture Report

## Executive Summary

This document provides a comprehensive architectural audit of the Flutter `/lib` directory. The codebase contains approximately **180 Dart files** organized across multiple patterns with significant technical debt and architectural inconsistencies.

---

## 1. Architecture Overview

### 1.1 Project Structure

```
lib/
├── main.dart                    # App entry point with 30+ providers
├── config.dart                  # Configuration (SMTP, Supabase, API)
├── clinical_forms.dart           # Unknown purpose
│
├── navigation/                  # Routing system
│   ├── app_router.dart          # GoRouter configuration (481 lines)
│   ├── app_routes.dart           # Route definitions
│   ├── app_shell_scaffold.dart   # Tab navigation shell
│   └── ...
│
├── screens/                     # Screen implementations (47 screens)
│   ├── home_screen.dart         # 1123 lines - MASSIVE
│   ├── analytics_screen.dart    # 2789 lines - MASSIVE
│   ├── streak_screen.dart       # 693 lines
│   └── ...
│
├── services/                    # Business logic services
│   ├── screen_time_service.dart # 1082 lines - DUPLICATE METHODS
│   ├── focus_session_service.dart
│   ├── auth_service.dart
│   └── ... (30+ services)
│
├── models/                       # Data models
│   ├── user_model.dart
│   ├── auth_model.dart
│   ├── mission_model.dart
│   └── hive/                    # Hive adapters
│
├── widgets/                     # Reusable widgets
│   ├── common/                  # Shared components
│   ├── streak/                  # Streak-related
│   ├── rewards/                 # Gamification
│   └── ...
│
├── features/                    # Feature modules
│   ├── community/               # Community feature (well-organized)
│   ├── onboarding/              # Onboarding feature
│   ├── steps/                   # Step tracking feature
│   └── ui_system/               # Premium UI components
│
├── design_system/               # Design system (tokens, components)
│   ├── tokens/                  # Design tokens
│   └── components/              # Reusable UI components
│
├── constants/                  # App constants
├── gamification/                # Gamification config & models
├── security/                   # Security utilities
├── use_cases/                   # Business use cases
├── utils/                       # Utilities
└── viewmodels/                  # ViewModels
```

### 1.2 State Management Flow

**Primary Pattern: Provider with ChangeNotifier**

The app uses a complex MultiProvider setup in `main.dart` with 30+ providers:

```dart
// From main.dart lines 227-348
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ErrorHandlerModel()),
    Provider(create: (_) => CommunityRepository()),
    ChangeNotifierProvider(create: (_) => AuthModel()),
    ProxyProvider<AuthModel, AppRouter>(...),
    ChangeNotifierProvider(create: (_) => AvatarProvider()),
    ChangeNotifierProvider(create: (_) => RewardOrchestrator()),
    ChangeNotifierProvider(create: (_) => ChallengeService()),
    ChangeNotifierProvider(create: (_) => UserModel(...)),
    // ... 25+ more providers
  ],
  ...
)
```

**Issues Identified:**
- Excessive provider count in single file
- No clear separation between UI state and business state
- ProxyProviders create tight coupling
- No clear state management architecture (could benefit from BLoC or Riverpod)

### 1.3 Navigation Structure

**Implementation: GoRouter with StatefulShellRoute**

```
appRouter.router
├── GoRoute (redirect based on auth)
│   ├── WelcomeScreen (/welcome)
│   ├── LoginScreen (/auth/login)
│   ├── SignUpScreen (/auth/signup)
│   └── OnboardingScreen (/onboarding-flow)
│
└── StatefulShellRoute.indexedStack
    ├── Branch 1 (Home): HomeScreen, AnalyticsScreen, MiniGamesScreen...
    ├── Branch 2 (Challenges): ChallengesScreen
    ├── Branch 3 (Community): CommunityHubScreen, GroupChatScreen...
    └── Branch 4 (Profile): ProfileScreen, BadgesScreen, StreakScreen...
```

**Assessment:**
- Well-structured navigation with clear separation
- Proper auth redirect logic
- Deep linking support for placeholders
- Good use of StatefulShellRoute for tab persistence

### 1.4 Theming System

**Implementation: Custom theme with design tokens**

- Uses Google Fonts (Inter) as base
- Custom `UpHealTheme` with brand colors in home_screen.dart
- Design system tokens in `/design_system/tokens/`
- ThemeModel provider manages light/dark mode

**Assessment:**
- Inconsistent theming - hardcoded colors in some screens
- Design system exists but not uniformly applied
- Mix of direct color usage vs design tokens

### 1.5 Shared Components Strategy

**Dual Strategy:**
1. **Design System** (`/design_system/components/`): AppButton, AppCard, AppDialog, etc.
2. **Common Widgets** (`/widgets/common/`): ErrorSnackBar, LoadingOverlay, EmptyState, etc.

**Issues:**
- Both patterns in use - no clear preference
- Duplication between patterns
- Some components only partially implemented

---

## 2. File-by-File Analysis

### Core Files

| File Path | Purpose | Category | Complexity | Status |
|-----------|---------|----------|------------|--------|
| `main.dart` | App entry, provider setup, initialization | Core | High | Review Recommended |
| `config.dart` | App configuration (SMTP, Supabase, API) | Core | Low | Healthy |
| `clinical_forms.dart` | Unknown - appears unused | Legacy | Low | Dead Code Candidate |

### Navigation Files

| File Path | Lines | Purpose | Status |
|-----------|-------|---------|--------|
| `navigation/app_router.dart` | 481 | GoRouter setup | Healthy |
| `navigation/app_routes.dart` | 414 | Route definitions | Healthy |
| `navigation/app_shell_scaffold.dart` | - | Tab navigation | Healthy |

### Large Screen Files (Critical Issues)

| File Path | Lines | Issues |
|-----------|-------|--------|
| `screens/analytics_screen.dart` | 2789 | Massive, business logic in UI, duplicate API calls |
| `screens/home_screen.dart` | 1123 | Large widget, hardcoded theme, mixed concerns |
| `features/community/ui/community_hub_screen.dart` | 984 | Large but well-structured |
| `screens/streak_screen.dart` | 693 | Medium complexity |
| `screens/challenges_screen.dart` | 1400+ | **CRITICAL: Multiple class definitions!** |

### Service Files

| File Path | Lines | Issues |
|-----------|-------|--------|
| `services/screen_time_service.dart` | 1082 | Duplicate methods, static pattern |
| `services/focus_session_service.dart` | 378 | Static pattern, but well-organized |
| `services/auth_service.dart` | 42 | Thin wrapper - good pattern |
| `services/supabase_service.dart` | 21 | Thin wrapper - good pattern |
| `services/journal_service.dart` | 94 | Clean, well-organized |

### Model Files

The `/models` directory contains 30+ model files covering:
- User data (UserModel, AuthModel)
- Activity tracking (StreakModel, FocusSessionModel, SleepModel)
- Content (JournalEntry, MoodEntry, InsightModel)
- Hive models with generated adapters

---

## 3. Architecture Issues Summary

### Critical Issues

1. **Oversized Screens**: 5 screens exceed 600 lines
2. **Duplicate Methods**: ScreenTimeService has 3+ nearly identical methods
3. **Static Service Pattern**: Most services use static methods (not testable)
4. **Multiple Class Definitions**: challenges_screen.dart defines 4 `ChallengesScreen` classes

### Important Issues

1. **Inconsistent Organization**: Mix of feature-based and type-based organization
2. **Provider Sprawl**: 30+ providers in main.dart
3. **Authentication Complexity**: 3 overlapping auth implementations
4. **Design System Inconsistency**: Mixed usage of design tokens vs hardcoded values
5. **Naming Inconsistencies**: camelCase, snake_case, PascalCase mixed

### Technical Debt Indicators

- Hardcoded strings throughout
- print() statements instead of proper logging
- TODO comments in production code
- Placeholder screens with TODO labels

---

## 4. Connected Files Analysis

### Authentication Flow
```
AuthModel (models/auth_model.dart)
    ↓
    ├─→ AuthService (services/auth_service.dart)
    │       ↓
    │       └─→ CommunitySupabase (features/community/services/community_supabase.dart)
    │
    └─→ SupabaseService (services/supabase_service.dart)
            ↓
            └─→ CommunitySupabase
```

### Screen Time Flow
```
AnalyticsScreen (screens/analytics_screen.dart)
    ↓
ScreenTimeService (services/screen_time_service.dart)
    ↓
    ├─→ UsageCacheService (services/usage_cache_service.dart)
    ├─→ ScreenTimeModel (models/screen_time_model.dart)
    └─→ Native MethodChannel
```

### Community Flow
```
main.dart → CommunityRepository (injected)
    ↓
CommunityHubScreen (features/community/ui/community_hub_screen.dart)
    ↓
    ├─→ GroupsNotifier
    ├─→ FeedTab
    └─→ CommunityGroupsTab
```

---

## 5. Recommendations

### Immediate Actions

1. **Split analytics_screen.dart** into:
   - AnalyticsScreen (presentation only)
   - AnalyticsViewModel (state management)
   - UsageStatsUseCase (business logic)

2. **Remove duplicate methods** from ScreenTimeService:
   - Consolidate getRealUsageStats, getAccurateUsageStats, getUltraAccurateUsageStats
   - Use parameter-based differentiation

3. **Fix challenges_screen.dart** - multiple class definitions indicate merge conflicts or severe fragmentation

### Short-term Improvements

1. Implement proper dependency injection (not static services)
2. Standardize on one auth pattern
3. Apply design system consistently
4. Reduce provider count with better state organization

### Long-term Architecture

1. Consider migration to Riverpod or BLoC
2. Implement feature-based folder structure consistently
3. Add proper error handling layer
4. Implement proper logging instead of debugPrint

---

*Report generated from architectural audit of Flutter /lib directory*
*Date: May 2026*