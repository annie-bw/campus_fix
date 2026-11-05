import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// In-app notification stored at notifications/{id}.
/// Created when a report is received and whenever staff change its status.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.incidentId,
    required this.title,
    required this.body,
    required this.status,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String incidentId;
  final String title;
  final String body;
  final IncidentStatus status;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      incidentId: d['incidentId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      status: IncidentStatus.fromName(d['status'] as String?),
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
