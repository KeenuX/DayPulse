import 'package:flutter/material.dart';
import 'package:daypulse/features/progress/models/streak_data.dart';

class StreakHeroCard extends StatelessWidget {
  final StreakData streakData;

  const StreakHeroCard({super.key, required this.streakData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Flame Hero Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),

                // Main Current Streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${streakData.currentStreak}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Day Streak',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        streakData.isTodaySuccessful
                            ? 'Today\'s goal completed! Streak extended.'
                            : 'Complete ≥${streakData.streakThresholdPercentage}% of tasks today to keep it going.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Sub Stats: Longest Streak & Total Successful Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StreakSubStat(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber[700]!,
                  label: 'Longest Streak',
                  value: '${streakData.longestStreak} days',
                ),
                Container(width: 1, height: 32, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                _StreakSubStat(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: Colors.teal,
                  label: 'Total Perfect Days',
                  value: '${streakData.totalSuccessfulDays} days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakSubStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StreakSubStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}