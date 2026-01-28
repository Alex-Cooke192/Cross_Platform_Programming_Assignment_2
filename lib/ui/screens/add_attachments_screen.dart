// add_attachments_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_system/ui/widgets/theme_toggle_button.dart';
import 'package:maintenance_system/core/data/local/repositories/attachments_repository.dart';


class AddAttachmentsScreen extends StatelessWidget {
  /// Pure UI state (container owns it)
  final String taskId;
  final String? selectedFileName;
  final bool hasSelection;
  final bool isUploading;

  /// UI-only callbacks (container decides what they do)
  final VoidCallback onPickFile;
  final VoidCallback onSubmitUpload;
  final VoidCallback? onRemoveSelection;

  const AddAttachmentsScreen({
    super.key,
    required this.taskId,
    required this.selectedFileName,
    required this.hasSelection,
    required this.isUploading,
    required this.onPickFile,
    required this.onSubmitUpload,
    this.onRemoveSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen_add_attachment'),
      appBar: AppBar(
        title: const Text('Add Attachment'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        key: const Key('list_add_attachment'),
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            key: const Key('card_attachment_header'),
            taskId: taskId,
          ),
          const SizedBox(height: 16),

          _PickerCard(
            key: const Key('card_attachment_picker'),
            selectedFileName: selectedFileName,
            hasSelection: hasSelection,
            onPickFile: onPickFile,
            onRemoveSelection: onRemoveSelection,
          ),

          const SizedBox(height: 16),

          _ActionsCard(
            key: const Key('card_attachment_actions'),
            canSubmit: hasSelection && !isUploading,
            isUploading: isUploading,
            onSubmit: onSubmitUpload,
          ),
        ],
      ),
    );
  }
}

/* -------------------- PRESENTATIONAL WIDGETS -------------------- */

class _HeaderCard extends StatelessWidget {
  final String taskId;

  const _HeaderCard({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('col_attachment_header'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Attachment',
              key: Key('text_attachment_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Task ID: $taskId',
              key: const Key('text_attachment_task_id'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'You can attach a single file to this task. Selecting a new file will replace the existing one.',
              key: const Key('text_attachment_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final String? selectedFileName;
  final bool hasSelection;
  final VoidCallback onPickFile;
  final VoidCallback? onRemoveSelection;

  const _PickerCard({
    super.key,
    required this.selectedFileName,
    required this.hasSelection,
    required this.onPickFile,
    required this.onRemoveSelection,
  });

  @override
  Widget build(BuildContext context) {
    final name = (selectedFileName == null || selectedFileName!.trim().isEmpty)
        ? '—'
        : selectedFileName!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('col_attachment_picker'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selected file',
              key: Key('text_selected_file_label'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              key: const Key('box_selected_file'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, key: Key('icon_selected_file')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      key: const Key('text_selected_file_name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSelection && onRemoveSelection != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      key: const Key('btn_remove_selection'),
                      onPressed: onRemoveSelection,
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove selected file',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              key: const Key('btn_pick_file'),
              onPressed: onPickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(hasSelection ? 'Choose different file' : 'Choose file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final bool canSubmit;
  final bool isUploading;
  final VoidCallback onSubmit;

  const _ActionsCard({
    super.key,
    required this.canSubmit,
    required this.isUploading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('col_attachment_actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('btn_upload_attachment'),
              onPressed: canSubmit ? onSubmit : null,
              icon: const Icon(Icons.cloud_upload),
              label: isUploading
                  ? const Text('Uploading…')
                  : const Text('Upload attachment'),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload will run when online. If offline, the attachment will remain pending until your next manual sync.',
              key: const Key('text_upload_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class AddAttachmentsContainer extends StatefulWidget {
  final String taskId;

  const AddAttachmentsContainer({
    super.key,
    required this.taskId,
  });

  @override
  State<AddAttachmentsContainer> createState() => _AddAttachmentsContainerState();
}

class _AddAttachmentsContainerState extends State<AddAttachmentsContainer> {
  File? _pickedFile;
  String? _pickedFileName;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false, // we want a path, not bytes in memory
      );

      if (!mounted) return;
      if (res == null || res.files.isEmpty) return;

      final f = res.files.single;
      final path = f.path;

      if (path == null || path.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read file path.',
              key: Key('snackbar_file_no_path'),
            ),
          ),
        );
        return;
      }

      setState(() {
        _pickedFile = File(path);
        _pickedFileName = f.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File picker failed.',
            key: Key('snackbar_file_picker_failed'),
          ),
        ),
      );
    }
  }

  void _removeSelection() {
    setState(() {
      _pickedFile = null;
      _pickedFileName = null;
    });
  }

  Future<void> _submit() async {
    if (_pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final repo = context.read<AttachmentsRepository>();

      final file = _pickedFile!;
      final stat = await file.stat();

      final attachmentId = DateTime.now().microsecondsSinceEpoch.toString();

      await repo.setForTask(
        attachmentId: attachmentId,
        taskId: widget.taskId,
        fileName: _pickedFileName ?? 'attachment',
        mimeType: _inferMimeType(_pickedFileName),
        sizeBytes: stat.size,
        localPath: file.path,
        sha256: null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment saved locally (pending upload).')),
      );

      Navigator.of(context).pop();
    } catch (e, st) {
      // IMPORTANT: print the real error
      // ignore: avoid_print
      print('Attachment save failed: $e');
      // ignore: avoid_print
      print(st);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attachment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddAttachmentsScreen(
      taskId: widget.taskId,
      selectedFileName: _pickedFileName,
      hasSelection: _pickedFile != null,
      isUploading: _isUploading,
      onPickFile: _isUploading ? () {} : _pickFile,
      onRemoveSelection: _isUploading ? null : _removeSelection,
      onSubmitUpload: _submit,
    );
  }

  static String _inferMimeType(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}
