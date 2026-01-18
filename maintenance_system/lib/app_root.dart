import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/data/local/repositories/technician_repository.dart';
import 'core/session/current_technician.dart';

import 'ui/screens/home_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_initActiveTechnician);
  }

  Future<void> _initActiveTechnician() async {
    if (!mounted) return; 

    final techRepo = context.read<TechnicianRepository>();
    final session = context.read<CurrentTechnician>();

    // If already set, do nothing
    if (session.technicianId != null) return;

    final first = await techRepo.getAnyTechnician();

    // DB table is empty
    if (first == null) {
      session.setTechnician(null); // or leave it null
      return;
    }
    session.setTechnician(first.id);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
