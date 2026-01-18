import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';

import '../../models/ui_models.dart';
import '../../models/inspection_mapper.dart';

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
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: inspections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final repo = context.read<InspectionRepository>();

    return StreamBuilder<List<InspectionUi>>(
      stream: repo.watchUnopenedInspections(),
      initialData: const [],
      builder: (context, snap) {
        final inspections = snap.data ?? const [];
        final inProgressCount =
            inspections.where((i) => i.isInProgress).length; // adjust to your model

        return UnopenedInspectionListScreen(
          inspections: inspections,
          inProgressCount: inProgressCount,
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
  }
}
