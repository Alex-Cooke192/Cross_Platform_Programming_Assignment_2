// lib/ui/models/ui_models.dart
//
// UI models that mirror your Drift tables (Inspections, Tasks).
// Keep these "dumb": no DB imports, no Stream/Future logic.

enum InspectionUiStatus { unopened, inProgress, completed }

class InspectionUi {
  final String id;
  final String aircraftId;
  final DateTime? openedAt;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? technicianId; 

  const InspectionUi({
    required this.id,
    required this.aircraftId,
    required this.openedAt,
    required this.createdAt,
    required this.isCompleted,
    required this.completedAt,
    required this.technicianId,
  });

  /// Derived status for UI display. (Not stored in DB.)
  InspectionUiStatus get status {
    if (isCompleted || completedAt != null) return InspectionUiStatus.completed;
    if (openedAt != null) return InspectionUiStatus.inProgress;
    return InspectionUiStatus.unopened;
  }

  InspectionUi copyWith({
    String? id,
    String? aircraftId,
    DateTime? openedAt,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? technicianId,
  }) {
    return InspectionUi(
      id: id ?? this.id,
      aircraftId: aircraftId ?? this.aircraftId,
      openedAt: openedAt ?? this.openedAt,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      technicianId: technicianId ?? this.technicianId,
    );
  }
}

class TaskUi {
  final String id;
  final String inspectionId;
  final String title;
  final bool isCompleted;
  final String? result;
  final String? notes;

  const TaskUi({
    required this.id,
    required this.inspectionId,
    required this.title,
    required this.isCompleted,
    required this.result,
    required this.notes,
  });

  TaskUi copyWith({
    String? id,
    String? inspectionId,
    String? title,
    bool? isCompleted,
    String? result,
    String? notes,
  }) {
    return TaskUi(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      result: result ?? this.result,
      notes: notes ?? this.notes,
    );
  }
}

extension InspectionUiStatusLabel on InspectionUiStatus {
  String get label {
    switch (this) {
      case InspectionUiStatus.unopened:
        return 'Unopened';
      case InspectionUiStatus.inProgress:
        return 'In progress';
      case InspectionUiStatus.completed:
        return 'Completed';
    }
  }
}
