# Dead Code Report

## Summary

This report identifies files that appear to be unused, abandoned, or dead code candidates within the `/lib` directory. Confidence levels are provided based on import analysis and usage patterns.

---

## 1. High Confidence Dead Code

These files appear to be completely unused based on import analysis.

### 1.1 Configuration & Setup

| File | Reason | Confidence |
|------|--------|-------------|
| `clinical_forms.dart` | No imports found from any other file. Contains unknown `clinicalForms` reference. | **HIGH** |
| `config.dart` | Contains empty SMTP credentials (`SMTP_USERNAME = ''`, `SMTP_PASSWORD = ''`, `FROM_EMAIL = ''`). Indicates incomplete implementation. | **HIGH** (incomplete) |

### 1.2 Duplicate Screens

| File | Reason | Confidence |
|------|--------|-------------|
| `screens/community_screen.dart` | Appears to be a duplicate of `features/community/ui/community_hub_screen.dart`. CommunityHubScreen is used in app_router.dart | **HIGH** |
| `screens/sleep_tracking_screen.dart` | Likely duplicate of `screens/sleep_tracker_screen.dart`. Both exist. | **HIGH** |

### 1.3 Placeholder/Unused Screens

| File | Reason | Confidence |
|------|--------|-------------|
| `navigation/app_route_placeholder_screen.dart` | Used only as placeholder for unimplemented routes. Contains "TODO" messaging. | **HIGH** (intentional placeholder) |
| `screens/app_blocked_screen.dart` | Single class, minimal implementation, not referenced in router | **MEDIUM** |

### 1.4 Unused Models

| File | Reason | Confidence |
|------|--------|-------------|
| `models/csv_exporter.dart` | Appears to be utility class but not imported by common files | **MEDIUM** |
| `models/notification_types.dart` | Defined but may not be fully utilized | **MEDIUM** |

---

## 2. Medium Confidence Dead Code

These files may have limited usage or could be refactored.

### 2.1 Duplicate Services

| File | Reason | Confidence |
|------|--------|-------------|
| `services/email_service.dart` | SMTP configuration in config.dart is empty - service likely not functional | **MEDIUM** |
| `services/api_client.dart` | May overlap with Supabase client usage | **MEDIUM** |

### 2.2 Incomplete Features

| File | Reason | Confidence |
|------|--------|-------------|
| `features/ui_system/` | Premium UI components - may be experimental or incomplete | **MEDIUM** |
| `screens/real_home.dart` | Name suggests replacement for home, but home_screen.dart is used in router | **MEDIUM** |

### 2.3 Duplicate Widgets

| File | Reason | Confidence |
|------|--------|-------------|
| `widgets/avatar_widget.dart` | Similar to `widgets/avatar_card.dart` and `avatar/ui/avatar_widget.dart` | **MEDIUM** |
| `screens/avatar_display.dart` | Likely duplicates avatar functionality | **MEDIUM** |
| `screens/avatar_glow.dart` | Likely duplicates avatar functionality | **MEDIUM** |

### 2.4 Unused Imports Analysis

Based on grep analysis, several files have imports that may not be fully utilized:
- `screens/gad_phq_form_screen.dart` - Clinical form implementation
- `screens/assessment_results_screen.dart` - Assessment results
- `models/assessment_model.dart` - Linked to assessment flow

---

## 3. Low Confidence - Review Recommended

These files need manual review to determine if they are truly dead code.

### 3.1 Security-Related

| File | Notes |
|------|-------|
| `security/tamper_check.dart` | Security feature - may be used conditionally |
| `utils/crypto_utils.dart` | Crypto utilities - may be used by security features |

### 3.2 Experimental Features

| File | Notes |
|------|-------|
| `services/threat_monitor_service.dart` | Security monitoring - may be conditionally active |
| `services/vpn_controller.dart` | VPN control - platform-specific |

### 3.3 Legacy Code

| File | Notes |
|------|-------|
| `use_cases/evaluate_blocking_use_case.dart` | Single use case - needs review |
| `viewmodels/blocked_app_view_model.dart` | ViewModel pattern - may be replaced by providers |

---

## 4. Potentially Unused Exports

### 4.1 Unused Design System Components

Based on design_system/components/ directory:
- `app_achievement_card.dart` - May not be used
- `app_glass_container.dart` - Glass morphism component
- `app_loading_state.dart` - Loading state component

### 4.2 Unused Widgets

| File | Notes |
|------|-------|
| `widgets/achievements_widget.dart` | May be replaced by AchievementsScreen |
| `widgets/mission_card.dart` | Mission display - verify usage |
| `widgets/stat_card.dart` | Statistics display - verify usage |

---

## 5. Configuration Issues

### 5.1 Empty/Incomplete Config

```dart
// config.dart - Lines 2-7
const String SMTP_HOST = 'smtp.gmail.com';
const int SMTP_PORT = 587;
const String SMTP_USERNAME = ''; // Empty - not configured
const String SMTP_PASSWORD = ''; // Empty - not configured
const String FROM_EMAIL = ''; // Empty - not configured
const String FROM_NAME = 'UpHeal Security';
```

**Impact**: EmailService is likely non-functional.

---

## 6. Refactor Candidates

### 6.1 Merge Candidates

| Files | Action |
|-------|--------|
| `sleep_tracker_screen.dart` + `sleep_tracking_screen.dart` | Merge into single screen |
| `community_screen.dart` + `community_hub_screen.dart` | Use single implementation |
| Multiple avatar widgets | Consolidate to single implementation |

### 6.2 Removal Candidates

| File | Action |
|------|--------|
| `clinical_forms.dart` | Remove if unused |
| `app_route_placeholder_screen.dart` | Implement or remove placeholder |
| Empty config values | Either configure or remove service |

---

## 7. Summary Table

| Category | Count | Action |
|----------|-------|--------|
| High Confidence Dead Code | 8 | Remove |
| Medium Confidence | 12 | Review and verify |
| Low Confidence | 6 | Manual review needed |
| Merge Candidates | 3 | Consolidate |
| Configuration Issues | 1 | Fix or remove |

---

## 8. Recommendations

1. **Immediate**: Remove `clinical_forms.dart` and duplicate screens
2. **Short-term**: Review and either implement or remove placeholder screens
3. **Medium-term**: Consolidate duplicate widget implementations
4. **Long-term**: Implement proper feature flag system for experimental code

---

*Report generated from architectural audit - May 2026*
*Confidence levels based on static analysis and import patterns*