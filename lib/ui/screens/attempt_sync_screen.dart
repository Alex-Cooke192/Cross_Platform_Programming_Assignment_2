import 'package:flutter/material.dart';

/// Call this to show the modal and get the entered API key back.
/// Returns `null` if the user cancels.
Future<String?> showAttemptSyncDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: true, // tap outside to close
    builder: (_) => const _AttemptSyncDialog(),
  );
}

class _AttemptSyncDialog extends StatefulWidget {
  const _AttemptSyncDialog();

  @override
  State<_AttemptSyncDialog> createState() => _AttemptSyncDialogState();
}

class _AttemptSyncDialogState extends State<_AttemptSyncDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // If you want to actually call sync here, do it.
    // For now, we just return the key to the caller.
    final key = _controller.text.trim();

    if (!mounted) return;
    Navigator.of(context).pop(key);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attempt sync'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420, // keeps it “mini” even on wide screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your server password / API key to sync.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                autofocus: true,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitting ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Password / API key',
                  hintText: 'e.g. api_warehouse_...',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show' : 'Hide',
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Please enter a key.';
                  if (v.length < 6) return 'That looks too short.';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(_submitting ? 'Syncing…' : 'Sync'),
        ),
      ],
    );
  }
}
