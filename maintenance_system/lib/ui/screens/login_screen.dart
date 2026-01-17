import 'package:flutter/material.dart';

import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailOrIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Replace with auth service call.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      // Add implementation to navigate to home/inspections screen.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login stub: success (replace with real auth)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
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
        actions: const [
          ThemeToggleButton(), 
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
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
                        'Use your technician account to access inspections.\nOffline use can be enabled after the first successful sign-in.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailOrIdController,
                        decoration: const InputDecoration(
                          labelText: 'Email or Technician ID',
                          hintText: 'e.g. tech123 or name@company.com',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Enter your email or Technician ID';
                          if (v.length < 3) return 'Too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _isLoading ? null : _onLoginPressed(),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) return 'Enter your password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: _isLoading ? null : _onLoginPressed,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign in'),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Hook up “Forgot password” flow later
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Forgot password stub')),
                                );
                              },
                        child: const Text('Forgot password?'),
                      ),

                      const SizedBox(height: 12),

                      // This is a placeholder for later when wiring connectivity/auth state.
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tip: After your first successful sign-in, you can keep working offline and sync later.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
