import 'package:flutter/material.dart';
import 'package:maintenance_system/ui/widgets/logout_button.dart';
import 'package:maintenance_system/ui/widgets/signed_in_as.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/repositories/inspection_repository.dart';

import 'unopened_inspection_list_screen.dart';
import 'opened_inspection_list_screen.dart';
import 'completed_inspection_list_screen.dart';
import '../dialogs/show_attempt_sync_dialog.dart';
import 'package:maintenance_system/core/data/sync/i_sync_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inspectionRepo = context.read<InspectionRepository>();

    final unopenedCount$ = inspectionRepo.watchUnopenedCount();
    final openCount$ = inspectionRepo.watchOpenCount();
    final completedCount$ = inspectionRepo.watchCompletedCount();

    return Scaffold(
      key: const Key('screen_home'),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('RampCheck'),
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: SignedInAsContainer(),
        ),
        actions: [
          IconButton(
            key: const Key('btn_sync'),
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final apiKey = await showAttemptSyncDialog(context,);
              if (apiKey == null) return;

              try {
                await context.read<ISyncService>().syncNow(apiKey: apiKey);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Sync successful',
                      key: Key('snackbar_sync_success'),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sync failed: $e',
                      key: const Key('snackbar_sync_failed'),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: const LogoutButton(),
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
              stream: unopenedCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  key: const Key('nav_unopened'),
                  title: 'Assigned Inspections: Ready to begin',
                  value: '$value',
                  icon: Icons.assignment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UnopenedInspectionListContainer(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            StreamBuilder<int>(
              stream: openCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  key: const Key('nav_opened'),
                  title: 'Assigned Inspections: In Progress',
                  value: '$value',
                  icon: Icons.build,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpenedInspectionListContainer(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            StreamBuilder<int>(
              stream: completedCount$,
              initialData: 0,
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return _DashboardCard(
                  key: const Key('nav_completed'),
                  title: 'Assigned Inspections: Completed • Awaiting Sync',
                  value: '$value',
                  icon: Icons.cloud_upload,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompletedInspectionListContainer(),
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
    super.key,
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
