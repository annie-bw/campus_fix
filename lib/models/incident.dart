import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// One entry in a report's status timeline.
class StatusChange {
  const StatusChange({required this.status, required this.at, required this.byName, this.note});

  final IncidentStatus status;
  final DateTime at;
  final String byName;
  final String? note;

  factory StatusChange.fromMap(Map<String, dynamic> m) => StatusChange(
    status: IncidentStatus.fromName(m['status'] as String?),
    at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    byName: m['byName'] as String? ?? '',
    note: m['note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'at': Timestamp.fromDate(at),
    'byName': byName,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

/// An incident report stored at incidents/{id}.
class Incident {
  const Incident({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.locationDetail = '',
    this.photoUrl,
    this.photoPath,
  });

  final String id;
  final String reference; // human friendly, e.g. CF-8F3K2A
  final String title;
  final String description;
  final IncidentCategory category;
  final String location; // campus area, e.g. Leadership Commons
  final String locationDetail; // exact spot, e.g. 2nd floor, Room 204

  /// "Leadership Commons · 2nd floor, Room 204"
  String get place => locationDetail.isEmpty ? location : '$location · $locationDetail';
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusChange> history;
  final String? photoUrl;
  final String? photoPath; // Storage path, kept so the file can be deleted

  /// Students may edit or delete only while nobody has acted on the report.
  bool get isEditable => status == IncidentStatus.submitted;

  bool isOwnedBy(String? uid) => uid != null && uid == reporterId;

  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    return title.toLowerCase().contains(s) ||
        place.toLowerCase().contains(s) ||
        description.toLowerCase().contains(s) ||
        reference.toLowerCase().contains(s) ||
        category.label.toLowerCase().contains(s);
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    // serverTimestamp() is null locally until the write is confirmed.
    final created = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Incident(
      id: doc.id,
      reference: d['reference'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: IncidentCategory.fromName(d['category'] as String?),
      location: d['location'] as String? ?? '',
      locationDetail: d['locationDetail'] as String? ?? '',
      status: IncidentStatus.fromName(d['status'] as String?),
      reporterId: d['reporterId'] as String? ?? '',
      reporterName: d['reporterName'] as String? ?? '',
      createdAt: created,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? created,
      history: ((d['history'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatusChange.fromMap)
          .toList(),
      photoUrl: d['photoUrl'] as String?,
      photoPath: d['photoPath'] as String?,
    );
  }
}

/// Values the student fills in on the report form.
class IncidentDraft {
  const IncidentDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.locationDetail,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final String locationDetail;
}
