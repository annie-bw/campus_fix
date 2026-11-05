import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// Profile stored at users/{uid}. Role is the source of truth for access
/// control; it is only ever changed by an admin in the Firebase Console.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? department;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: UserRole.fromName(d['role'] as String?),
      department: d['department'] as String?,
    );
  }

  /// Fields written on registration. Role is always "student" here;
  /// security rules reject any other value.
  Map<String, dynamic> toNewUserMap() => {
    'name': name,
    'email': email,
    'role': UserRole.student.name,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
