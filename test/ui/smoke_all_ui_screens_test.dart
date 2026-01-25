import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/support/fake_local_db.dart';
import '../../integration_test/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalDbHarness harness;

  setUpAll(() async {
    harness = await FakeLocalDbHarness.create(inMemory: true);
    await harness.seedAssumedData();
  });

  Future<void> waitFor(
    Finder f,
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 16));
      if (f.evaluate().isNotEmpty) return;
    }
    fail('Timeout waiting for $f');
  }

  /// Bounded version of pumpAndSettle so the test can’t hang forever.
  Future<void> settle(WidgetTester tester,
      {int maxFrames = 120, Duration step = const Duration(milliseconds: 16)}) async {
    for (var i = 0; i < maxFrames; i++) {
      await tester.pump(step);
      if (!tester.binding.hasScheduledFrame &&
          tester.binding.transientCallbackCount == 0) {
        return;
      }
    }
    // Don’t fail the test just because something animates forever in a smoke test.
    // If you *want* it to fail, change this to `fail(...)`.
    debugPrint('⚠️ settle() hit maxFrames=$maxFrames (continuing)');
  }

  testWidgets('UI smoke test: core screens render', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(db: harness.db));
    await settle(tester);

    // Login screen
    expect(find.byKey(const Key('screen_login')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('field_technician_id')),
      'tech.jane',
    );
    await tester.tap(find.byKey(const Key('btn_sign_in')));
    await settle(tester);

    // Home screen
    await waitFor(find.byKey(const Key('screen_home')), tester);
    expect(find.text('RampCheck'), findsOneWidget);

    // Sync dialog
    await tester.tap(find.byKey(const Key('btn_sync')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Attempt sync'), findsOneWidget);
    expect(find.text('Password / API key'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);

    // Close dialog
    await tester.tap(find.byKey(const Key('btn_cancel_sync')));
    await settle(tester);

    // Navigate to unopened list
    await tester.tap(find.byKey(const Key('nav_unopened')));
    await settle(tester);
    expect(find.byKey(const Key('screen_unopened_list')), findsOneWidget);

    // Open unopened details
    await waitFor(find.byKey(const Key('tile_unopened_inspection_0')), tester);
    await tester.tap(find.byKey(const Key('tile_unopened_inspection_0')));
    await settle(tester);
    expect(find.byKey(const Key('screen_unopened_details')), findsOneWidget);

    // Start inspection -> returns to list
    await tester.tap(find.byKey(const Key('btn_start_inspection')));
    await settle(tester);
    expect(find.byKey(const Key('screen_unopened_list')), findsOneWidget);

    // Back to home
    await tester.pageBack();
    await settle(tester);
    expect(find.byKey(const Key('screen_home')), findsOneWidget);

    // Navigate to opened list
    await tester.tap(find.byKey(const Key('nav_opened')));
    await settle(tester);
    expect(find.byKey(const Key('screen_opened_list')), findsOneWidget);

    // Open opened details
    await waitFor(find.byKey(const Key('tile_opened_inspection_0')), tester);
    await tester.tap(find.byKey(const Key('tile_opened_inspection_0')));
    await settle(tester);
    expect(find.byKey(const Key('screen_opened_details')), findsOneWidget);

    // Open first task details
    final firstTaskTile = find.byKey(const Key('tile_opened_task_0'));
    if (firstTaskTile.evaluate().isNotEmpty) {
      await tester.tap(firstTaskTile);
      await settle(tester);
      expect(find.byKey(const Key('screen_task_details')), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      expect(find.byKey(const Key('screen_opened_details')), findsOneWidget);
    }

    // Back out to home
    await tester.pageBack();
    await settle(tester);
    expect(find.byKey(const Key('screen_opened_list')), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.byKey(const Key('screen_home')), findsOneWidget);

    // Completed screen
    await tester.tap(find.byKey(const Key('nav_completed')));
    await settle(tester);
    expect(find.byKey(const Key('screen_completed_list')), findsOneWidget);

    // Unmount UI while tester can still pump
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);

    // Dispose DB, but don’t allow it to hang forever
    await tester.runAsync(() async {
      await harness.dispose().timeout(const Duration(seconds: 5));
    });

    // Flush Drift’s 0-duration cleanup timer
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
