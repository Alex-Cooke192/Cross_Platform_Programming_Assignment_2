import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';
import '../../core/data/local/repositories/task_repository.dart';
import '../widgets/signed_in_as.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inspectionRepo = context.read<InspectionRepository>();

    final UnopenedCount$ = inspectionRepo.watchUnopened(); 
    final OpenCount$ = inspectionRepo.watchOpen();
    final CompletedCount$ = inspectionRepo.watchCompleted();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('RampCheck'),
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: SignedInAs(userLabel: 'user.name'),
        ),
        actions: const [
          Icon(Icons.sync),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today’s Work',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            StreamBuilder<int>(
              stream: UnopenedCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  title: 'Assigned Inspections: Ready to begin',
                  value: '$value',
                  icon: Icons.assignment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OutstandingInspectionListScreen(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            StreamBuilder<int>(
              stream: OpenCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  title: 'Assigned Inspections: In Progress',
                  value: '$value',
                  icon: Icons.build,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpenedInspectionsListScreen(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            StreamBuilder<int>(
              stream: CompletedCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  title: 'Assigned Inspections: Completed • Awaiting Sync',
                  value: '$value',
                  icon: Icons.cloud_upload,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompletedInspectionListScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
