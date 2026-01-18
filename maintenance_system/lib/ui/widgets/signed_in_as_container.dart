import 'package:flutter/material.dart';
import 'package:maintenance_system/core/data/local/app_database.dart';

import '../../core/data/local/repositories/technician_repository.dart';
import 'signed_in_as.dart';

class SignedInAsContainer extends StatelessWidget {
  final String technicianId;
  final TechnicianRepository technicianRepository;

  const SignedInAsContainer({
    super.key,
    required this.technicianId,
    required this.technicianRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TechniciansCacheData?>(
      stream: technicianRepository.watchById(technicianId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? 'Unknown';

        return SignedInAs(userLabel: name);
      },
    );
  }
}
