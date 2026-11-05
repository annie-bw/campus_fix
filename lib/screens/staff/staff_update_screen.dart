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
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_photo.dart';

/// Staff-only: change a report's status and leave a message for the
/// student. Guarded in three places: the UI only offers it to staff, the
/// provider re-checks the role, and Firestore rules reject non-staff writes.
class StaffUpdateScreen extends StatefulWidget {
  const StaffUpdateScreen({super.key, required this.incidentId});

  final String incidentId;

  static Future<void> open(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaffUpdateScreen(incidentId: id)));

  @override
  State<StaffUpdateScreen> createState() => _StaffUpdateScreenState();
}

class _StaffUpdateScreenState extends State<StaffUpdateScreen> {
  final _note = TextEditingController();
  IncidentStatus? _picked;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(Incident incident) async {
    final status = _picked ?? incident.status;
    if (status == incident.status && _note.text.trim().isEmpty) {
      showAppSnack(context, 'Pick a new status or write a message first.', error: true);
      return;
    }
    if (status == IncidentStatus.rejected && _note.text.trim().isEmpty) {
      showAppSnack(context, 'Tell the student why the report wasn’t accepted.', error: true);
      return;
    }
    try {
      await context.read<IncidentProvider>().updateStatus(incident, status, _note.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Status updated. The student has been notified.');
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, e is StateError ? e.message : AuthService.describe(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    final incident = context.select<IncidentProvider, Incident?>((p) => p.byId(widget.incidentId));
    final saving = context.select<IncidentProvider, bool>((p) => p.saving);

    if (!isStaff) {
      return const Scaffold(
        appBar: ScreenHeader(title: 'Update status'),
        body: EmptyState(
          icon: PhosphorIconsRegular.lock,
          title: 'Staff only',
          message: 'Only authorised campus staff can change a report’s status.',
        ),
      );
    }
    if (incident == null) {
      return const Scaffold(
        appBar: ScreenHeader(title: 'Update status'),
        body: EmptyState(icon: PhosphorIconsRegular.trash, title: 'Report not found'),
      );
    }

    final selected = _picked ?? incident.status;

    return Scaffold(
      appBar: const ScreenHeader(title: 'Update status'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                IncidentThumb(incident: incident, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incident.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${incident.place} · by ${incident.reporterName} · '
                        '${Formatters.timeAgo(incident.createdAt)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('New status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          RadioGroup<IncidentStatus>(
            groupValue: selected,
            onChanged: (v) => setState(() => _picked = v),
            child: Column(
              children: [
                for (final s in IncidentStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StatusOption(
                      status: s,
                      selected: selected == s,
                      isCurrent: incident.status == s,
                      onTap: saving ? null : () => setState(() => _picked = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: selected == IncidentStatus.rejected
                ? 'Reason for the student'
                : 'Message to student (optional)',
            controller: _note,
            multiline: true,
            enabled: !saving,
            maxLength: 300,
            hint: selected == IncidentStatus.rejected
                ? 'e.g. Duplicate of an existing report.'
                : 'e.g. An electrician is on the way.',
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Save update',
            loading: saving,
            loadingLabel: 'Saving…',
            onPressed: () => _save(incident),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool selected;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              Radio<IncidentStatus>(value: status, activeColor: AppColors.primary),
              Expanded(
                child: Text(
                  status.label,
                  style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
              if (isCurrent)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Text(
                    'Current',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
