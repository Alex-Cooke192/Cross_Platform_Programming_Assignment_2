import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../models/ui_models.dart';
import '../../models/inspection_mapper.dart'; 
import 'unopened_inspection_list_screen.dart';
import 'opened_inspection_details_screen.dart'; 

class OpenedInspectionListScreen extends StatelessWidget {
  final List<InspectionUi> inspections;
  final int maxInProgress;

  final void Function(InspectionUi inspection) onOpenInspection;
  final VoidCallback onStartNewInspection;

  const OpenedInspectionListScreen({
    super.key,
    required this.inspections,
    required this.maxInProgress,
    required this.onOpenInspection,
    required this.onStartNewInspection,
  });

  @override
  Widget build(BuildContext context) {
    final count = inspections.length;
    final canStart = count < maxInProgress;
    final remaining = (maxInProgress - count).clamp(0, maxInProgress);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Inspections'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusHeader(
              count: count,
              remaining: remaining,
              canStart: canStart,
              maxInProgress: maxInProgress,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: count == 0
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: count,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inspection = inspections[index];
                        return _InspectionCard(
                          inspection: inspection,
                          onTap: () => onOpenInspection(inspection),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: canStart
          ? FloatingActionButton(
              onPressed: onStartNewInspection,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/* -------------------- PRESENTATIONAL WIDGETS -------------------- */

class _StatusHeader extends StatelessWidget {
  final int count;
  final int remaining;
  final bool canStart;
  final int maxInProgress;

  const _StatusHeader({
    required this.count,
    required this.remaining,
    required this.canStart,
    required this.maxInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 28,
              color: canStart
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count / $maxInProgress in progress',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canStart
                        ? '$remaining slot${remaining == 1 ? '' : 's'} remaining'
                        : 'Finish one to start another',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final InspectionUi inspection;
  final VoidCallback onTap;

  const _InspectionCard({
    required this.inspection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final started =
        inspection.openedAt == null ? '—' : _formatDateTime(inspection.openedAt!);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.assignment_outlined),
        title: Text(
          inspection.id.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Started: $started'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
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
            Icon(Icons.inbox_outlined,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No inspections in progress',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a new inspection to see it here.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const int kMaxInProgressInspections = 3;

class OpenedInspectionListContainer extends StatelessWidget {
  const OpenedInspectionListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InspectionRepository>();

    final inProgress$ =
        repo.watchOpen().map((rows) => rows.toUiList());

    return StreamBuilder<List<InspectionUi>>(
      stream: inProgress$,
      initialData: const [],
      builder: (context, snap) {
        final inspections = snap.data ?? const [];

        return OpenedInspectionListScreen(
          inspections: inspections,
          maxInProgress: kMaxInProgressInspections,
          onOpenInspection: (inspection) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OpenedInspectionDetailsContainer(
                  inspectionId: inspection.id,
                ),
              ),
            );
          },
          onStartNewInspection: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UnopenedInspectionListContainer(),
              ),
            );
          },
        );
      },
    );
  }
}
