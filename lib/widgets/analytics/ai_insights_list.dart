import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../models/insight_model.dart';

class AiInsightsList extends StatelessWidget {
  final List<Insight> insights;
  final InsightsSummary? summary;
  final VoidCallback onViewAll;

  const AiInsightsList({
    super.key,
    required this.insights,
    this.summary,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null && insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? const <BoxShadow>[]
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: tokens.accentGradient,
                  borderRadius: AppRadius.md,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.accentGradient.colors.first
                          .withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.sparkles,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : tokens.primaryText,
                      ),
                    ),
                    if (summary != null)
                      Text(
                        'Wellness Score: ${summary!.overallHealthScore.toStringAsFixed(0)}/100',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: summary!.healthColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  backgroundColor: isDark
                      ? tokens.accentGradient.colors.first
                          .withValues(alpha: 0.2)
                      : tokens.cardFill,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill),
                ),
                icon: Icon(LucideIcons.arrowRight,
                    size: 14,
                    color: isDark ? Colors.white : tokens.primaryText),
                label: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : tokens.primaryText,
                  ),
                ),
              ),
            ],
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildInsightItem(context, insight),
                )),
          ],
          if (summary != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInsightStatChip(
                  context,
                  '${summary!.positiveCount} positive',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _buildInsightStatChip(
                  context,
                  '${summary!.warningCount} warnings',
                  const Color(0xFFFF9800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, Insight insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    final displayColor = insight.category == InsightCategory.critical
        ? const Color(0xFFF44336)
        : insight.categoryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : tokens.cardFill,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : tokens.dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.2),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(insight.icon, color: displayColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : tokens.faintText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStatChip(
      BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
