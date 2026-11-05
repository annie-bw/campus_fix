import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import 'storage_service.dart';

/// All Firestore reads/writes for incidents (and the notifications that
/// status changes generate). Providers depend on this, never on Firestore.
class IncidentRepository {
  IncidentRepository({FirebaseFirestore? db, StorageService? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage ?? StorageService();

  final FirebaseFirestore _db;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _incidents => _db.collection('incidents');
  CollectionReference<Map<String, dynamic>> get _notifications => _db.collection('notifications');

  /// Live feed of every report on campus, newest first.
  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots()
      .map((snap) => snap.docs.map(Incident.fromDoc).toList());

  /// CREATE. Photo (optional) is uploaded first so the document is written
  /// once with its URL.
  Future<Incident> create({
    required AppUser reporter,
    required IncidentDraft draft,
    File? photo,
    void Function(double)? onUploadProgress,
  }) async {
    final doc = _incidents.doc();
    String? url;
    String? path;
    if (photo != null) {
      final up = await _storage.uploadIncidentPhoto(
        uid: reporter.uid,
        incidentId: doc.id,
        file: photo,
        onProgress: onUploadProgress,
      );
      url = up.url;
      path = up.path;
    }

    final now = DateTime.now();
    final reference = 'CF-${doc.id.substring(0, 6).toUpperCase()}';
    final first = StatusChange(status: IncidentStatus.submitted, at: now, byName: reporter.name);

    final batch = _db.batch();
    batch.set(doc, {
      'reference': reference,
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'category': draft.category.name,
      'location': draft.location,
      'locationDetail': draft.locationDetail.trim(),
      'status': IncidentStatus.submitted.name,
      'reporterId': reporter.uid,
      'reporterName': reporter.name,
      'photoUrl': url,
      'photoPath': path,
      'history': [first.toMap()],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_notifications.doc(), {
      'userId': reporter.uid,
      'incidentId': doc.id,
      'title': 'Report received',
      'body': '“${draft.title.trim()}” was sent to campus staff.',
      'status': IncidentStatus.submitted.name,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return Incident(
      id: doc.id,
      reference: reference,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      location: draft.location,
      locationDetail: draft.locationDetail.trim(),
      status: IncidentStatus.submitted,
      reporterId: reporter.uid,
      reporterName: reporter.name,
      createdAt: now,
      updatedAt: now,
      history: [first],
      photoUrl: url,
      photoPath: path,
    );
  }

  /// UPDATE (student). Only allowed while the report is still Submitted;
  /// the security rules enforce the same thing server-side.
  Future<void> updateDetails({
    required Incident incident,
    required IncidentDraft draft,
    File? newPhoto,
    bool removePhoto = false,
    void Function(double)? onUploadProgress,
  }) async {
    final data = <String, dynamic>{
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'category': draft.category.name,
      'location': draft.location,
      'locationDetail': draft.locationDetail.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    String? oldPathToDelete;
    if (newPhoto != null) {
      final up = await _storage.uploadIncidentPhoto(
        uid: incident.reporterId,
        incidentId: incident.id,
        file: newPhoto,
        onProgress: onUploadProgress,
      );
      data['photoUrl'] = up.url;
      data['photoPath'] = up.path;
      oldPathToDelete = incident.photoPath;
    } else if (removePhoto) {
      data['photoUrl'] = null;
      data['photoPath'] = null;
      oldPathToDelete = incident.photoPath;
    }

    await _incidents.doc(incident.id).update(data);
    await _storage.deleteIfExists(oldPathToDelete);
  }

  /// UPDATE (staff). Changes status, appends to the timeline and notifies
  /// the reporter, all in one atomic batch.
  Future<void> updateStatus({
    required Incident incident,
    required IncidentStatus status,
    required AppUser staff,
    String? note,
  }) async {
    final change = StatusChange(status: status, at: DateTime.now(), byName: staff.name, note: note?.trim());
    final batch = _db.batch();
    batch.update(_incidents.doc(incident.id), {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([change.toMap()]),
    });
    batch.set(_notifications.doc(), {
      'userId': incident.reporterId,
      'incidentId': incident.id,
      'title': _notificationTitle(status),
      'body': (note != null && note.trim().isNotEmpty)
          ? '“${incident.title}” — ${note.trim()}'
          : '“${incident.title}” is now ${status.label.toLowerCase()}.',
      'status': status.name,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// DELETE (student, while Submitted). Removes the photo too.
  Future<void> delete(Incident incident) async {
    await _incidents.doc(incident.id).delete();
    await _storage.deleteIfExists(incident.photoPath);
  }

  static String _notificationTitle(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => 'Status changed to Submitted',
    IncidentStatus.inProgress => 'Status changed to In progress',
    IncidentStatus.resolved => 'Resolved',
    IncidentStatus.rejected => 'Report not accepted',
  };
}
