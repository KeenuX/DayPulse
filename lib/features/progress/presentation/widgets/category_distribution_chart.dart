import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:daypulse/features/progress/models/productivity_metrics.dart';

class CategoryDistributionChart extends StatefulWidget {
  final List<CategoryDistribution> distribution;

  const CategoryDistributionChart({super.key, required this.distribution});

  @override
  State<CategoryDistributionChart> createState() => _CategoryDistributionChartState();
}

class _CategoryDistributionChartState extends State<CategoryDistributionChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.distribution.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Category Distribution',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Assign tasks to categories to see your time and focus breakdown.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: List.generate(widget.distribution.length, (i) {
                        final item = widget.distribution[i];
                        final isTouched = i == _touchedIndex;
                        final radius = isTouched ? 34.0 : 28.0;

                        return PieChartSectionData(
                          color: Color(item.colorValue),
                          value: item.taskCount.toDouble(),
                          title: '',
                          radius: radius,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Category List & Percentages
                Expanded(
                  child: Column(
                    children: widget.distribution.map((item) {
                      final percent = (item.percentage * 100).round();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(item.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}