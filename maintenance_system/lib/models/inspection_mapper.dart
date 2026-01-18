import '../core/data/local/app_database.dart'; 
import '../../models/ui_models.dart';

/// This maps the ui model InspectionUi to the domain inspection model
extension InspectionDomainToUi on Inspection {
  InspectionUi toUi() {
    return InspectionUi(
      id: id,
      aircraftId: aircraftId,
      createdAt: createdAt,
      isCompleted: isCompleted,
      openedAt: openedAt,
      completedAt: completedAt,
      technicianId: technicianId,
    );
  }
}

extension InspectionDomainListToUi on List<Inspection> {
  List<InspectionUi> toUiList() =>
      map((inspection) => inspection.toUi()).toList();
}

