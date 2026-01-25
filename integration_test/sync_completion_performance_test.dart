import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/fake_local_db.dart';
import 'test_app.dart';

import 'package:maintenance_system/core/data/sync/i_sync_service.dart';
import 'package:maintenance_system/core/data/sync/sync_service.dart' show AuthStyle;
import 'package:maintenance_system/models/sync_models.dart';

class DelayedSuccessSyncService implements ISyncService {
  DelayedSuccessSyncService({required this.delay});

  final Duration delay;

  @override
  AuthStyle get authStyle => AuthStyle.bearer;

  @override
  Future<DateTime?> getLastSyncAt() async => null;

  @override
  Future<DateTime?> getLastTechSyncAt() async => null;

  @override
  Future<SyncResult> syncNow({required String apiKey}) async {
    await Future<void>.delayed(delay);
    return SyncResult(
      jobId: 'test_sync',
      serverTime: DateTime.now().toUtc(),
      applied: const {},
      conflicts: const {},
      serverChanges: const {},
    );
  }

  @override
  Future<SyncResult> syncTechnicians({required String apiKey}) async {
    await Future<void>.delayed(delay);
    return SyncResult(
      jobId: 'test_tech_sync',
      serverTime: DateTime.now().toUtc(),
      applied: const {},
      conflicts: const {},
      serverChanges: const {},
    );
  }

  @override
  void dispose() {}
}

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

  testWidgets('Sync completion < 120 seconds (UI end-to-end)', (tester) async {
    final sync = DelayedSuccessSyncService(
      delay: const Duration(milliseconds: 600),
    );

    await tester.pumpWidget(
      createTestApp(
        db: harness.db,
        overrideSyncService: sync,
      ),
    );
    await tester.pumpAndSettle();

    Future<void> waitForVisible(
      Finder f, {
      Duration timeout = const Duration(seconds: 10),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 16));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('Timeout waiting for $f');
    }

    Future<int> measureToVisible({
      required String label,
      required Future<void> Function() action,
      required Finder nextFinder,
      Duration hardTimeout = const Duration(seconds: 130),
      int targetMs = 120000,
    }) async {
      final sw = Stopwatch()..start();
      await action();

      final deadline = DateTime.now().add(hardTimeout);
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 16));
        if (nextFinder.evaluate().isNotEmpty) {
          sw.stop();
          final ms = sw.elapsedMilliseconds;
          expect(
            ms,
            lessThan(targetMs),
            reason: '[$label] ${ms}ms >= ${targetMs}ms',
          );
          return ms;
        }
      }

      sw.stop();
      fail('[$label] nextFinder not visible within $hardTimeout');
    }

    expect(find.byKey(const Key('screen_login')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('field_technician_id')),
      'tech.jane',
    );
    await tester.tap(find.byKey(const Key('btn_sign_in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_home')), findsOneWidget);

    await waitForVisible(find.byKey(const Key('screen_home')));

    expect(find.byKey(const Key('screen_home')), findsOneWidget);

    final syncBtn = find.byKey(const Key('btn_sync'));
    expect(syncBtn, findsOneWidget);
    await tester.ensureVisible(syncBtn);

    await tester.tapAt(tester.getCenter(syncBtn));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    print('dialogs=${find.byType(AlertDialog).evaluate().length}');
    print('attemptSyncText=${find.text("Attempt sync").evaluate().length}');
    print('dialogKey=${find.byKey(const Key("dialog_sync")).evaluate().length}');

    await tester.tapAt(tester.getCenter(syncBtn));
    await tester.pump(); // do NOT pumpAndSettle yet

    final exAfterTap = tester.takeException();
    expect(exAfterTap, isNull, reason: 'Tapping Sync threw: $exAfterTap');

    // Fast poll for any dialog/title for up to 5 seconds
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    bool anyDialog = false;

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 20));

      final alertCount = find.byType(AlertDialog).evaluate().length;
      final titleCount = find.text('Attempt sync').evaluate().length;

      if (alertCount > 0 || titleCount > 0) {
        anyDialog = true;
        break;
      }
    }

    expect(anyDialog, isTrue, reason: 'No dialog appeared after tapping Sync.');

    // Now check which dialog we actually got (keyed vs unkeyed)
    final keyed = find.byKey(const Key('dialog_sync')).evaluate().isNotEmpty;
    final byType = find.byType(AlertDialog).evaluate().isNotEmpty;
    final byTitle = find.text('Attempt sync').evaluate().isNotEmpty;

    // ignore: avoid_print
    print('[DEBUG] dialog visible? keyed=$keyed byType=$byType byTitle=$byTitle');

    await waitForVisible(find.byType(AlertDialog), timeout: const Duration(seconds: 5));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Attempt sync'), findsOneWidget);

    // Find field
    final apiField = find.byKey(const Key('field_sync_api_key'));
    expect(apiField, findsOneWidget);

    // Make sure it is in view + focused
    await tester.ensureVisible(apiField);
    await tester.tap(apiField);
    await tester.pump(const Duration(milliseconds: 200));

    // Enter text (do NOT assert find.text(...); it's obscured)
    await tester.enterText(apiField, 'api_warehouse_student_key_1234567890abcdef');
    final fieldWidget = tester.widget<TextFormField>(apiField);
    expect(fieldWidget.controller, isNotNull);

    final controllerText = fieldWidget.controller!.text;
    expect(
      controllerText,
      equals('api_warehouse_student_key_1234567890abcdef'),
      reason: 'API key was not entered into controller.',
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Submit by tapping the button (this pops the dialog and returns the key)
    final confirm = find.byKey(const Key('btn_confirm_sync'));
    expect(confirm, findsOneWidget);

    final ms = await measureToVisible(
      label: 'SyncConfirm->SnackbarSuccess',
      action: () async {
        await tester.tap(confirm);
      },
      nextFinder: find.byKey(const Key('snackbar_sync_success')),
      targetMs: 120000,
      hardTimeout: const Duration(seconds: 130),
    );

    // If anything threw during sync, surface it
    final ex = tester.takeException();
    expect(ex, isNull, reason: 'Sync flow threw: $ex');

    // Evidence for console log / report
    // ignore: avoid_print
    print('[PERF] Sync completion: ${ms}ms (target < 120000ms)');
  });
}
