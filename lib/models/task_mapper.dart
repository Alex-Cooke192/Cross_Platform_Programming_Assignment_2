import '../core/data/local/app_database.dart';
import 'ui_models.dart';

extension TaskDomainToUi on Task {
  TaskUi toUi() {
    return TaskUi(
      id: id,
      inspectionId: inspectionId,
      title: title,
      isCompleted: isCompleted,
      result: result,
      notes: notes,
    );
  }
}

extension TaskDomainListToUi on List<Task> {
  List<TaskUi> toUiList() => map((t) => t.toUi()).toList();
}
