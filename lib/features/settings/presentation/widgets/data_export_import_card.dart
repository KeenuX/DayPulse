import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class DataExportImportCard extends ConsumerWidget {
  const DataExportImportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          // Export JSON
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Data (JSON)'),
            subtitle: const Text('Create a complete offline backup of your tasks and categories'),
            onTap: () async {
              try {
                final jsonStr = await ref.read(tasksNotifierProvider.notifier).exportJson();
                if (context.mounted) {
                  _showExportDialog(context, jsonStr);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
          const Divider(),

          // Import JSON
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import Data (JSON)'),
            subtitle: const Text('Restore tasks and categories from a backup string'),
            onTap: () => _showImportDialog(context, ref),
          ),
          const Divider(),

          // Clear All Data
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
            title: Text('Clear All Data', style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Erase all tasks, categories, and progress history'),
            onTap: () => _showClearConfirmationDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String jsonString) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Backup JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy this JSON backup text or save it to a safe place:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    bool overwrite = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Import Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your DayPulse JSON backup text below:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON content here...',
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Overwrite existing data', style: TextStyle(fontSize: 13)),
                value: overwrite,
                onChanged: (val) => setState(() => overwrite = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;

                try {
                  final count = await ref.read(tasksNotifierProvider.notifier).importJson(text, overwrite: overwrite);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully imported $count task(s)!')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to import: $e')),
                    );
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all tasks, categories, and progress statistics. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(tasksNotifierProvider.notifier).clearAll();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared.')),
                );
              }
            },
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}