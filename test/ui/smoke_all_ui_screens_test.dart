import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maintenance_system/ui/dialogs/show_attempt_sync_dialog.dart';
import 'package:maintenance_system/ui/screens/completed_inspection_list_screen.dart';
import 'package:maintenance_system/ui/screens/create_new_technician_screen.dart';
import 'package:maintenance_system/ui/screens/home_screen.dart';
import 'package:maintenance_system/ui/screens/login_screen.dart';
import 'package:maintenance_system/ui/screens/opened_inspection_list_screen.dart';
import 'package:maintenance_system/ui/screens/opened_task_details_screen.dart';
import 'package:maintenance_system/ui/screens/unopened_inspection_details_screen.dart';
import 'package:maintenance_system/ui/screens/unopened_inspection_list_screen.dart';
import 'package:maintenance_system/ui/screens/unopened_task_details_screen.dart';

import 'package:maintenance_system/models/ui_models.dart';

void main() {
  testWidgets('UI smoke test: core screens render', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('RampCheck Login'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: CreateTechnicianScreen(
        nameController: TextEditingController(),
        isSubmitting: false,
        errorText: null,
        onBackToLogin: () {},
        onCreatePressed: () {},
      ),
    ));
    expect(find.text('Create Technician Account'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('RampCheck'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: CompletedInspectionListScreen(
        inspections: const [],
        tasksByInspectionId: const {},
        onTapInspection: null,
      ),
    ));
    expect(find.text('Completed Inspections'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: OpenedInspectionListScreen(
        inspections: const [],
        maxInProgress: 3,
        onOpenInspection: (_) {},
        onStartNewInspection: () {},
      ),
    ));
    expect(find.text('Current Inspections'), findsOneWidget);

    final inspection = InspectionUi(
      id: 'i1',
      aircraftId: 'A1',
      technicianId: 't1',
      openedAt: DateTime(2026, 1, 1, 10, 0),
      completedAt: null,
      isCompleted: false,
      createdAt: DateTime(2025, 3, 10, 4, 0), 
    );

    final task = TaskUi(
      id: 'k1',
      inspectionId: 'i1',
      title: 'Check tire pressure',
      isCompleted: false,
      result: null,
      notes: null,
    );

    await tester.pumpWidget(MaterialApp(
      home: UnopenedInspectionDetailsScreen(
        inspection: inspection,
        tasks: [task],
        onStartInspection: () {},
        onOpenTask: (_) {},
      ),
    ));
    expect(find.text('Inspection Details'), findsOneWidget);
    expect(find.text('Start inspection'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: UnopenedInspectionListScreen(
        inspections: [inspection],
        inProgressCount: 0,
        tasksByInspectionId: {'i1': [task]},
        onTapInspection: (_) {},
      ),
    ));
    expect(find.textContaining('Inspections'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: UnopenedTaskDetailsScreen(task: task),
    ));
    expect(find.text('Task Details'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: CurrentTaskDetailsUi(
        title: 'Task title',
        code: 'ABC',
        isComplete: false,
        resultText: '',
        notesText: '',
        onBack: () {},
        onSave: () {},
        onToggleComplete: (_) {},
        onResultChanged: (_) {},
        onNotesChanged: (_) {},
      ),
    ));
    expect(find.text('Task (Current)'), findsOneWidget);
    expect(find.byKey(const ValueKey('resultField')), findsOneWidget);
    expect(find.byKey(const ValueKey('notesField')), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAttemptSyncDialog(context),
                child: const Text('Open dialog'),
              ),
            ),
          );
        },
      ),
    ));

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Attempt sync'), findsOneWidget);
    expect(find.text('Password / API key'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
  });
}
