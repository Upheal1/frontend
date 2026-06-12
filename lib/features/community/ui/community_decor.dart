import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

  /// Shared calm / premium visuals for the UpHeal community surfaces.
class CommunityDecor {
  CommunityDecor._();

  // ── Demo avatars / covers ──────────────────────────────────────────────────
  /// Returns a stable (per [key]) Pravatar URL (real human photos).
  static String avatarFor(String key) =>
      'https://i.pravatar.cc/150?u=$key';

  /// Returns a stable (per [key]) Picsum placeholder URL.
  static String groupCoverFor(String key) =>
      'https://picsum.photos/seed/$key/320/120';

  // ── Brand palette (from AppColors) ───────────────────────────────────────────
  static const Color lavender = AppColors.purple;
  static const Color lavenderLight = AppColors.blue;
  static const Color mint = AppColors.teal;
  static const Color peach = AppColors.orange;
  static const Color roseAccent = AppColors.pink;
  static const Color warmGold = AppColors.warning;

  // ── Card / surface ─────────────────────────────────────────────────────────

  /// Clean white card with a soft shadow (light) or dark-slate surface (dark).
  static BoxDecoration glassCard(BuildContext context, {double radius = 22}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: isDark ? AppColors.card : Colors.white,
      border: isDark
          ? Border.all(color: Colors.white.withValues(alpha: 0.07))
          : Border.all(color: AppColors.surface),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: AppColors.textMuted.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration pillAccent(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: LinearGradient(
        colors: [
          AppColors.purple.withValues(alpha: 0.18),
          AppColors.teal.withValues(alpha: 0.14),
        ],
      ),
      border: Border.all(color: AppColors.purple.withValues(alpha: 0.22)),
    );
  }

  // ── Backgrounds ────────────────────────────────────────────────────────────

  static Gradient calmBackdrop(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceDark, Color(0xFF0A0A12), AppColors.surfaceDark],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.surface, Color(0xFFF1F4FF), Color(0xFFF8F9FF)],
    );
  }

  static Gradient headerGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.purple.withValues(alpha: 0.20),
          AppColors.teal.withValues(alpha: 0.12),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.purple.withValues(alpha: 0.12),
        AppColors.teal.withValues(alpha: 0.08),
      ],
    );
  }

  // ── FAB gradient ───────────────────────────────────────────────────────────
  static const Gradient fabGradient = LinearGradient(
    colors: [lavender, mint],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Shimmer colors ─────────────────────────────────────────────────────────
  static Color shimmerBase(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF232636)
        : const Color(0xFFEEEFF4);
  }

  static Color shimmerHighlight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C3050)
        : const Color(0xFFF8F9FF);
  }
}
