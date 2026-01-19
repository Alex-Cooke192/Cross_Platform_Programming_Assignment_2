import 'package:flutter/material.dart';
import '../../models/ui_models.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../core/data/local/repositories/task_repository.dart';
import '../../core/session/current_technician.dart';

import 'unopened_task_details_screen.dart';
import '../../models/inspection_mapper.dart';
import '../../models/task_mapper.dart';

class UnopenedInspectionDetailsScreen extends StatelessWidget {
  final InspectionUi inspection;
  final List<TaskUi> tasks;

  final VoidCallback onStartInspection;
  final void Function(TaskUi task) onOpenTask;

  const UnopenedInspectionDetailsScreen({
    super.key,
    required this.inspection,
    required this.tasks,
    required this.onStartInspection,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: onStartInspection,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start inspection'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InspectionHeaderCard(inspection: inspection),

            const SizedBox(height: 16),

            const Text(
              'Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('No tasks found for this inspection.'),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _TaskTile(
                          task: task,
                          onTap: () => onOpenTask(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- PRESENTATIONAL WIDGETS -------------------- */

class _InspectionHeaderCard extends StatelessWidget {
  final InspectionUi inspection;

  const _InspectionHeaderCard({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final openedText =
        inspection.openedAt == null ? 'Opened: —' : 'Opened: ${inspection.openedAt}';
    final completedText =
        inspection.completedAt == null ? 'Completed: —' : 'Completed: ${inspection.completedAt}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inspection.aircraftId,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(openedText),
            const SizedBox(height: 4),
            Text(completedText),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskUi task;
  final VoidCallback onTap;

  const _TaskTile({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (task.result != null && task.result!.trim().isNotEmpty)
        'Result: ${task.result}',
      if (task.notes != null && task.notes!.trim().isNotEmpty)
        'Notes added',
    ];

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: Icon(
        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      title: Text(task.title),
      subtitle:
          subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class UnopenedInspectionDetailsContainer extends StatelessWidget {
  final String inspectionId;

  const UnopenedInspectionDetailsContainer({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context) {
    final inspectionRepo = context.read<InspectionRepository>();
    final taskRepo = context.read<TaskRepository>();

    // Stream<InspectionUi?>
    final inspectionUi$ =
        inspectionRepo.watchById(inspectionId).map((row) => row?.toUi());

    // Stream<List<TaskUi>>
    final tasksUi$ =
        taskRepo.watchByInspectionId(inspectionId).map((rows) => rows.toUiList());

    return StreamBuilder<InspectionUi?>(
      stream: inspectionUi$,
      builder: (context, inspSnap) {
        final inspection = inspSnap.data;

        if (inspection == null) {
          // Simple placeholder while loading / if not found
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<List<TaskUi>>(
          stream: tasksUi$,
          initialData: const [],
          builder: (context, tasksSnap) {
            final tasks = tasksSnap.data ?? const <TaskUi>[];

            return UnopenedInspectionDetailsScreen(
              inspection: inspection,
              tasks: tasks,

              onStartInspection: () async {
                final techId =
                    context.read<CurrentTechnician>().technicianId;

                if (techId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No technician selected.')),
                  );
                  return;
                }

                await inspectionRepo.setOpened(
                  inspectionId
                );

                // Optional: go back after starting
                if (context.mounted) Navigator.of(context).pop();
              },

              onOpenTask: (task) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UnopenedTaskDetailsContainer(
                      taskId: task.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
