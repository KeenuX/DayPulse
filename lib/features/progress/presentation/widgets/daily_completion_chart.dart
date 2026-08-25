import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/progress/models/productivity_metrics.dart';

class DailyCompletionChart extends StatelessWidget {
  final List<DailyMetric> metrics;

  const DailyCompletionChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find max value for Y axis scaling
    double maxY = 5;
    for (final m in metrics) {
      if (m.plannedCount > maxY) maxY = m.plannedCount.toDouble();
    }
    maxY = (maxY + 2).ceilToDouble();

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
                    'Daily Completion (Last 7 Days)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _LegendDot(color: AppColors.primary, label: 'Done'),
                const SizedBox(width: 8),
                _LegendDot(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  label: 'Plan',
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final metric = metrics[group.x.toInt()];
                        return BarTooltipItem(
                          '${metric.dayLabel}\n${metric.completedCount} / ${metric.plannedCount} completed',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (maxY / 4).clamp(1.0, 10.0),
                        getTitlesWidget: (val, meta) {
                          if (val % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            val.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < metrics.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                metrics[idx].dayLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).clamp(1.0, 10.0),
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(metrics.length, (index) {
                    final metric = metrics[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        // Background planned rod
                        BarChartRodData(
                          toY: metric.plannedCount.toDouble(),
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [
                            // Foreground completed rod
                            BarChartRodStackItem(
                              0,
                              metric.completedCount.toDouble(),
                              AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}