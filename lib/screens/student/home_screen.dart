import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_filter.dart';
import '../../providers/incident_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shell_provider.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/campus_photo.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';
import '../notifications/notifications_screen.dart';
import '../reports/report_details_screen.dart';
import '../reports/report_form_screen.dart';

/// Student home: greeting, the main "report" card, my counts, category
/// shortcuts and the latest reports on campus.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMine(BuildContext context, IncidentStatus status) {
    context.read<IncidentProvider>().applyFilter(IncidentFilter(onlyMine: true, status: status));
    context.read<ShellProvider>().goTo(Tabs.reports);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((a) => a.profile?.name ?? '');
    final uid = context.select<AuthProvider, String?>((a) => a.uid);
    final unread = context.select<NotificationProvider, int>((n) => n.unreadCount);
    final incidents = context.watch<IncidentProvider>();
    final latest = incidents.all.take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ---- Greeting
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi ${Formatters.firstName(name)}',
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: PhosphorIconsRegular.bell,
                tooltip: 'Notifications',
                variant: IconButtonVariant.outline,
                round: true,
                badge: unread,
                onPressed: () => NotificationsScreen.open(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- Main action
          _ReportPhotoCard(onTap: () => ReportFormScreen.open(context)),
          const SizedBox(height: 28),

          // ---- My reports
          const _SectionTitle('Your reports'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, s) in const [
                IncidentStatus.submitted,
                IncidentStatus.inProgress,
                IncidentStatus.resolved,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _StatusCount(
                    status: s,
                    count: incidents.countMine(s),
                    onTap: () => _openMine(context, s),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // ---- Category shortcuts
          const _SectionTitle('Report by category'),
          const SizedBox(height: 12),
          TileGrid(
            children: [
              for (final c in IncidentCategory.values)
                CategoryTile(
                  category: c,
                  selected: false,
                  onTap: () => ReportFormScreen.open(context, category: c),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Latest on campus
          SectionHeader(
            title: 'Latest on campus',
            action: 'View all',
            onAction: () {
              context.read<IncidentProvider>().resetFilter();
              context.read<ShellProvider>().goTo(Tabs.reports);
            },
          ),
          const SizedBox(height: 8),
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
          else if (latest.isEmpty)
            const EmptyState(
              icon: PhosphorIconsRegular.tray,
              title: 'No reports yet',
              message: 'Reports from across campus will show up here.',
            )
          else
            for (final i in latest)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(
                  incident: i,
                  isMine: i.isOwnedBy(uid),
                  onTap: () => ReportDetailsScreen.open(context, i.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
}

/// The design's green "Something not working?" card, now showing the
/// campus. The bottom of the photo is darkened so the text stays readable.
class _ReportPhotoCard extends StatelessWidget {
  const _ReportPhotoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Report an issue',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 184,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CampusPhoto(alignment: Alignment(0, 0.35)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 1],
                    colors: [Color(0x0010231A), Color(0xD910231A)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Something not working?',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell us what and where.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(PhosphorIconsRegular.plus, color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the three "Your reports" counts, tinted in its status colour.
class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.status, required this.count, required this.onTap});

  final IncidentStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count ${status.label}',
      excludeSemantics: true,
      child: Material(
        color: status.background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: status.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: status.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
