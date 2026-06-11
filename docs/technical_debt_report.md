# Technical Debt Report

## Executive Summary

This report identifies technical debt across the Flutter `/lib` codebase. Issues are categorized by severity with recommended remediation approaches.

---

## 1. Critical Technical Debt

### 1.1 Oversized Widgets

| File | Lines | Issue |
|------|-------|-------|
| `screens/analytics_screen.dart` | **2789** | Massive screen with business logic in UI layer |
| `screens/home_screen.dart` | **1123** | Large widget mixing UI and business logic |
| `screens/challenges_screen.dart` | **1400+** | Contains 4 separate `ChallengesScreen` class definitions - severe fragmentation |
| `features/community/ui/community_hub_screen.dart` | **984** | Large but relatively well-organized |
| `screens/streak_screen.dart` | **693** | Contains UI logic that could be extracted |

**Impact:** Maintainability nightmare, impossible to understand full context, high bug risk

**Recommendation:** Extract to separate widgets, create ViewModels, implement Clean Architecture

### 1.2 Duplicate Service Methods

**File: `services/screen_time_service.dart` (1082 lines)**

```dart
// Three nearly identical methods:
static Future<List<Map<String, dynamic>>> getRealUsageStats() async {...}
static Future<List<Map<String, dynamic>>> getAccurateUsageStats({String period = 'today'}) async {...}
static Future<List<Map<String, dynamic>>> getUltraAccurateUsageStats({String period = 'today'}) async {...}
```

**Issues:**
- Code duplication (~400 lines of similar logic)
- Inconsistent return types
- No clear differentiation between methods
- Same caching logic repeated

**Recommendation:** Consolidate into single method with enum/parameter for behavior differentiation

### 1.3 Static Service Pattern

**Affected Services:**
- `ScreenTimeService` - All static methods with internal state
- `FocusSessionService` - Static methods with state via callback
- `StreakService` - Static pattern
- `BadgeProvider` - Static initialization
- `RewardOrchestrator` - Static pattern

**Issues:**
- Not testable (cannot mock)
- Global mutable state
- Tight coupling
- Memory leaks possible (static state never cleaned)
- Difficult to debug

**Recommendation:** Convert to proper dependency injection with interface-based services

---

## 2. Important Technical Debt

### 2.1 Business Logic in UI Layer

**analytics_screen.dart** - Contains:
- Permission checking logic
- API call handling
- Data transformation
- Export functionality

**home_screen.dart** - Contains:
- Theme configuration
- Navigation logic
- Service instantiation
- Data formatting

**impact:** Violates separation of concerns, difficult to test business logic

### 2.2 Hardcoded Values Throughout

**Color Hardcoding (home_screen.dart):**
```dart
static const Color brandPurple = Color(0xFF7F7BC3);
static const Color brandLight = Color(0xFFD8BBEB);
// ... 10+ hardcoded colors
```

**String Hardcoding:**
- Multiple screens contain hardcoded strings
- No localization support visible
- Inconsistent text styling

**Recommendation:** Use design system tokens consistently, implement localization

### 2.3 Inconsistent Authentication Implementation

**Three overlapping implementations:**
1. `models/auth_model.dart` - Full auth model with login/logout/signup
2. `services/auth_service.dart` - Thin wrapper (42 lines)
3. `services/supabase_service.dart` - Token service (21 lines)
4. `features/community/services/community_supabase.dart` - Supabase client

**Issues:**
- Unclear which to use
- Duplicate functionality
- Confusing dependency graph

**Recommendation:** Consolidate to single auth pattern, likely keep AuthModel as primary

### 2.4 Provider Sprawl in main.dart

**30+ providers in single file (main.dart lines 227-348):**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ErrorHandlerModel()),
    Provider(create: (_) => CommunityRepository()),
    ChangeNotifierProvider(create: (_) => AuthModel()),
    // ... 25+ more
  ],
  ...
)
```

**Issues:**
- Single point of failure
- Impossible to understand full dependency graph
- Circular dependency risk (ProxyProviders)
- No lazy loading of providers

**Recommendation:** Split into provider modules by feature, implement provider interceptors

### 2.5 Inconsistent Naming Conventions

| Pattern | Example |
|---------|---------|
| camelCase | `screen_time_service.dart`, `auth_service.dart` |
| snake_case | `journal_entry.dart`, `focus_session.dart` |
| PascalCase | `AuthModel`, `UserModel`, `MissionModel` |
| Prefix pattern | `app_router.dart`, `app_routes.dart` |

**Impact:** Confusion, difficulty finding related files

**Recommendation:** Standardize on one naming convention (recommend: camelCase for files, PascalCase for classes)

### 2.6 Inconsistent Folder Organization

**Mix of patterns:**
- `features/community/` - Feature-based (good)
- `features/steps/` - Feature-based (good)
- `screens/` - All screens flat (poor)
- `services/` - All services flat (poor)
- `widgets/common/` - Subfolder (good)
- `widgets/streak/` - Subfolder (good)

**Recommendation:** Standardize on feature-based organization

---

## 3. Architecture Violations

### 3.1 Missing Abstractions

- Direct service instantiation in screens
- No use case layer for business logic
- No repository pattern (some services act as repositories)
- Direct model manipulation in UI

### 3.2 Tight Coupling

**Example from analytics_screen.dart:**
```dart
// Direct service call in UI
List<Map<String, dynamic>> realUsageStats = await ScreenTimeService.getUltraAccurateUsageStats(...);
```

**Should be:**
```dart
// Through abstraction
final usageStats = await _usageStatsUseCase.getUsageStats(period: _selectedTimePeriod);
```

### 3.3 Missing Error Handling Layer

- No centralized error handling
- Try-catch scattered throughout
- Inconsistent error messages
- No error recovery strategies

### 3.4 No Proper Logging

**Evidence:**
```dart
// Using print instead of proper logging
print('Error getting usage stats: $e');
debugPrint('Cache invalidated');
// Multiple debugPrint throughout
```

**Recommendation:** Implement proper logging framework (e.g., logger, dio interceptors)

---

## 4. Code Quality Issues

### 4.1 TODO Comments in Production

Found in multiple locations:
- `navigation/app_routes.dart` - Placeholder routes
- `screens/challenges_screen.dart` - Multiple class definitions indicate unfinished work
- Design system components - Some incomplete implementations

### 4.2 Debug Code in Production

```dart
// From screen_time_service.dart
debugPrint('[ScreenTimeService] getRealUsageStats called');
debugPrint('Cache invalidated');
// ~50+ debugPrint statements across codebase
```

### 4.3 Missing Documentation

- No documentation on public APIs
- No README files in feature directories
- Inline comments sparse
- No architecture decision records (ADRs)

### 4.4 Inconsistent Null Handling

- Mix of null checks, ! operators, and ? operators
- Some places use `??` defaults, others don't
- No consistent null safety strategy

---

## 5. Performance Concerns

### 5.1 Repeated API Calls

**analytics_screen.dart:**
- Multiple calls to ScreenTimeService
- No request deduplication
- No caching at UI layer

### 5.2 Unnecessary Rebuilds

- Many Consumer/Selector usages without proper selector functions
- Some setState calls that could use more targeted rebuilds
- No const constructors in frequently-built widgets

### 5.3 Large Bundle Size Indicators

- Multiple large dependencies imported in main.dart
- Google Fonts loaded unconditionally
- Fl_chart for charts (heavy dependency)
- flutter_animate for animations

---

## 6. Refactor Priority Summary

### Critical (Fix Immediately)

| Issue | Location | Effort |
|-------|----------|--------|
| Multiple class definitions | challenges_screen.dart | Medium |
| Duplicate service methods | screen_time_service.dart | Medium |
| Oversized analytics screen | analytics_screen.dart | High |

### Important (Plan for Next Sprint)

| Issue | Location | Effort |
|-------|----------|--------|
| Static service pattern | Multiple services | High |
| Provider sprawl | main.dart | Medium |
| Business logic in UI | Multiple screens | Medium |
| Hardcoded values | Throughout | Low |

### Nice to Have (Backlog)

| Issue | Location | Effort |
|-------|----------|--------|
| Naming standardization | Throughout | Low |
| Folder reorganization | lib/ | Medium |
| Documentation | All files | High |
| Logging implementation | Throughout | Medium |

---

## 7. Recommended Approach

### Phase 1: Stabilization (1-2 sprints)
1. Fix challenges_screen.dart class duplication
2. Remove debugPrint statements
3. Add TODO comments for known issues

### Phase 2: Architecture (2-3 sprints)
1. Consolidate authentication pattern
2. Refactor screen_time_service methods
3. Extract business logic from screens
4. Implement proper error handling

### Phase 3: Quality (Ongoing)
1. Standardize naming conventions
2. Reorganize folder structure
3. Add documentation
4. Implement proper logging

---

## 8. Metrics Summary

| Category | Count |
|----------|-------|
| Files with >600 lines | 5 |
| Static service classes | 8 |
| Duplicate method groups | 1 |
| Hardcoded color values | 50+ |
| Provider count | 30+ |
| Screen files | 47 |
| Service files | 30+ |

---

*Report generated from technical debt audit - May 2026*
*Priorities based on maintainability, bug risk, and development velocity impact*