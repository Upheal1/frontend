import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../models/dashboard_data.dart';

class QuickStatsRow extends StatelessWidget {
  final DashboardData data;
  const QuickStatsRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        color: tokens.cardFill,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          _statItem(
            context,
            icon: LucideIcons.messageCircle,
            label: 'Social',
            value: data.formattedSocialMedia,
          ),
          _divider(isDark, tokens),
          _statItem(
            context,
            icon: LucideIcons.grid,
            label: 'Apps used',
            value: '${data.appCount}',
          ),
          _divider(isDark, tokens),
          _statItem(
            context,
            icon: LucideIcons.target,
            label: 'Focus sessions',
            value: '${data.focusSessions}',
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: tokens.accentGradient.colors.first),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: isDark ? Colors.white : tokens.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? tokens.secondaryText : tokens.faintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark, UpHealHomeTheme tokens) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? tokens.dividerColor : tokens.dividerColor,
    );
  }
}
