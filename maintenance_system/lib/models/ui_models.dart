class InspectionUi {
  final int? id; 

  InspectionUi ({
    required this.id
  }); 

  InspectionUi copyWith({
    int? id
  }) {
    return InspectionUi(
      id: id
    ); 
  }
}

class TaskUi {
  final int? id; 

  TaskUi ({
    required this.id
  }); 
  
  TaskUi copyWith ({
    int? id
  }) {
    return TaskUi(
      id: id
      ); 
  }
}