import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../models/dashboard_data.dart';
import '../../utils/format_duration.dart';
import '../common/app_icon_widget.dart';

class MostUsedAppsList extends StatelessWidget {
  final DashboardData data;
  final Set<String> blockedPackages;
  final Map<String, int> appTimeLimits;
  final void Function(String packageName, String appName, String usageTime)
      onAppOptions;

  const MostUsedAppsList({
    super.key,
    required this.data,
    this.blockedPackages = const {},
    this.appTimeLimits = const {},
    required this.onAppOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final apps = data.usageData.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        color: tokens.cardFill,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? const <BoxShadow>[]
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Column(
        children: apps.map((app) {
          final appTime = formatDuration((app['usageTime'] as int) ~/ 1000);
          final pkg = app['packageName'] as String;
          final name = app['appName'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                AppIconWidget(
                  packageName: pkg,
                  appName: name,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : tokens.primaryText,
                        ),
                      ),
                      Text(
                        appTime,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? tokens.secondaryText : tokens.faintText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appTimeLimits.containsKey(pkg))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.accentGradient.colors.first
                          .withValues(alpha: 0.2),
                      borderRadius: AppRadius.sm,
                      border: Border.all(
                        color: tokens.accentGradient.colors.first,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: tokens.accentGradient.colors.first,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${appTimeLimits[pkg]}m',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tokens.accentGradient.colors.first,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                if (blockedPackages.contains(pkg))
                  const Icon(LucideIcons.shieldOff, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onAppOptions(pkg, name, appTime),
                  icon: const Icon(LucideIcons.shield, color: Colors.orange, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
