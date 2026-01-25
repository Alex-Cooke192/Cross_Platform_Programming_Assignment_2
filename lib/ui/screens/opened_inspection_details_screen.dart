import 'package:flutter/material.dart';
import 'package:maintenance_system/ui/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../core/data/local/repositories/task_repository.dart';
import '../../models/ui_models.dart';
import '../../core/session/current_technician.dart';
import '../../models/inspection_mapper.dart';
import '../../models/task_mapper.dart';
import 'opened_task_details_screen.dart';

class CurrentInspectionDetailsScreen extends StatelessWidget {
  final InspectionUi inspection;
  final List<TaskUi> tasks;

  /// UI-only callbacks (container decides what they do)
  final void Function(TaskUi task) onOpenTask;
  final VoidCallback onMarkInspectionComplete;

  /// Pure UI flags / numbers (container computes these)
  final String statusLabel; // e.g. "IN PROGRESS"
  final int completedCount;
  final int totalCount;
  final double progress; // 0.0 -> 1.0
  final bool canComplete;

  const CurrentInspectionDetailsScreen({
    super.key,
    required this.inspection,
    required this.tasks,
    required this.onOpenTask,
    required this.onMarkInspectionComplete,
    required this.statusLabel,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.canComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen_opened_details'),
      appBar: AppBar(
        title: const Text('Current Inspection'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _StatusChip(
                key: const Key('chip_inspection_status'),
                label: statusLabel,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: ListView(
        key: const Key('list_opened_details'),
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            key: const Key('card_inspection_header'),
            inspection: inspection,
            completedCount: completedCount,
            totalCount: totalCount,
            progress: progress,
          ),
          const SizedBox(height: 16),

          _SectionTitle(
            key: const Key('section_tasks_title'),
            title: 'Tasks',
            trailing: Text(
              totalCount == 0 ? '—' : '$completedCount / $totalCount',
              key: const Key('text_task_progress'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            const _EmptyStateCard(
              key: Key('empty_tasks'),
              title: 'No tasks found',
              message: 'This inspection has no tasks to complete.',
            )
          else
            ...tasks.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final t = entry.value;
                return Padding(
                  key: Key('pad_opened_task_$index'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskTile(
                    key: Key('tile_opened_task_$index'),
                    task: t,
                    onTap: () => onOpenTask(t),
                  ),
                );
              },
            ),

          const SizedBox(height: 20),

          _ActionsCard(
            key: const Key('card_actions'),
            canComplete: canComplete,
            onMarkComplete: onMarkInspectionComplete,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/* -------------------- PRESENTATIONAL WIDGETS -------------------- */

class _HeaderCard extends StatelessWidget {
  final InspectionUi inspection;
  final int completedCount;
  final int totalCount;
  final double progress;

  const _HeaderCard({
    super.key,
    required this.inspection,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      _safe(inspection.technicianId),
      _formatStarted(inspection.openedAt),
    ].where((s) => s != '—').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inspection.id,
              key: const Key('text_inspection_id'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitleParts.join(' • '),
                key: const Key('text_inspection_subtitle'),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalCount == 0
                      ? 'Progress —'
                      : 'Progress $completedCount / $totalCount',
                  key: const Key('text_progress_label'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  key: const Key('text_progress_percent'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const Key('bar_progress'),
                value: progress,
              ),
            ),
            const SizedBox(height: 14),
            _InfoGrid(
              key: const Key('grid_info'),
              inspection: inspection,
            ),
          ],
        ),
      ),
    );
  }

  static String _safe(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  static String _formatStarted(DateTime? dt) {
    if (dt == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return 'Started: ${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _InfoGrid extends StatelessWidget {
  final InspectionUi inspection;

  const _InfoGrid({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow(label: 'Technician', value: _safe(inspection.technicianId)),
      _InfoRow(label: 'Opened at', value: _formatDateTime(inspection.openedAt)),
      _InfoRow(label: 'Completed at', value: _formatDateTime(inspection.completedAt)),
    ].where((r) => r.value != '—').toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('col_info_rows'),
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        ...rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final r = entry.value;
          return Padding(
            key: Key('row_info_$idx'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    r.label,
                    key: Key('label_info_$idx'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.value,
                    key: Key('value_info_$idx'),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static String _safe(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow({required this.label, required this.value});
}

class _TaskTile extends StatelessWidget {
  final TaskUi task;
  final VoidCallback onTap;

  const _TaskTile({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final result = (task.result ?? '—').trim();
    final hasNotes = (task.notes ?? '').trim().isNotEmpty;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          key: Key('icon_task_complete_${task.id}'),
        ),
        title: Text(task.title, key: Key('text_task_title_${task.id}')),
        subtitle: Column(
          key: Key('col_task_sub_${task.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result: $result', key: Key('text_task_result_${task.id}')),
            if (hasNotes) Text('Notes added', key: Key('text_task_notes_${task.id}')),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final bool canComplete;
  final VoidCallback onMarkComplete;

  const _ActionsCard({
    super.key,
    required this.canComplete,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('col_actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              key: const Key('btn_mark_inspection_complete'),
              onPressed: canComplete ? onMarkComplete : null,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark inspection complete'),
            ),
            const SizedBox(height: 10),
            if (!canComplete) ...[
              const SizedBox(height: 10),
              Text(
                'Complete all tasks to mark this inspection as complete.',
                key: const Key('text_cannot_complete_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        label,
        key: const Key('text_status_label'),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('row_section_title'),
      children: [
        Text(
          title,
          key: const Key('text_section_title'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('col_empty_tasks'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, key: const Key('text_empty_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message, key: const Key('text_empty_message')),
          ],
        ),
      ),
    );
  }
}

class OpenedInspectionDetailsContainer extends StatelessWidget {
  final String inspectionId;

  const OpenedInspectionDetailsContainer({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context) {
    final inspectionRepo = context.read<InspectionRepository>();
    final taskRepo = context.read<TaskRepository>();

    final inspectionUi$ =
        inspectionRepo.watchById(inspectionId).map((row) => row?.toUi());

    final tasksUi$ =
        taskRepo.watchByInspectionId(inspectionId).map((rows) => rows.toUiList());

    return StreamBuilder<InspectionUi?>(
      stream: inspectionUi$,
      builder: (context, inspSnap) {
        final inspection = inspSnap.data;

        if (inspSnap.connectionState == ConnectionState.waiting &&
            inspection == null) {
          return const Scaffold(
            key: Key('screen_opened_details_loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (inspection == null) {
          return const Scaffold(
            key: Key('screen_opened_details_not_found'),
            body: Center(child: Text('Inspection not found')),
          );
        }

        return StreamBuilder<List<TaskUi>>(
          stream: tasksUi$,
          initialData: const [],
          builder: (context, tasksSnap) {
            final tasks = tasksSnap.data ?? const <TaskUi>[];

            final completedCount = tasks.where((t) => t.isCompleted).length;
            final totalCount = tasks.length;
            final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
            final canComplete = totalCount > 0 && completedCount == totalCount;

            return CurrentInspectionDetailsScreen(
              inspection: inspection,
              tasks: tasks,
              statusLabel: 'IN PROGRESS',
              completedCount: completedCount,
              totalCount: totalCount,
              progress: progress,
              canComplete: canComplete,

              onOpenTask: (task) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OpenedTaskDetailsContainer(taskId: task.id),
                  ),
                );
              },

              onMarkInspectionComplete: () async {
                final techId = context.read<CurrentTechnician>().technicianId;

                if (techId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No technician selected.',
                        key: Key('snackbar_no_technician'),
                      ),
                    ),
                  );
                  return;
                }

                await inspectionRepo.markCompleted(inspectionId);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}
