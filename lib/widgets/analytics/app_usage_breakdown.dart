import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../models/dashboard_data.dart';
import '../../utils/format_duration.dart';
import '../common/app_icon_widget.dart';

class AppUsageBreakdown extends StatelessWidget {
  final DashboardData data;
  const AppUsageBreakdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;
    final apps = data.topApps;

    if (apps.isEmpty) return const SizedBox.shrink();

    final maxUsage = apps.isNotEmpty
        ? (apps[0]['usageTime'] as int) ~/ 1000
        : 1;

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
        children: [
          for (int i = 0; i < apps.length; i++) ...[
            _buildBarRow(context, apps[i], maxUsage),
            if (i < apps.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _buildBarRow(
    BuildContext context,
    Map<String, dynamic> app,
    int maxSeconds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final usageSeconds = (app['usageTime'] as int) ~/ 1000;
    final fraction = maxSeconds > 0 ? usageSeconds / maxSeconds : 0.0;

    return Column(
      children: [
        Row(
          children: [
            AppIconWidget(
              packageName: app['packageName'] as String,
              appName: app['appName'] as String,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app['appName'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : tokens.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pill,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : tokens.trackColor,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: fraction.clamp(0.01, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.pill,
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF5B7CFA),
                                    Color(0xFF8A6CF6),
                                    Color(0xFFB07BF5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              formatDuration(usageSeconds),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : tokens.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
