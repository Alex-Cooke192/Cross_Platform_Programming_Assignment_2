import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maintenance_system/core/data/local/repositories/technician_repository.dart';

class CreateTechnicianScreen extends StatelessWidget {
  final TextEditingController nameController;

  final bool isSubmitting;
  final String? errorText;

  final VoidCallback onBackToLogin;
  final VoidCallback onCreatePressed;

  const CreateTechnicianScreen({
    super.key,
    required this.nameController,
    required this.isSubmitting,
    required this.errorText,
    required this.onBackToLogin,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Technician Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isSubmitting ? null : onBackToLogin,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Alex Cooke',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!isSubmitting) onCreatePressed();
                },
              ),

              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onCreatePressed,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: isSubmitting ? null : onBackToLogin,
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateTechnicianContainer extends StatefulWidget {
  const CreateTechnicianContainer({super.key});

  @override
  State<CreateTechnicianContainer> createState() =>
      _CreateTechnicianContainerState();
}

class _CreateTechnicianContainerState extends State<CreateTechnicianContainer> {
  final _nameController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatName(String raw) {
    // minimal formatting: trim + collapse repeated spaces
    final trimmed = raw.trim();
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed;
  }

  String? _validateName(String formatted) {
    if (formatted.isEmpty) return 'Please enter your name.';
    if (formatted.length < 2) return 'Name is too short.';
    if (formatted.length > 60) return 'Name is too long.';
    return null;
  }

  Future<void> _onCreatePressed() async {
    if (_isSubmitting) return;

    final repo = context.read<TechnicianRepository>();

    final formattedName = _formatName(_nameController.text);
    final validationError = _validateName(formattedName);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await repo.createTechnician(name: formattedName);

      if (!mounted) return;
      // Success: go back to login
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Could not create account. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  void _onBackToLogin() {
    if (_isSubmitting) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CreateTechnicianScreen(
      nameController: _nameController,
      isSubmitting: _isSubmitting,
      errorText: _errorText,
      onBackToLogin: _onBackToLogin,
      onCreatePressed: _onCreatePressed,
    );
  }
}
