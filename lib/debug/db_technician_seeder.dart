import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../core/data/local/app_database.dart';

class TechnicianDevSeeder {
  final AppDatabase db;
  TechnicianDevSeeder(this.db);

  static const _uuid = Uuid();

  Future<void> reseed() async {
    await db.transaction(() async {

      final now = DateTime.now(); 
      // Wipe tables (order matters if you add FKs later)
      await db.delete(db.tasks).go();
      await db.delete(db.inspections).go();
      await db.delete(db.techniciansCache).go();

      // 1) Insert 5 technicians
      final techNames = <String>[
        'tech.jane',
        'tech.ali',
        'tech.sam',
        'tech.rory',
        'tech.mina',
      ];

      final techIds = <String>[];
      for (final name in techNames) {
        final id = _uuid.v4();
        techIds.add(id);

        await db.into(db.techniciansCache).insert(
          TechniciansCacheCompanion.insert(
              id: id,
              name: name,
              syncStatus: const drift.Value('pending'),
              updatedAt: drift.Value(now),
            ),
          );
        }
      }
    );
  }
}