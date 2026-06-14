import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';
import '../../models/dashboard_data.dart';
import '../../utils/format_duration.dart';

class ScreenLimitMeter extends StatelessWidget {
  final DashboardData data;
  const ScreenLimitMeter({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    final over = data.isOverLimit;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 18,
                color: tokens.accentGradient.colors.first,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Daily Screen Limit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : tokens.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final goalW = totalW * 0.67;
              final progress = data.limitProgress;
              final fillW = (progress * goalW).clamp(0.0, goalW);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.pill,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : tokens.trackColor,
                            ),
                          ),
                        ),
                        if (fillW > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: fillW,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: over
                                    ? const BorderRadius.horizontal(
                                        left: Radius.circular(999))
                                    : AppRadius.pill,
                                gradient: over
                                    ? LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          const Color(0xFF5B7CFA),
                                          const Color(0xFF8A6CF6),
                                          if (progress > 1.0)
                                            const Color(0xFFFF6B6B),
                                        ],
                                      )
                                    : const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF45D9A8),
                                          Color(0xFF6BCB8E),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        if (over)
                          Positioned(
                            left: goalW,
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(999)),
                              child: CustomPaint(
                                painter: const _StripePainter(
                                    color: Color(0xFFFF6B6B)),
                              ),
                            ),
                          ),
                        if (goalW < totalW - 4)
                          Positioned(
                            left: goalW - 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(1)),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '${data.formattedTotal} / 2h goal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : tokens.primaryText,
                        ),
                      ),
                      const Spacer(),
                      if (over)
                        Text(
                          '+${formatDuration(data.overageSeconds)} over',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        )
                      else
                        Text(
                          '${formatDuration(data.remainingSeconds)} left',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF45D9A8),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  const _StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final stripePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    const stripeWidth = 6.0;
    const gap = 6.0;
    final total = stripeWidth + gap;
    final count = (size.width / total).ceil() + 1;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < count; i++) {
      final x = i * total - (size.height * 0.3);
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth - size.height * 0.6, size.height)
        ..lineTo(x - size.height * 0.6, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}
