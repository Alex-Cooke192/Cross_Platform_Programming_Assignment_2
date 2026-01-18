import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';

import '../../models/ui_models.dart';
import '../../models/inspection_mapper.dart';

class UnopenedInspectionListScreen extends StatelessWidget {
  final List<InspectionUi> inspections;
  final int inProgressCount;

  /// Optional: if you want tasks shown/passed, provide them preloaded.
  /// If you don't need tasks on the list screen, you can remove this entirely.
  final Map<String, List<TaskUi>> tasksByInspectionId;

  const UnopenedInspectionListScreen({
    super.key,
    required this.inspections,
    required this.inProgressCount,
    this.tasksByInspectionId = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspections')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: inspections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final inspection = inspections[index];

          return Card(
            child: ListTile(
              title: Text(
                inspection.aircraftId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(inspection),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnopenedInspectionListScreen(
                    ),
                  ),
                );
              },
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
    final inspectionRepo = context.read<InspectionRepository>();

    // Domain stream -> UI stream
    final unopenedUi$ =
        inspectionRepo.watchUnopened().map((rows) => rows.toUiList());

    // Domain stream -> count stream
    final inProgressCount$ =
        inspectionRepo.watchOpen().map((rows) => rows.length);

    return StreamBuilder<List<InspectionUi>>(
      stream: unopenedUi$,
      initialData: const [],
      builder: (context, inspectionsSnap) {
        final inspections = inspectionsSnap.data ?? const [];

        return StreamBuilder<int>(
          stream: inProgressCount$,
          initialData: 0,
          builder: (context, countSnap) {
            final inProgressCount = countSnap.data ?? 0;

            return UnopenedInspectionListScreen(
              inspections: inspections,
              inProgressCount: inProgressCount,
            );
          },
        );
      },
    );
  }
}