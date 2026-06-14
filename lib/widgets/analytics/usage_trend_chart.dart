import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../shared/theme/upheal_home_theme.dart';

class UsageTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> currentWeek;
  final List<Map<String, dynamic>> previousWeek;
  final GlobalKey? chartKey;

  const UsageTrendChart({
    super.key,
    required this.currentWeek,
    this.previousWeek = const [],
    this.chartKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    double maxY = 0;
    for (final point in currentWeek) {
      final hours = (point['usageHours'] as num).toDouble();
      if (hours > maxY) maxY = hours;
    }
    for (final point in previousWeek) {
      final hours = (point['usageHours'] as num).toDouble();
      if (hours > maxY) maxY = hours;
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 1) maxY = 1;

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
              _buildLegendItem(context, 'This Week', tokens.accentGradient.colors.first),
              const SizedBox(width: 16),
              _buildLegendItem(context, 'Last Week', const Color(0xFF9CA3AF)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          RepaintBoundary(
            key: chartKey,
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : tokens.dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}h',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white38
                                  : tokens.faintText,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < currentWeek.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                currentWeek[index]['dayLabel'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : tokens.faintText,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (currentWeek.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(currentWeek.length, (i) {
                        return FlSpot(
                            i.toDouble(),
                            (currentWeek[i]['usageHours'] as num)
                                .toDouble());
                      }),
                      isCurved: true,
                      color: tokens.accentGradient.colors.first,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: tokens.accentGradient.colors.first,
                            strokeWidth: 2,
                            strokeColor:
                                isDark ? Colors.white : const Color(0xFFFFFFFF),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: tokens.accentGradient.colors.first
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    if (previousWeek.isNotEmpty)
                      LineChartBarData(
                        spots: List.generate(previousWeek.length, (i) {
                          return FlSpot(
                              i.toDouble(),
                              (previousWeek[i]['usageHours'] as num)
                                  .toDouble());
                        }),
                        isCurved: true,
                        color: const Color(0xFF9CA3AF),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dashArray: [5, 5],
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFF9CA3AF),
                              strokeWidth: 0,
                            );
                          },
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          const Color(0xFF3A3A3A),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isCurrentPeriod = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}h',
                            GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCurrentPeriod
                                  ? tokens.accentGradient.colors.first
                                  : const Color(0xFF9CA3AF),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white54 : tokens.faintText,
          ),
        ),
      ],
    );
  }
}
