import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_sheet_frame.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_photo.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/timeline_step.dart';
import '../staff/staff_update_screen.dart';
import 'report_form_screen.dart';

/// Takes only an id and reads the incident from IncidentProvider, so the
/// screen updates live when staff change the status (or it is deleted).
class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  static Future<void> open(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportDetailsScreen(incidentId: id)));

  @override
  Widget build(BuildContext context) {
    final incident = context.select<IncidentProvider, Incident?>((p) => p.byId(incidentId));
    final auth = context.watch<AuthProvider>();
    final loading = context.select<IncidentProvider, bool>((p) => p.loading);

    if (incident == null) {
      return Scaffold(
        appBar: const ScreenHeader(title: 'Report'),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: PhosphorIconsRegular.trash,
                title: 'This report is no longer available',
                message: 'It may have been deleted by the person who reported it.',
              ),
      );
    }

    final isOwner = incident.isOwnedBy(auth.uid);
    final isStaff = auth.isStaff;

    return Scaffold(
      appBar: ScreenHeader(
        title: 'Report #${incident.reference}',
        subtle: true,
        trailing: isOwner
            ? IconButton(
                tooltip: 'Edit or delete report',
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: AppColors.ink),
                onPressed: () => _ReportOptionsSheet.show(context, incident),
              )
            : null,
      ),
      bottomNavigationBar: isStaff
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: AppButton(
                  label: 'Update status',
                  icon: PhosphorIconsRegular.notePencil,
                  onPressed: () => StaffUpdateScreen.open(context, incident.id),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          Row(
            children: [
              Icon(incident.category.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                incident.category.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const Spacer(),
              StatusPill.status(incident.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incident.title,
            style: const TextStyle(fontSize: 23, height: 1.25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _MetaRow(PhosphorIconsRegular.mapPin, incident.place),
          const SizedBox(height: 6),
          _MetaRow(
            PhosphorIconsRegular.user,
            // Privacy: other students don't see who reported an issue.
            isOwner
                ? 'Reported by you'
                : isStaff
                ? 'Reported by ${incident.reporterName}'
                : 'Reported by a student',
          ),
          const SizedBox(height: 6),
          _MetaRow(
            PhosphorIconsRegular.calendarBlank,
            'Submitted ${Formatters.timelineTime(incident.createdAt)}',
          ),
          const SizedBox(height: 20),
          if (incident.photoUrl != null) ...[
            IncidentPhoto(url: incident.photoUrl!),
            const SizedBox(height: 20),
          ],
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            incident.description,
            style: const TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 24),
          const Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ..._timeline(incident, isOwner),
        ],
      ),
    );
  }

  /// Past steps come from the stored history; future steps are shown
  /// greyed out so students know what happens next.
  List<Widget> _timeline(Incident incident, bool isOwner) {
    final history = incident.history.isEmpty
        ? [StatusChange(status: IncidentStatus.submitted, at: incident.createdAt, byName: '')]
        : incident.history;
    final last = history.last.status;
    final upcoming = switch (last) {
      IncidentStatus.submitted => [IncidentStatus.inProgress, IncidentStatus.resolved],
      IncidentStatus.inProgress => [IncidentStatus.resolved],
      _ => <IncidentStatus>[],
    };

    final steps = <Widget>[];
    for (var i = 0; i < history.length; i++) {
      final h = history[i];
      final isLatest = i == history.length - 1;
      final state = !isLatest
          ? TimelineState.done
          : switch (h.status) {
              IncidentStatus.resolved => TimelineState.done,
              IncidentStatus.rejected => TimelineState.rejected,
              _ => TimelineState.current,
            };
      final label = (i == 0 && h.status == IncidentStatus.submitted)
          ? (isOwner ? 'Submitted by you' : 'Submitted')
          : h.status == IncidentStatus.rejected
          ? 'Not accepted'
          : h.status.label;
      steps.add(
        TimelineStep(
          label: label,
          time: Formatters.timelineTime(h.at),
          note: h.note,
          state: state,
          isLast: isLatest && upcoming.isEmpty,
        ),
      );
    }
    for (var i = 0; i < upcoming.length; i++) {
      steps.add(
        TimelineStep(
          label: upcoming[i].label,
          time: 'We’ll notify you',
          state: TimelineState.pending,
          isLast: i == upcoming.length - 1,
        ),
      );
    }
    return steps;
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ),
      ],
    );
  }
}

/// "Report options" sheet: Edit / Delete, disabled once staff act on it.
class _ReportOptionsSheet extends StatelessWidget {
  const _ReportOptionsSheet({required this.incident, required this.screenContext});
  final Incident incident;

  /// The details screen's context. The sheet's own context is gone once
  /// the sheet closes, so follow-up navigation must use this one.
  final BuildContext screenContext;

  static Future<void> show(BuildContext context, Incident incident) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportOptionsSheet(incident: incident, screenContext: context),
  );

  @override
  Widget build(BuildContext context) {
    final editable = incident.isEditable;

    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color fg,
      required Color bg,
      required VoidCallback onTap,
    }) => Opacity(
      opacity: editable ? 1 : 0.45,
      child: ListTile(
        enabled: editable,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: fg, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        onTap: onTap,
      ),
    );

    return BottomSheetFrame(
      title: 'Report options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          option(
            icon: PhosphorIconsRegular.pencilSimple,
            title: 'Edit report',
            subtitle: 'Change the details or photo',
            fg: AppColors.ink,
            bg: AppColors.primaryTint,
            onTap: () {
              Navigator.pop(context);
              ReportFormScreen.open(screenContext, existing: incident);
            },
          ),
          option(
            icon: PhosphorIconsRegular.trash,
            title: 'Delete report',
            subtitle: 'Remove it permanently',
            fg: AppColors.error,
            bg: AppColors.errorTint,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(screenContext, incident);
            },
          ),
          const SizedBox(height: 8),
          const NoticeBanner(
            icon: PhosphorIconsRegular.lock,
            tone: NoticeTone.gray,
            text: 'You can edit or delete a report only while it is still Submitted.',
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Incident incident) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.errorTint, shape: BoxShape.circle),
              child: const Icon(PhosphorIconsRegular.trash, color: AppColors.error, size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Delete this report?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '“${incident.title}”${incident.photoUrl != null ? ' and its photo' : ''} '
              'will be removed. This can’t be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Delete',
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Keep report',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await context.read<IncidentProvider>().delete(incident);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // leave the details screen
    showAppSnack(context, 'Report deleted');
  } catch (e) {
    if (!context.mounted) return;
    showAppSnack(context, e is StateError ? e.message : AuthService.describe(e), error: true);
  }
}
