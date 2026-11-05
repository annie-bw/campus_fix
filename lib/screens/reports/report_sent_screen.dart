import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import 'report_details_screen.dart';

class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((a) => a.profile?.name ?? '');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsRegular.check, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Report sent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Thanks, ${Formatters.firstName(name)}. Campus staff have been notified. '
                'We’ll let you know when the status changes.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.55, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Reference', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ),
                    Text(
                      '#${incident.reference}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              AppButton(
                label: 'View my report',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => ReportDetailsScreen(incidentId: incident.id)),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Back to home',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
