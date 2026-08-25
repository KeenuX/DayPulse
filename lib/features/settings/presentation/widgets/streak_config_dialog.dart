import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/settings/providers/settings_provider.dart';

class StreakConfigDialog extends ConsumerStatefulWidget {
  final int currentThreshold;

  const StreakConfigDialog({super.key, required this.currentThreshold});

  static Future<void> show(BuildContext context, int currentThreshold) {
    return showDialog(
      context: context,
      builder: (ctx) => StreakConfigDialog(currentThreshold: currentThreshold),
    );
  }

  @override
  ConsumerState<StreakConfigDialog> createState() => _StreakConfigDialogState();
}

class _StreakConfigDialogState extends ConsumerState<StreakConfigDialog> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    _threshold = widget.currentThreshold.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Streak Success Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A day counts toward your streak when you complete at least this percentage of planned tasks:',
            style: TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${_threshold.round()}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Slider(
            value: _threshold,
            min: 50,
            max: 100,
            divisions: 10,
            label: '${_threshold.round()}%',
            onChanged: (val) => setState(() => _threshold = val),
          ),
          const SizedBox(height: 8),
          Text(
            'Default is 70%. Keeping it balanced avoids burnout while ensuring daily progress.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref.read(userSettingsProvider.notifier).setStreakThreshold(_threshold.round());
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}