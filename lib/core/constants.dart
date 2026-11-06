import 'package:flutter/material.dart';
import 'app_icons.dart';

import 'theme/app_colors.dart';

/// Email domains allowed to sign up. Students use alustudent.com,
/// staff use alueducation.com. Anything else is rejected at registration
/// and again in the Firestore security rules.
///
const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

/// Staff exception: an email an admin added to staffInvites/{email} (in the
/// Firebase Console) may sign up with any domain and becomes staff. Nobody
/// can invite themselves, so this does not open the app to outsiders.

/// Address of the CampusFix photo Worker on Cloudflare (see
/// cloudflare/photo-worker.js). Photos are stored in Cloudflare Workers KV.
/// No trailing slash.
const photoApiUrl = 'https://hello-world-hidden-waterfall-ab26.bwizaannie20.workers.dev';

/// Incident categories shown as tiles on the report form.
enum IncidentCategory {
  facilities('Facilities', PhosphorIconsRegular.buildings),
  water('Water', PhosphorIconsRegular.drop),
  electricity('Electricity', PhosphorIconsRegular.lightning),
  furniture('Furniture', PhosphorIconsRegular.chair),
  sanitation('Sanitation', PhosphorIconsRegular.trash),
  safety('Safety', PhosphorIconsRegular.shield);

  const IncidentCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  static IncidentCategory fromName(String? name) =>
      IncidentCategory.values.firstWhere((c) => c.name == name, orElse: () => IncidentCategory.facilities);
}

/// Lifecycle of a report. Only staff can move a report between statuses.
enum IncidentStatus {
  submitted('Submitted', AppColors.blueBg, AppColors.blueFg),
  inProgress('In progress', AppColors.amberBg, AppColors.amberFg),
  resolved('Resolved', AppColors.greenBg, AppColors.greenFg),
  rejected('Rejected', AppColors.redBg, AppColors.redFg);

  const IncidentStatus(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;

  IconData get icon => switch (this) {
    IncidentStatus.submitted => PhosphorIconsRegular.paperPlaneTilt,
    IncidentStatus.inProgress => PhosphorIconsRegular.wrench,
    IncidentStatus.resolved => PhosphorIconsRegular.checkCircle,
    IncidentStatus.rejected => PhosphorIconsRegular.prohibit,
  };

  static IncidentStatus fromName(String? name) =>
      IncidentStatus.values.firstWhere((s) => s.name == name, orElse: () => IncidentStatus.submitted);
}

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? name) => name == 'staff' ? UserRole.staff : UserRole.student;
}

/// ALU campus areas offered in the "Where is it?" picker. The exact spot
/// (room, floor, landmark) is typed into the "Specify exactly" field.
const campusLocations = ['Leadership Commons', 'Enterprise Commons', 'Social Commons', 'Parking'];
