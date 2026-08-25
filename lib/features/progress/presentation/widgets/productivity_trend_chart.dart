import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/progress/models/productivity_metrics.dart';

class ProductivityTrendChart extends StatelessWidget {
  final List<DailyMetric> monthlyMetrics;

  const ProductivityTrendChart({super.key, required this.monthlyMetrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (monthlyMetrics.isEmpty) return const SizedBox.shrink();

    // Generate line spots for completion rate (0% to 100%)
    final List<FlSpot> spots = [];
    for (int i = 0; i < monthlyMetrics.length; i++) {
      final rate = monthlyMetrics[i].completionRate * 100;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Productivity Trend (30 Days)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completion Rate %',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: (monthlyMetrics.length - 1).toDouble(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.black87,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final metric = monthlyMetrics[spot.x.toInt()];
                          return LineTooltipItem(
                            '${metric.dayLabel}\n${spot.y.round()}% (${metric.completedCount}/${metric.plannedCount})',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            '${val.toInt()}%',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < monthlyMetrics.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                monthlyMetrics[idx].dayLabel,
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.3),
                            AppColors.secondary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}