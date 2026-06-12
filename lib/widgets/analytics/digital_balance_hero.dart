import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DigitalBalanceHero extends StatelessWidget {
  final int totalSeconds;
  final int focusScore;
  final int appCount;
  final int blockedCount;
  final String periodLabel;

  const DigitalBalanceHero({
    super.key,
    required this.totalSeconds,
    required this.focusScore,
    required this.appCount,
    this.blockedCount = 0,
    this.periodLabel = 'Today',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    final accentColor = const Color(0xFF7C3AED);
    final cardBg1 = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF8FAFC);
    final cardBg2 = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    final scoreColor = _scoreColor(focusScore);
    final message = _motivationalMessage(focusScore);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardBg1, cardBg2],
            ),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.gauge, size: 22, color: accentColor),
                  const SizedBox(width: 10),
                  Text(
                    periodLabel == 'Today'
                        ? "Today's Digital Balance"
                        : 'Digital Balance — $periodLabel',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildMetricColumn(
                      icon: LucideIcons.clock,
                      label: 'Screen Time',
                      value: _formatTime(totalSeconds),
                      color: accentColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildScoreRing(focusScore, scoreColor, isDark),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMiniStat(LucideIcons.smartphone, '$appCount apps', subtextColor, isDark),
                  const SizedBox(width: 20),
                  _buildMiniStat(LucideIcons.shield, '$blockedCount blocked', subtextColor, isDark),
                  const Spacer(),
                  Icon(LucideIcons.sparkles, size: 14, color: scoreColor),
                  const SizedBox(width: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRing(int score, Color color, bool isDark) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 5,
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              Text(
                'Focus',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _motivationalMessage(int score) {
    if (score >= 80) return 'Great balance!';
    if (score >= 60) return 'Doing well!';
    if (score >= 40) return 'Room to improve';
    return 'Needs attention';
  }
}
