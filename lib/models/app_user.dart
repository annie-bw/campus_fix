import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// Profile stored at users/{uid}. Role is the source of truth for access
/// control. Staff come from an admin's invite (staffInvites/{email}) or an
/// admin editing `role` in the Firebase Console; nobody can change their own.
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

  /// Fields written on registration. Security rules only accept "staff"
  /// when staffInvites/{email} exists, and "student" for ALU emails.
  Map<String, dynamic> toNewUserMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    if (department != null) 'department': department,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
