import '../core/data/local/app_database.dart';
import '../models/ui_models.dart';

extension TechnicianUiMapper on TechniciansCacheData {
  TechnicianUi toUi() => TechnicianUi(
        id: id,
        name: name,
      );
}
