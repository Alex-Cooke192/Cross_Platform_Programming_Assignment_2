import 'package:flutter/widgets.dart';
import 'support/fake_local_db.dart';
import 'test_app.dart';

Future<Widget> buildSeededTestApp() async {
  final harness = await FakeLocalDbHarness.create(inMemory: true);
  await harness.seedAssumedData();

  return createTestApp(db: harness.db);
}
