import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/task_repository.dart';
import '../../models/ui_models.dart';
import '../../models/task_mapper.dart';

class CurrentTaskDetailsUi extends StatelessWidget {
  final String title;
  final String? code;

  final bool isComplete;
  final String resultText;
  final String notesText;

  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final ValueChanged<bool>? onToggleComplete;
  final ValueChanged<String>? onResultChanged;
  final ValueChanged<String>? onNotesChanged;

  const CurrentTaskDetailsUi({
    super.key,
    required this.title,
    this.code,
    required this.isComplete,
    this.resultText = '',
    this.notesText = '',
    this.onBack,
    this.onSave,
    this.onToggleComplete,
    this.onResultChanged,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedCode = (code ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task (Current)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: onSave,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onSave,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trimmedCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Code: $trimmedCode'),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isComplete ? 'Status: Complete' : 'Status: Incomplete',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Switch(
                        value: isComplete,
                        onChanged: onToggleComplete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          const _SectionTitle(title: 'Result'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const ValueKey('resultField'),
                controller: TextEditingController(text: resultText),
                onChanged: onResultChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Enter the task result (e.g. OK / Fail / N/A / measurement)',
                ),
                textInputAction: TextInputAction.next,
                minLines: 1,
                maxLines: 3,
              ),
            ),
          ),

          const SizedBox(height: 14),

          const _SectionTitle(title: 'Notes'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const ValueKey('notesField'),
                controller: TextEditingController(text: notesText),
                onChanged: onNotesChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add notes (optional).',
                ),
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 10,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class OpenedTaskDetailsContainer extends StatefulWidget {
  final String taskId;

  const OpenedTaskDetailsContainer({
    super.key,
    required this.taskId,
  });

  @override
  State<OpenedTaskDetailsContainer> createState() =>
      _OpenedTaskDetailsContainerState();
}

class _OpenedTaskDetailsContainerState
    extends State<OpenedTaskDetailsContainer> {
  late final TextEditingController _resultController;
  late final TextEditingController _notesController;

  bool _isComplete = false;
  bool _initializedFromTask = false;

  @override
  void initState() {
    super.initState();
    _resultController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromTask(TaskUi task) {
    if (_initializedFromTask) return;

    final initialResult = (task.result ?? '').trim();
    _isComplete =
        task.isCompleted || (initialResult.isNotEmpty && initialResult != '—');

    _resultController.text = task.result ?? '';
    _notesController.text = task.notes ?? '';

    _initializedFromTask = true;
  }

  Future<void> _save(TaskUi task) async {
    final repo = context.read<TaskRepository>();

    final newResult =
        _resultController.text.trim().isEmpty ? null : _resultController.text.trim();
    final newNotes =
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    await repo.updateResultAndNotes(
      taskId: task.id, 
      result: newResult,
      notes: newNotes
    ); 

    if (task.isCompleted != _isComplete) {
      await repo.setCompleted(task.id, _isComplete);
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _toggleComplete(bool value) {
    setState(() {
      _isComplete = value;

      if (_isComplete) {
        final txt = _resultController.text.trim();
        if (txt.isEmpty || txt == '—') {
          _resultController.text = 'Completed';
        }
      } else {
        if (_resultController.text.trim() == 'Completed') {
          _resultController.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskRepo = context.read<TaskRepository>();

    final Stream<TaskUi?> taskUi$ = 
      taskRepo.watchById(widget.taskId).map((task) => task?.toUi()); 
    return StreamBuilder<TaskUi?>(
      stream: taskUi$,
      builder: (context, snapshot) {
        final task = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting &&
            task == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (task == null) {
          return const Scaffold(
            body: Center(child: Text('Task not found')),
          );
        }

        _initFromTask(task);

        return CurrentTaskDetailsUi(
          title: task.title,
          isComplete: _isComplete,
          resultText: _resultController.text,
          notesText: _notesController.text,
          onBack: () => Navigator.of(context).pop(),
          onSave: () => _save(task),
          onToggleComplete: _toggleComplete,
          onResultChanged: (v) => _resultController.text = v,
          onNotesChanged: (v) => _notesController.text = v,
        );
      },
    );
  }
}
