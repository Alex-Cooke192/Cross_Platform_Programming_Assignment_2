import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/task_repository.dart';
import '../../models/ui_models.dart';
import 'package:maintenance_system/ui/widgets/theme_toggle_button.dart';
import '../../models/task_mapper.dart';
import 'add_attachments_screen.dart';

class CurrentTaskDetailsUi extends StatelessWidget {
  final String title;
  final String? code;

  final bool isComplete;

  final TextEditingController resultController;
  final TextEditingController notesController;

  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final ValueChanged<bool>? onToggleComplete;

  final VoidCallback? onAddAttachment;

  const CurrentTaskDetailsUi({
    super.key,
    required this.title,
    this.code,
    required this.isComplete,
    required this.resultController,
    required this.notesController,
    this.onBack,
    this.onSave,
    this.onToggleComplete,
    this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedCode = (code ?? '').trim();

    return Scaffold(
      key: const Key('screen_task_details'),
      appBar: AppBar(
        title: const Text('Task (Current)'),
        leading: IconButton(
          key: const Key('btn_task_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          tooltip: 'Back',
        ),
        actions: [
          // new button in app bar
          IconButton(
            key: const Key('btn_open_add_attachment'),
            tooltip: 'Add attachment',
            icon: const Icon(Icons.attach_file),
            onPressed: onAddAttachment,
          ),
          const ThemeToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_task_save'),
        onPressed: onSave,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
      body: ListView(
        key: const Key('list_task_details'),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            key: const Key('card_task_header'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const Key('col_task_header'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const Key('text_task_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trimmedCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Code: $trimmedCode', key: const Key('text_task_code')),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    key: const Key('row_task_status'),
                    children: [
                      Expanded(
                        child: Text(
                          isComplete ? 'Status: Complete' : 'Status: Incomplete',
                          key: const Key('text_task_status'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Switch(
                        key: const Key('switch_task_complete'),
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

          // Attachment section
          _SectionTitle(
            key: const Key('section_attachment'),
            title: 'Attachment',
          ),
          const SizedBox(height: 8),
          Card(
            key: const Key('card_attachment'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const Key('col_attachment'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add or replace the attachment for this task.',
                    key: const Key('text_attachment_blurb'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('btn_add_attachment'),
                    onPressed: onAddAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add / replace attachment'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          const _SectionTitle(
            key: Key('section_result'),
            title: 'Result',
          ),
          const SizedBox(height: 8),
          Card(
            key: const Key('card_result'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const Key('field_task_result'),
                controller: resultController,
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

          const _SectionTitle(
            key: Key('section_notes'),
            title: 'Notes',
          ),
          const SizedBox(height: 8),
          Card(
            key: const Key('card_notes'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const Key('field_task_notes'),
                controller: notesController,
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

  const _SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      key: Key('text_section_${title.toLowerCase()}'),
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

class _OpenedTaskDetailsContainerState extends State<OpenedTaskDetailsContainer> {
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
      notes: newNotes,
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

  void _openAttachments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddAttachmentsContainer(taskId: widget.taskId),
      ),
    );
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

        if (snapshot.connectionState == ConnectionState.waiting && task == null) {
          return const Scaffold(
            key: Key('screen_task_loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (task == null) {
          return const Scaffold(
            key: Key('screen_task_not_found'),
            body: Center(child: Text('Task not found')),
          );
        }

        _initFromTask(task);

        return CurrentTaskDetailsUi(
          title: task.title,
          code: task.notes,
          isComplete: _isComplete,
          resultController: _resultController,
          notesController: _notesController,
          onBack: () => Navigator.of(context).pop(),
          onSave: () => _save(task),
          onToggleComplete: _toggleComplete,
          onAddAttachment: _openAttachments,
        );
      },
    );
  }
}
