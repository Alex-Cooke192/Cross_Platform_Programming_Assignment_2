import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_system/ui/widgets/theme_toggle_button.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../core/data/local/repositories/task_repository.dart';

import '../../models/ui_models.dart';
import '../../models/inspection_mapper.dart';
import '../../models/task_mapper.dart';
import 'unopened_inspection_details_screen.dart';

class UnopenedInspectionListScreen extends StatelessWidget {
  final List<InspectionUi> inspections;
  final int inProgressCount;

  /// Optional: preloaded tasks so we can show counts in the list.
  final Map<String, List<TaskUi>> tasksByInspectionId;

  /// Optional: let the container decide navigation / behavior.
  final void Function(InspectionUi inspection)? onTapInspection;

  const UnopenedInspectionListScreen({
    super.key,
    required this.inspections,
    required this.inProgressCount,
    this.tasksByInspectionId = const {},
    this.onTapInspection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspections ($inProgressCount in progress)'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: inspections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final inspection = inspections[index];
          final taskCount =
              (tasksByInspectionId[inspection.id] ?? const []).length;

          return Card(
            child: ListTile(
              title: Text(
                inspection.aircraftId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              trailing: Text('$taskCount tasks'),

              onTap: onTapInspection == null
                  ? null
                  : () => onTapInspection!(inspection),
            ),
          );
        },
      ),
    );
  }
}


/// Container: resolves streams + maps domain -> UI values, then hands plain values to UI.
class UnopenedInspectionListContainer extends StatelessWidget {
  const UnopenedInspectionListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final inspectionsRepo = context.read<InspectionRepository>();
    final tasksRepo = context.read<TaskRepository>();

    final unopened$ = inspectionsRepo.watchUnopened().map((rows) => rows.toUiList());
    final inProgress$ = inspectionsRepo.watchOpenCount();

    return StreamBuilder<List<InspectionUi>>(
      stream: unopened$,
      initialData: const [],
      builder: (context, inspectionsSnap) {
        final inspections = inspectionsSnap.data ?? const [];
        final inspectionIds = inspections.map((i) => i.id).toList();

        final tasksByInspectionId$ = tasksRepo
            .watchByInspectionIds(inspectionIds) 
            .map((tasks) {
              final map = <String, List<TaskUi>>{};
              for (final t in tasks.toUiList()) {
                (map[t.inspectionId] ??= []).add(t);
              }
              return map;
            });

        return StreamBuilder<int>(
          stream: inProgress$,
          initialData: 0,
          builder: (context, countSnap) {
            final inProgressCount = countSnap.data ?? 0;

            return StreamBuilder<Map<String, List<TaskUi>>>(
              stream: tasksByInspectionId$,
              initialData: const {},
              builder: (context, tasksSnap) {
                return UnopenedInspectionListScreen(
                  inspections: inspections,
                  inProgressCount: inProgressCount,
                  tasksByInspectionId: tasksSnap.data ?? const {},
                  onTapInspection: (inspection) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnopenedInspectionDetailsContainer(
                          inspectionId: inspection.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
