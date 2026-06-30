import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_list_model.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/glass_card.dart';
import 'focus_screen.dart';

class TaskListDetailScreen extends StatefulWidget {
  final TaskListModel taskList;
  const TaskListDetailScreen({super.key, required this.taskList});

  @override
  State<TaskListDetailScreen> createState() => _TaskListDetailScreenState();
}

class _TaskListDetailScreenState extends State<TaskListDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks(widget.taskList.id!);
    });
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
                'New Task',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'What do you need to do?',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
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
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        final desc = descController.text.trim();
                        context.read<TaskProvider>().addTask(
                              widget.taskList.id!,
                              title,
                              desc.isNotEmpty ? desc : null,
                            );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTask(TaskModel task) async {
    final provider = context.read<TaskProvider>();
    await provider.startTask(task, widget.taskList);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FocusScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colors = Theme.of(context).colorScheme;
    final totalTasks = provider.currentTasks.length;
    final completedTasks =
        provider.currentTasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskList.name),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (totalTasks > 0)
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.zero,
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value:
                          totalTasks > 0 ? completedTasks / totalTasks : 0,
                      backgroundColor:
                          Color(widget.taskList.color).withValues(alpha: 0.2),
                      color: Color(widget.taskList.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$completedTasks/$totalTasks',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.currentTasks.isEmpty
                    ? Column(
                        children: [
                          const Spacer(),
                          Center(
                            child: GlassCard(
                              width: 220,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: Icon(Icons.task_alt_rounded,
                                        size: 56, color: colors.outline),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text('No tasks yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: colors.outline)),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text('Tap + to add a task',
                                        style: TextStyle(
                                            color: colors.outline)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            provider.loadTasks(widget.taskList.id!),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: provider.currentTasks.length,
                          itemBuilder: (ctx, i) {
                            final task = provider.currentTasks[i];
                            return TaskCard(
                              task: task,
                              accentColor: Color(widget.taskList.color),
                              onToggleComplete: () =>
                                  provider.toggleTaskComplete(task),
                              onStart: () => _startTask(task),
                              onDelete: () => _confirmDeleteTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _confirmDeleteTask(TaskModel task) {
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
                'Delete Task',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text('Delete "${task.title}"?'),
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
                      context.read<TaskProvider>().deleteTask(task);
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
