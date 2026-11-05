import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_filter.dart';
import '../../providers/incident_provider.dart';
import '../../providers/shell_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_pill.dart';
import '../reports/report_details_screen.dart';

/// Staff landing tab: campus-wide counts and the queue of new reports.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  void _openStatus(BuildContext context, IncidentStatus s) {
    context.read<IncidentProvider>().applyFilter(IncidentFilter(status: s));
    context.read<ShellProvider>().goTo(Tabs.reports);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((a) => a.profile?.name ?? '');
    final incidents = context.watch<IncidentProvider>();

    // Oldest unhandled report first: the queue staff should work through.
    final queue = incidents.all.where((i) => i.status == IncidentStatus.submitted).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final active = incidents.all.where((i) => i.status == IncidentStatus.inProgress).take(3).toList();

    Widget tile(IncidentStatus s) => Expanded(
      child: StatTile(
        value: '${incidents.countAll(s)}',
        label: s.label,
        background: s.background,
        foreground: s.foreground,
        onTap: () => _openStatus(context, s),
      ),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill.dark('Staff'),
                    const SizedBox(height: 8),
                    Text(
                      'Hello, ${Formatters.firstName(name)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here’s what needs your attention.',
                      style: TextStyle(fontSize: 15, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              tile(IncidentStatus.submitted),
              const SizedBox(width: 8),
              tile(IncidentStatus.inProgress),
              const SizedBox(width: 8),
              tile(IncidentStatus.resolved),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'New reports (${queue.length})',
            action: 'See all',
            onAction: () => _openStatus(context, IncidentStatus.submitted),
          ),
          const SizedBox(height: 6),
          if (incidents.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (incidents.loadError != null)
            EmptyState(
              icon: PhosphorIconsRegular.cloudSlash,
              title: 'Couldn’t load reports',
              message: incidents.loadError,
            )
          else if (queue.isEmpty)
            const EmptyState(
              icon: PhosphorIconsRegular.checkCircle,
              title: 'All caught up',
              message: 'There are no new reports waiting for review.',
            )
          else
            for (final i in queue.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(
                  incident: i,
                  showReporter: true,
                  onTap: () => ReportDetailsScreen.open(context, i.id),
                ),
              ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionHeader(
              title: 'In progress',
              action: 'See all',
              onAction: () => _openStatus(context, IncidentStatus.inProgress),
            ),
            const SizedBox(height: 6),
            for (final i in active)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(
                  incident: i,
                  showReporter: true,
                  onTap: () => ReportDetailsScreen.open(context, i.id),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
