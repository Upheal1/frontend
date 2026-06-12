import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HealthyLimitsCard extends StatelessWidget {
  final int totalSeconds;
  final int totalAppCount;
  final int blockedCount;
  final int focusScore;

  const HealthyLimitsCard({
    super.key,
    required this.totalSeconds,
    this.totalAppCount = 0,
    this.blockedCount = 0,
    this.focusScore = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    final cardBg1 = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50;
    final cardBg2 = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    final green = const Color(0xFF4CAF50);
    final amber = const Color(0xFFFFC107);

    final totalMinutes = totalSeconds ~/ 60;
    final isUnderLimit = totalMinutes <= 120;
    final remainingMinutes = isUnderLimit ? 120 - totalMinutes : totalMinutes - 120;
    final progress = totalMinutes > 0 ? (totalMinutes / 120.0).clamp(0.0, 1.0) : 0.0;
    final limitColor = isUnderLimit ? green : amber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg1, cardBg2],
        ),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.heart, size: 20, color: green),
              const SizedBox(width: 8),
              Text(
                'Healthy Screen Habits',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnderLimit
                          ? 'You\'re within the recommended 2-hour limit'
                          : '$remainingMinutes min over the recommended limit',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(limitColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _tipIcon(LucideIcons.checkCircle2, green),
                        const SizedBox(width: 6),
                        Text(
                          _tipText(totalMinutes, blockedCount, focusScore),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalAppCount > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _miniPill(LucideIcons.smartphone, '$totalAppCount apps used', green, isDark),
                const SizedBox(width: 8),
                _miniPill(LucideIcons.shield, '$blockedCount blocked', subtextColor, isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipIcon(IconData icon, Color color) {
    return Icon(icon, size: 14, color: color);
  }

  Widget _miniPill(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _tipText(int totalMinutes, int blockedCount, int focusScore) {
    if (totalMinutes <= 60) return 'Great start — keep screen time intentional.';
    if (totalMinutes <= 120) return 'You\'re within healthy limits. Try taking short breaks.';
    if (focusScore >= 60) return 'Good usage balance — consider winding down soon.';
    if (blockedCount > 3) return 'Blocked apps are helping. Reduce idle scrolling next.';
    return 'Try setting app time limits to stay on track.';
  }
}
