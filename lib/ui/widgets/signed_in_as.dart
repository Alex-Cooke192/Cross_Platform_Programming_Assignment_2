import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/session/current_technician.dart';

import '../../core/data/local/repositories/technician_repository.dart';

class SignedInAs extends StatelessWidget {
  final String userLabel;

  const SignedInAs({
    super.key,
    required this.userLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person, size: 18),
        const SizedBox(width: 6),

        // Make the *name* flexible so it can shrink/ellipsis in the tight AppBar area
        Flexible(
          child: Text(
            'Signed in as $userLabel',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}


class SignedInAsContainer extends StatelessWidget {
  const SignedInAsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final technicianId = context.watch<CurrentTechnician>().technicianId;

    if (technicianId == null) {
      return const SignedInAs(userLabel: 'Not signed in');
    }

    final techRepo = context.read<TechnicianRepository>();

    return StreamBuilder<TechniciansCacheData?>(
      stream: techRepo.watchById(technicianId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Unknown';
        return SignedInAs(userLabel: name);
      },
    );
  }
}
