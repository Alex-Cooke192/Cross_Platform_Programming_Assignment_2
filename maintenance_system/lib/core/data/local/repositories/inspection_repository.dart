import 'dart:convert';

import 'package:maintenance_system/core/data/local/daos/inspection_dao.dart';
import 'package:maintenance_system/core/data/local/daos/task_dao.dart';

class InspectionRepository {
  final InspectionDao _inspectionDao; 
  final TaskDao _taskDao; 
  
  InspectionRepository({
    required InspectionDao inspectionDao, 
    required TaskDao taskDao, 
  }) : _inspectionDao = inspectionDao, 
       _taskDao = taskDao; 

  }