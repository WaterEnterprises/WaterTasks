import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'glass_card.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Color accentColor;
  final VoidCallback onToggleComplete;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.accentColor,
    required this.onToggleComplete,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggleComplete(),
            activeColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? Theme.of(context).colorScheme.outline
                            : null,
                      ),
                ),
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (!task.isCompleted)
            IconButton(
              icon: Icon(
                Icons.play_circle_fill_rounded,
                color: accentColor,
                size: 32,
              ),
              tooltip: 'Start focus',
              onPressed: onStart,
            ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
