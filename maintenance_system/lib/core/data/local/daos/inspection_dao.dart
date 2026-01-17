import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inspections.dart';

part 'inspection_dao.g.dart';

@DriftAccessor(tables: [Inspections])
class InspectionDao extends DatabaseAccessor<AppDatabase>
    with _$InspectionDaoMixin {
  InspectionDao(super.db); }