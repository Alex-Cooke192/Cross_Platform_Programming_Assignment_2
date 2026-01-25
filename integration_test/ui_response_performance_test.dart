import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';
import 'support/fake_local_db.dart';

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

  testWidgets('UI response ...', (tester) async {
    await tester.pumpWidget(createTestApp(db: harness.db));
    await tester.pumpAndSettle();

    Future<void> enterTextSafe(Finder field, String text) async {
      await tester.ensureVisible(field);
      await tester.tap(field, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      final editable =
          find.descendant(of: field, matching: find.byType(EditableText));
      expect(editable, findsOneWidget);

      await tester.showKeyboard(editable);
      await tester.pump(const Duration(milliseconds: 50));

      tester.testTextInput.enterText(text);
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> tapSafe(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(f, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<int> measureToVisible({
      required String label,
      required Future<void> Function() action,
      required Finder nextFinder,
      Duration hardTimeout = const Duration(seconds: 3),
      int targetMs = 350,
    }) async {
      final sw = Stopwatch()..start();
      await action();

      while (sw.elapsed < hardTimeout) {
        await tester.pump(const Duration(milliseconds: 16));
        if (nextFinder.evaluate().isNotEmpty) {
          final ms = sw.elapsedMilliseconds;
          // ignore: avoid_print
          print('[PERF] $label: ${ms}ms');
          expect(ms, lessThan(targetMs), reason: '[$label] ${ms}ms >= ${targetMs}ms');
          return ms;
        }
      }

      fail('[$label] nextFinder not visible within $hardTimeout');
    }


    Future<void> waitForVisible(
      Finder f, {
      Duration timeout = const Duration(seconds: 5),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 16));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('Timeout waiting for $f');
    }

    Future<void> popRouteFast() async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pop();
      await tester.pump(); // 1 frame only (measures actual UI response)
    }


    expect(find.byKey(const Key('screen_login')), findsOneWidget);

    // Warm-up: do the transition once without measuring
    await tapSafe(find.byKey(const Key('btn_sign_in')));
    await tester.pumpAndSettle();

    // Restart app to measure from Login again (keeps warm caches like fonts/shaders)
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    await tester.pumpWidget(createTestApp(db: harness.db));
    await tester.pumpAndSettle();

    // Re-enter login text (field is recreated)
    await enterTextSafe(find.byKey(const Key('field_technician_id')), 'tech.jane');

    await measureToVisible(
      label: 'Login->Home',
      action: () async => tapSafe(find.byKey(const Key('btn_sign_in'))),
      nextFinder: find.byKey(const Key('screen_home')),
    );

    await measureToVisible(
      label: 'Home->UnopenedList',
      action: () async => tapSafe(find.byKey(const Key('nav_unopened'))),
      nextFinder: find.byKey(const Key('screen_unopened_list')),
    );

    await waitForVisible(find.byKey(const Key('tile_unopened_inspection_0')));

    await measureToVisible(
      label: 'UnopenedList->UnopenedDetails',
      action: () async => tapSafe(find.byKey(const Key('tile_unopened_inspection_0'))),
      nextFinder: find.byKey(const Key('screen_unopened_details')),
    );

    await measureToVisible(
      label: 'StartInspection->UnopenedList',
      action: () async => tapSafe(find.byKey(const Key('btn_start_inspection'))),
      nextFinder: find.byKey(const Key('screen_unopened_list')),
    );

    await measureToVisible(
      label: 'UnopenedList->Home',
      action: () async => popRouteFast(),
      nextFinder: find.byKey(const Key('screen_home')),
    );

    await tester.pumpAndSettle();

    await measureToVisible(
      label: 'Home->OpenedList',
      action: () async => tapSafe(find.byKey(const Key('nav_opened'))),
      nextFinder: find.byKey(const Key('screen_opened_list')),
    );

    await waitForVisible(find.byKey(const Key('tile_opened_inspection_0')));

    await measureToVisible(
      label: 'OpenedList->OpenedDetails',
      action: () async => tapSafe(find.byKey(const Key('tile_opened_inspection_0'))),
      nextFinder: find.byKey(const Key('screen_opened_details')),
    );

    var taskIndex = 0;
    while (true) {
      final tile = find.byKey(Key('tile_opened_task_$taskIndex'));
      if (tile.evaluate().isEmpty) break;

      await measureToVisible(
        label: 'OpenedDetails->TaskDetails($taskIndex)',
        action: () async => tapSafe(tile),
        nextFinder: find.byKey(const Key('screen_task_details')),
      );

      final completeSwitch = find.byKey(const Key('switch_task_complete'));
      if (completeSwitch.evaluate().isNotEmpty) {
        await tapSafe(completeSwitch);
      }

      final resultField = find.byKey(const Key('field_task_result'));
      if (resultField.evaluate().isNotEmpty) {
        await enterTextSafe(resultField, 'OK');
      }

      final notesField = find.byKey(const Key('field_task_notes'));
      if (notesField.evaluate().isNotEmpty) {
        await enterTextSafe(notesField, 'Completed in integration test');
      }

      await measureToVisible(
        label: 'TaskDetails->OpenedDetails(save $taskIndex)',
        action: () async => tapSafe(find.byKey(const Key('btn_task_save'))),
        nextFinder: find.byKey(const Key('screen_opened_details')),
      );

      taskIndex++;
    }

    final completeBtn = find.byKey(const Key('btn_mark_inspection_complete'));
    expect(completeBtn, findsOneWidget);

    await measureToVisible(
      label: 'CompleteInspection->OpenedList',
      action: () async => tapSafe(completeBtn),
      nextFinder: find.byKey(const Key('screen_opened_list')),
      hardTimeout: const Duration(seconds: 5),
    );
  });
}
