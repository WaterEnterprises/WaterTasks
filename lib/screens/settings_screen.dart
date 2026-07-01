import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/config_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check-in Tone',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Sound played when a check-in is due',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ToneType>(
                  segments: ToneType.values.map((tone) {
                    return ButtonSegment(
                      value: tone,
                      label: Text(_toneLabel(tone)),
                    );
                  }).toList(),
                  selected: {provider.toneType},
                  onSelectionChanged: (v) => provider.setToneType(v.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF00E5FF);
                      }
                      return colors.onSurfaceVariant;
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _toneDescription(provider.toneType),
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Management',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Export your lists, tasks, and sessions as a JSON file. '
                  'Import to restore data on another device.',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _export(context),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export Configuration'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                    onPressed: () => _import(context),
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import Configuration'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _toneLabel(ToneType tone) {
    switch (tone) {
      case ToneType.buzzer:
        return 'Buzzer';
      case ToneType.classicBeep:
        return 'Classic Beep';
      case ToneType.softChime:
        return 'Soft Chime';
      case ToneType.pulse:
        return 'Pulse';
      case ToneType.silent:
        return 'Silent';
    }
  }

  String _toneDescription(ToneType tone) {
    switch (tone) {
      case ToneType.buzzer:
        return '180Hz pulse wave with 90Hz sub — hard and continuous (default)';
      case ToneType.classicBeep:
        return 'Short 440Hz repeating beep';
      case ToneType.softChime:
        return 'Two-note ascending chime (C5 → E5)';
      case ToneType.pulse:
        return '65Hz sub-bass thump, 200ms on / 800ms off';
      case ToneType.silent:
        return 'No in-app sound — only OS notification';
    }
  }

  Future<void> _export(BuildContext context) async {
    final success = await ConfigService().exportToFile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Configuration exported' : 'Export cancelled'),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Import Configuration',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text(
                'This will replace all current data with the imported data. '
                'This cannot be undone.',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    final success = await ConfigService().importFromFile();
    if (!context.mounted) return;
    if (success) {
      context.read<TaskProvider>().loadTaskLists();
      context.read<TaskProvider>().loadSettings();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Configuration imported' : 'Import failed'),
      ),
    );
  }
}
