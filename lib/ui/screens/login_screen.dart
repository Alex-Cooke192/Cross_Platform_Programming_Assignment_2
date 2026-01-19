import 'package:flutter/material.dart';
import 'package:maintenance_system/core/session/current_technician.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_system/core/data/local/repositories/technician_repository.dart';
import 'package:maintenance_system/ui/screens/create_new_technician_screen.dart';

import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Technician ID',
                      hintText: 'e.g. tech.jane',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const FilledButton(
                    onPressed: null,
                    child: Text('Sign in'),
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
    final techId = _technicianIdController.text.trim();
    if (techId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final techRepo = context.read<TechnicianRepository>();
      final tech = await techRepo.getByName(techId);

      if (!mounted) return;
      if (tech == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No technician found for name: $techId"))
        ); 
        return; 
      }

      context.read<CurrentTechnician>().setTechnician(tech.id); 
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                    controller: _technicianIdController,
                    decoration: const InputDecoration(
                      labelText: 'Technician ID',
                      hintText: 'e.g. tech.jane',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateTechnicianContainer(),
                              ),
                            );
                          },
                    child: const Text('Create technician account'),
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