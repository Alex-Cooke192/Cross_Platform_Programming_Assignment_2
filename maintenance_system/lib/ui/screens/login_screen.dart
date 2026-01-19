import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_system/core/data/local/repositories/technician_repository.dart';
import '../screens/home_screen.dart';

import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController technicianIdController;
  final VoidCallback? onSignInPressed;
  final bool isLoading;

  const LoginScreen({
    super.key,
    required this.technicianIdController,
    required this.onSignInPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RampCheck Login'),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your technician ID to access inspections.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: technicianIdController,
                    decoration: const InputDecoration(
                      labelText: 'Technician ID',
                      hintText: 'e.g. tech.jane',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: isLoading ? null : onSignInPressed,
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginContainer extends StatefulWidget {
  const LoginContainer({super.key});

  @override
  State<LoginContainer> createState() => _LoginContainerState();
}

class _LoginContainerState extends State<LoginContainer> {
  final _technicianIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _technicianIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final technicianId = _technicianIdController.text.trim();
    if (technicianId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final techRepo = context.read<TechnicianRepository>();
      final technician =
          await techRepo.watchByIdUi(technicianId).first;

      if (!mounted) return;

      if (technician == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No technician found for ID: $technicianId')),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      technicianIdController: _technicianIdController,
      isLoading: _isLoading,
      onSignInPressed: _handleSignIn,
    );
  }
}
