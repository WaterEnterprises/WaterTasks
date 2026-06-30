import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_list_model.dart';
import '../widgets/task_list_card.dart';
import '../widgets/glass_card.dart';
import 'task_list_detail_screen.dart';
import 'focus_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> _listColors = const [
    Color(0xFF00E5FF),
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          child: StatefulBuilder(
            builder: (ctx, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Task List',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'List name',
                    hintText: 'e.g. Work, Study, Chores',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'List color',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _listColors.map((color) {
                    final selected = color.toARGB32() == selectedColor;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = color.toARGB32()),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: Colors.white, width: 2.5)
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
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
                      dropdownColor:
                          Colors.black.withValues(alpha: 0.8),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          context
                              .read<TaskProvider>()
                              .addTaskList(name, selectedColor,
                                  checkInIntervalSeconds: intervalSeconds);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.taskLists.isEmpty
              ? Column(
                  children: [
                    const Spacer(),
                    Center(
                      child: GlassCard(
                        width: 260,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Icon(Icons.list_alt_rounded,
                                  size: 64, color: colors.outline),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text('No task lists yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: colors.outline)),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('Tap + to create your first list',
                                  style: TextStyle(color: colors.outline)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadTaskLists(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: provider.taskLists.length,
                    itemBuilder: (ctx, i) {
                      final list = provider.taskLists[i];
                      return TaskListCard(
                        taskList: list,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TaskListDetailScreen(taskList: list),
                          ),
                        ),
                        onDelete: () => _confirmDeleteList(list),
                      );
                    },
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delete List',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text('Delete "${list.name}" and all its tasks?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      context.read<TaskProvider>().deleteTaskList(list.id!);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
