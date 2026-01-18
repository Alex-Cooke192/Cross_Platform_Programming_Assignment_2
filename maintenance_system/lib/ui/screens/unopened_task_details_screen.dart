import 'package:flutter/material.dart';
import 'package:maintenance_system/models/task_mapper.dart';
import 'package:provider/provider.dart';
import '../../models/ui_models.dart';

import '../../core/data/local/repositories/task_repository.dart';

class UnopenedTaskDetailsScreen extends StatelessWidget {
  final TaskUi task;

  const UnopenedTaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final resultText = task.result?.trim().isNotEmpty == true
        ? task.result!
        : '—';

    final titleText = task.title.trim().isNotEmpty == true
        ? task.title
        : '—';

    final notesText = task.notes?.trim().isNotEmpty == true
        ? task.notes!
        : 'No notes added.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _ReadOnlyRow(label: 'Title', value: titleText),
                    const SizedBox(height: 8),

                    _ReadOnlyRow(label: 'Result', value: resultText),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text('Status'),
                        const Spacer(),
                        Text(
                          task.isCompleted ? 'Completed' : 'Outstanding',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(notesText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- PRESENTATIONAL WIDGETS -------------------- */

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class UnopenedTaskDetailsContainer extends StatelessWidget {
  final String taskId;

  const UnopenedTaskDetailsContainer({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    final taskRepo = context.read<TaskRepository>();

    final Stream<TaskUi?> taskUi$ = 
      taskRepo.watchById(taskId).map((task) => task?.toUi()); 
    return StreamBuilder<TaskUi?>(
      stream: taskUi$,
      builder: (context, snapshot) {
        final taskUi = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && taskUi == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (taskUi == null) {
          return const Scaffold(
            body: Center(child: Text('Task not found')),
          );
        }
        return UnopenedTaskDetailsScreen(task: taskUi);
      },
    );
  }
}
