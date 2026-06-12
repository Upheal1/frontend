import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/theme/upheal_home_theme.dart';

/// Shared calm / premium visuals for the UpHeal community surfaces.
/// Delegates to [UpHealHomeTheme] tokens so community pages match the home page
/// styling in both light and dark mode.
class CommunityDecor {
  CommunityDecor._();

  // ── Demo avatars / covers ──────────────────────────────────────────────────
  /// Returns a stable (per [key]) Pravatar URL (real human photos).
  static String avatarFor(String key) =>
      'https://i.pravatar.cc/150?u=$key';

  /// Returns a stable (per [key]) Picsum placeholder URL.
  static String groupCoverFor(String key) =>
      'https://picsum.photos/seed/$key/320/120';

  // ── Brand palette (used for avatar borders, chip accents) ──────────────────
  static const Color lavender = AppColors.purple;
  static const Color lavenderLight = AppColors.blue;
  static const Color mint = AppColors.teal;
  static const Color peach = AppColors.orange;
  static const Color roseAccent = AppColors.pink;
  static const Color warmGold = AppColors.warning;

  // ── Convenience helpers ────────────────────────────────────────────────────
  static UpHealHomeTheme _t(BuildContext context) =>
      Theme.of(context).upHealHome;

  // ── Card / surface ─────────────────────────────────────────────────────────

  /// Card decoration matching [UpHealHomeTheme] tokens (transparent glass in
  /// dark mode, white + purple shadow in light mode).
  static BoxDecoration glassCard(BuildContext context, {double? radius}) {
    final t = _t(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius ?? t.cardRadius),
      color: t.cardFill,
      border: Border.all(color: t.cardBorder),
      boxShadow: t.cardShadow == null
          ? const <BoxShadow>[]
          : <BoxShadow>[t.cardShadow!],
    );
  }

  static BoxDecoration pillAccent(BuildContext context) {
    final t = _t(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: LinearGradient(
        colors: [
          t.quickGroups.withValues(alpha: 0.45),
          t.quickGroups.withValues(alpha: 0.25),
        ],
      ),
      border: Border.all(color: t.quickGroups.withValues(alpha: 0.40)),
    );
  }

  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Same background gradient used by the home page ([UpHealHomeTheme.pageGradient]).
  static Gradient calmBackdrop(BuildContext context) => _t(context).pageGradient;

  static Gradient headerGradient(BuildContext context) {
    final t = _t(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        t.quickGroups.withValues(alpha: 0.40),
        t.quickGroups.withValues(alpha: 0.15),
      ],
    );
  }

  // ── FAB gradient ───────────────────────────────────────────────────────────
  /// Uses the same blue→purple gradient as the home page's accent.
  static const Gradient fabGradient = UpHealHomeTheme.sharedAccentGradient;

  // ── Shimmer colors ─────────────────────────────────────────────────────────
  static Color shimmerBase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1F1A33) : const Color(0xFFEEEFF4);
  }

  static Color shimmerHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2E2847) : const Color(0xFFF8F9FF);
  }
}
