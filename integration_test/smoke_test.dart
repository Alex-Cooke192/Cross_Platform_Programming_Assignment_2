import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/fake_local_db.dart';
import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalDbHarness harness;

  setUpAll(() async {
    harness = await FakeLocalDbHarness.create(inMemory: true);
    await harness.seedAssumedData();
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  testWidgets('Smoke: app boots to login', (tester) async {
    await tester.pumpWidget(createTestApp(db: harness.db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_login')), findsOneWidget);
  });
}
