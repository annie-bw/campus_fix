import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/theme/app_colors.dart';

enum TimelineState { done, current, pending, rejected }

/// One row in the Progress timeline on the details screen.
class TimelineStep extends StatelessWidget {
  const TimelineStep({
    super.key,
    required this.label,
    required this.time,
    required this.state,
    this.note,
    this.isLast = false,
  });

  final String label;
  final String time;
  final TimelineState state;
  final String? note;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final marker = switch (state) {
      TimelineState.done => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(PhosphorIconsRegular.check, size: 16, color: Colors.white),
      ),
      TimelineState.current => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        ),
      ),
      TimelineState.rejected => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
        child: const Icon(PhosphorIconsRegular.x, size: 16, color: Colors.white),
      ),
      TimelineState.pending => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pending, width: 2),
        ),
      ),
    };

    final labelColor = switch (state) {
      TimelineState.current => AppColors.primary,
      TimelineState.pending => AppColors.muted,
      TimelineState.rejected => AppColors.error,
      TimelineState.done => AppColors.ink,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              marker,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    constraints: const BoxConstraints(minHeight: 22),
                    color: state == TimelineState.done ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: labelColor),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note!,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
