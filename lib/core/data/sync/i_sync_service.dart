import 'sync_service.dart';
import 'package:maintenance_system/models/sync_models.dart';

abstract class ISyncService {
  AuthStyle get authStyle;

  Future<SyncResult> syncNow({required String apiKey});
  Future<SyncResult> syncTechnicians({required String apiKey});

  Future<DateTime?> getLastSyncAt();
  Future<DateTime?> getLastTechSyncAt();

  void dispose();
}
