import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/session/current_technician.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final techId = context.watch<CurrentTechnician>().technicianId;

    if (techId == null) return const LoginContainer();
    return const HomeScreen();
  }
}
