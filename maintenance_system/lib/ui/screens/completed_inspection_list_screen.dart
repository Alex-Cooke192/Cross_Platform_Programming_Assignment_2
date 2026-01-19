import 'package:flutter/material.dart';
import 'package:maintenance_system/models/task_mapper.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../core/data/local/repositories/task_repository.dart';
import '../../models/ui_models.dart';
import '../../models/inspection_mapper.dart';


/// Screen requires:
/// - List of completed inspections (already sorted)
/// - a map of tasks keyed by inspectionId (already fetched/sorted)
/// - callbacks for navigation if needed
class CompletedInspectionListScreen extends StatelessWidget {
  final List<InspectionUi> inspections;

  /// Preloaded tasks for each inspection (keyed by inspectionId).
  final Map<String, List<TaskUi>> tasksByInspectionId;

  /// Optional: if you want to handle tapping a card (e.g., open a details screen)
  final void Function(InspectionUi inspection)? onTapInspection;

  const CompletedInspectionListScreen({
    super.key,
    required this.inspections,
    this.tasksByInspectionId = const {},
    this.onTapInspection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Completed Inspections'),
      ),
      body: inspections.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: inspections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final insp = inspections[index];
                final tasks = tasksByInspectionId[insp.id] ?? const <TaskUi>[];

                return _CompletedInspectionCard(
                  inspection: insp,
                  tasks: tasks,
                  onTap: onTapInspection == null ? null : () => onTapInspection!(insp),
                );
              },
            ),
    );
  }
}

class _CompletedInspectionCard extends StatelessWidget {
  final InspectionUi inspection;
  final List<TaskUi> tasks;
  final VoidCallback? onTap;

  const _CompletedInspectionCard({
    required this.inspection,
    required this.tasks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final aircraft = (inspection.aircraftId).trim().isNotEmpty
        ? inspection.aircraftId.trim()
        : 'Aircraft —';

    final openedAt = inspection.openedAt;
    final completedAt = inspection.completedAt;

    final openedText = openedAt == null ? 'Opened: —' : 'Opened: ${_fmtDateTime(openedAt)}';
    final completedText =
        completedAt == null ? 'Completed: —' : 'Completed: ${_fmtDateTime(completedAt)}';

    final taskCount = tasks.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (aircraft + status pill)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      aircraft,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _StatusPill(
                    label: 'COMPLETED',
                    icon: Icons.check_circle,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // "Timeline" look: Opened -> Completed
              _TimelineRow(
                leftText: openedText,
                rightText: completedText,
              ),

              const SizedBox(height: 10),

              // Summary strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_add_check, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$taskCount task${taskCount == 1 ? '' : 's'} completed',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      'Read-only',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Expandable tasks (pure UI; tasks provided by parent)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 6, bottom: 8),
                  title: Text(
                    'Tasks on this jet',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    taskCount == 0 ? 'No tasks found' : 'Tap to review',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                    ),
                  ),
                  trailing: const Icon(Icons.expand_more),
                  children: [
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'No tasks were recorded for this inspection.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      )
                    else
                      _TaskReviewList(tasks: tasks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskReviewList extends StatelessWidget {
  final List<TaskUi> tasks;

  const _TaskReviewList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: tasks.map((t) {
        final code = (t.notes ?? '').trim();
        final result = (t.result ?? '—').trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                ),
                child: const Icon(Icons.task_alt, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          code.isEmpty ? 'Code: —' : 'Code: $code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Result: $result',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String leftText;
  final String rightText;

  const _TimelineRow({
    required this.leftText,
    required this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faded = theme.textTheme.bodySmall?.color?.withOpacity(0.75);

    return Row(
      children: [
        _Dot(color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            leftText,
            style: theme.textTheme.bodySmall?.copyWith(color: faded),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          width: 26,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: theme.dividerColor.withOpacity(0.9),
          ),
        ),
        _Dot(color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rightText,
            style: theme.textTheme.bodySmall?.copyWith(color: faded),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withOpacity(0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'No completed inspections yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed inspections will appear here for review.\nThis screen is read-only.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDateTime(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = months[dt.month - 1];
  final yyyy = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$dd $mm $yyyy • $hh:$min';
}

class CompletedInspectionListContainer extends StatelessWidget {
  const CompletedInspectionListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final inspectionRepo = context.read<InspectionRepository>();
    final taskRepo = context.read<TaskRepository>(); 

    // Domain -> UI list, then sort
    final completedUi$ = inspectionRepo
        .watchCompleted()
        .map((rows) => rows.toUiList())
        .map((uiList) {
          final copy = [...uiList];
          copy.sort((a, b) {
            final aTime = a.completedAt ?? a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.completedAt ?? b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return copy;
        });

    return StreamBuilder<List<InspectionUi>>(
      stream: completedUi$,
      initialData: const [],
      builder: (context, inspSnap) {
        final inspections = inspSnap.data ?? const <InspectionUi>[];

        // Build a single stream that emits a Map<inspectionId, tasks>
        final tasksMap$ = _tasksMapStream(taskRepo, inspections);

        return StreamBuilder<Map<String, List<TaskUi>>>(
          stream: tasksMap$,
          initialData: const {},
          builder: (context, tasksSnap) {
            final tasksByInspectionId = tasksSnap.data ?? const {};

            return CompletedInspectionListScreen(
              inspections: inspections,
              tasksByInspectionId: tasksByInspectionId,
              onTapInspection: null,
            );
          },
        );
      },
    );
  }

  Stream<Map<String, List<TaskUi>>> _tasksMapStream(
    TaskRepository repo,
    List<InspectionUi> inspections,
  ) {
    if (inspections.isEmpty) return Stream.value(const {});

    final ids = inspections.map((i) => i.id).toList();

    final taskStreams = ids.map((id) {
      return repo.watchByInspectionId(id)
          // sort for stable UI
          .map((rows) => rows.toUiList());
    }).toList();

    // CombineLatest emits whenever ANY inspection’s tasks stream emits
    return CombineLatestStream.list<List<TaskUi>>(taskStreams).map((lists) {
      final map = <String, List<TaskUi>>{};
      for (var i = 0; i < ids.length; i++) {
        map[ids[i]] = lists[i];
      }
      return map;
    });
  }
}
