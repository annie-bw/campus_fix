import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/formatters.dart';
import '../core/theme/app_colors.dart';
import '../models/incident.dart';
import 'incident_photo.dart';
import 'status_pill.dart';

/// List row for a report, as in the design: thumbnail (the photo, or the
/// category icon), title, "building · time", status, chevron.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showReporter = false,
    this.isMine = false,
  });

  final Incident incident;
  final VoidCallback onTap;
  final bool showReporter; // staff see who reported it
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final meta = [
      incident.location,
      Formatters.timeAgo(incident.createdAt),
      if (showReporter) 'by ${incident.reporterName}',
    ].join(' · ');

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IncidentThumb(incident: incident, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusPill.status(incident.status),
                        if (isMine) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Yours',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(PhosphorIconsRegular.caretRight, color: AppColors.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}
