import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_list_model.dart';
import '../widgets/task_list_card.dart';
import 'task_list_detail_screen.dart';
import 'dashboard_screen.dart';
import 'focus_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> _listColors = const [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TaskProvider>();
      await provider.loadTaskLists();
      if (provider.hasActiveSession && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusScreen()),
        );
      }
    });
  }

  void _showAddListDialog() {
    final nameController = TextEditingController();
    int selectedColor = _listColors[0].toARGB32();
    int intervalSeconds = 120;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Task List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'List name',
                  hintText: 'e.g. Work, Study, Chores',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _listColors.map((color) {
                  final selected = color.toARGB32() == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color.toARGB32()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Check-in interval: ',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  DropdownButton<int>(
                    value: intervalSeconds,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30s')),
                      DropdownMenuItem(value: 60, child: Text('1m')),
                      DropdownMenuItem(value: 120, child: Text('2m')),
                      DropdownMenuItem(value: 300, child: Text('5m')),
                      DropdownMenuItem(value: 600, child: Text('10m')),
                      DropdownMenuItem(value: 900, child: Text('15m')),
                      DropdownMenuItem(value: 1800, child: Text('30m')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => intervalSeconds = v);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context
                      .read<TaskProvider>()
                      .addTaskList(name, selectedColor, checkInIntervalSeconds: intervalSeconds);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface,
              colors.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.taskLists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 80,
                            color: colors.outline),
                        const SizedBox(height: 16),
                        Text('No task lists yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colors.outline)),
                        const SizedBox(height: 8),
                        Text('Tap + to create your first list',
                            style: TextStyle(
                                color: colors.outline)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadTaskLists(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: provider.taskLists.length,
                      itemBuilder: (ctx, i) {
                        final list = provider.taskLists[i];
                        return TaskListCard(
                          taskList: list,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskListDetailScreen(taskList: list),
                            ),
                          ),
                          onDelete: () => _confirmDeleteList(list),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddListDialog,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }

  void _confirmDeleteList(TaskListModel list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Delete "${list.name}" and all its tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<TaskProvider>().deleteTaskList(list.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
