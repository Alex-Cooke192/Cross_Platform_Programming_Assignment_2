import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/session/current_technician.dart';
import 'core/data/sync/i_sync_service.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = context.read<ISyncService>();

      // Always pull technicians on startup
      const apiKey = 'api_warehouse_student_key_1234567890abcdef';
      try {
        await sync.syncTechnicians(apiKey: apiKey);
      } catch (_) {
        // offline/unauthorized is fine on startup
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    final techId = context.watch<CurrentTechnician>().technicianId;
    if (techId == null) return const LoginContainer();
    return const HomeScreen();
  }
}

