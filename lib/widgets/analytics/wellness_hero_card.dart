import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../utils/format_duration.dart';
import '../../models/dashboard_data.dart';

class WellnessHeroCard extends StatefulWidget {
  final DashboardData data;
  const WellnessHeroCard({super.key, required this.data});

  @override
  State<WellnessHeroCard> createState() => _WellnessHeroCardState();
}

class _WellnessHeroCardState extends State<WellnessHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.deliberate,
      vsync: this,
    );
    _ringAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.entrance,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final score = widget.data.focusScore;
    final total = widget.data.formattedTotal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  tokens.pageBackground.withValues(alpha: 0.78),
                ],
              ),
        color: isDark ? tokens.cardFill : null,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? const <BoxShadow>[]
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: Row(
        children: [
          _buildGradientRing(context, score),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Screen time today',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? tokens.secondaryText : tokens.faintText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildOverGoalPill(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientRing(BuildContext context, int score) {
    final tokens = Theme.of(context).upHealHome;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _GradientRingPainter(
                    progress: score / 100 * _ringAnimation.value,
                    accentColors: const [
                      Color(0xFF5B7CFA),
                      Color(0xFF8A6CF6),
                      Color(0xFFB07BF5),
                    ],
                    trackColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : tokens.trackColor,
                    strokeWidth: 6,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: isDark ? Colors.white : tokens.primaryText,
                    ),
                  ),
                  Text(
                    'Wellness',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? tokens.secondaryText : tokens.faintText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverGoalPill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;

    if (data.isOverLimit) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE53E3E))
              .withValues(alpha: 0.15),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE53E3E))
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle,
                size: 12,
                color: isDark
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFFE53E3E)),
            const SizedBox(width: 4),
            Text(
              '+${formatDuration(data.overageSeconds)} over 2h goal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFFE53E3E),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF45D9A8).withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: const Color(0xFF45D9A8).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.checkCircle,
              size: 12, color: const Color(0xFF45D9A8)),
          const SizedBox(width: 4),
          Text(
            '${formatDuration(data.remainingSeconds)} remaining',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF45D9A8),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final List<Color> accentColors;
  final Color trackColor;
  final double strokeWidth;

  _GradientRingPainter({
    required this.progress,
    required this.accentColors,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final gradientPaint = Paint()
      ..shader = gradient(accentColors).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, gradientPaint);
  }

  LinearGradient gradient(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => old.progress != progress;
}
