import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('notifications');

  /// Filtered by user only and sorted on the device, so no composite
  /// Firestore index is needed.
  Stream<List<AppNotification>> watchFor(String uid) =>
      _col.where('userId', isEqualTo: uid).limit(100).snapshots().map((snap) {
        final list = snap.docs.map(AppNotification.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  Future<void> markAllRead(List<AppNotification> items) async {
    final unread = items.where((n) => !n.read);
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final n in unread) {
      batch.update(_col.doc(n.id), {'read': true});
    }
    await batch.commit();
  }
}
