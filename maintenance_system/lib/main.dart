import 'package:flutter/material.dart';

import 'core/data/local/app_database.dart';
import 'app.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  // Debug-only seed
  assert(() {
    DevSeeder(db).seedIfEmpty();
    return true;
  }());

  runApp(App(database: db));
}
