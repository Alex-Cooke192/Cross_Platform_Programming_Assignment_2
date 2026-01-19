import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/current_technician.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    context.read<CurrentTechnician>().setTechnician(null);
    // AppRoot will handle the screen switch
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Sign out',
      onPressed: () => _confirmAndLogout(context),
      child: const Icon(Icons.logout),
    );
  }
}
