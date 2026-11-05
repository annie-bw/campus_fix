import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme/app_colors.dart';

/// Rounded badge. Use [StatusPill.status] for report statuses so the
/// colours always match (Submitted blue, In progress amber, etc).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.background, required this.foreground});

  StatusPill.status(IncidentStatus s, {super.key})
    : label = s.label,
      background = s.background,
      foreground = s.foreground;

  const StatusPill.dark(this.label, {super.key})
    : background = AppColors.primaryDark,
      foreground = Colors.white;

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}
