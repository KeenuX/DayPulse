import 'package:flutter/material.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/productivity_calculator.dart';

class ProductivityScoreCard extends StatelessWidget {
  final ProductivityScoreBreakdown score;

  const ProductivityScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color scoreColor;
    if (score.totalScore >= 80) {
      scoreColor = AppColors.success;
    } else if (score.totalScore >= 50) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Info Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.speed_rounded, color: scoreColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Productivity Score',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  tooltip: 'How score is calculated',
                  onPressed: () => _showScoreExplainer(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score Display (e.g. 82 / 100)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${score.totalScore}',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Human Explanation Text
            Text(
              score.summaryExplanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),

            // Points mini bars (Completion 40, Priority 30, Overdue 15, Consistency 15)
            Row(
              children: [
                _ScoreMiniBar(
                  label: 'Completion',
                  points: score.completionPoints,
                  maxPoints: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _ScoreMiniBar(
                  label: 'Priority',
                  points: score.priorityPoints,
                  maxPoints: 30,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ScoreMiniBar(
                  label: 'Punctuality',
                  points: score.punctualityPoints,
                  maxPoints: 15,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 10),
                _ScoreMiniBar(
                  label: 'Streak',
                  points: score.consistencyPoints,
                  maxPoints: 15,
                  color: Colors.amber[600]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreExplainer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calculate_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Score Calculation'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Productivity Score (0–100) is calculated transparently from four core factors:',
              style: TextStyle(fontSize: 13.5),
            ),
            SizedBox(height: 14),
            _ExplainerRow(title: 'Task Completion (Max 40 pts)', desc: 'Percentage of scheduled tasks completed today.'),
            SizedBox(height: 8),
            _ExplainerRow(title: 'High-Priority Focus (Max 30 pts)', desc: 'Completion of high-impact priority tasks.'),
            SizedBox(height: 8),
            _ExplainerRow(title: 'Punctuality (Max 15 pts)', desc: 'Full points if no tasks are left overdue.'),
            SizedBox(height: 8),
            _ExplainerRow(title: 'Streak & Consistency (Max 15 pts)', desc: 'Maintaining active multi-day productivity streaks.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ScoreMiniBar extends StatelessWidget {
  final String label;
  final int points;
  final int maxPoints;
  final Color color;

  const _ScoreMiniBar({
    required this.label,
    required this.points,
    required this.maxPoints,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxPoints > 0 ? (points / maxPoints).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
              Text('$points/$maxPoints', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainerRow extends StatelessWidget {
  final String title;
  final String desc;

  const _ExplainerRow({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}