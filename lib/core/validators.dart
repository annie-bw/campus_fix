import 'constants.dart';

/// Pure validation functions used by the forms (and unit-tested in test/).
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@([^@\s]+)$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your full name';
    if (v.length < 3) return 'Name looks too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    final match = _emailPattern.firstMatch(v);
    if (match == null) return 'Enter a valid email address';
    return null;
  }

  /// Same as [email] but also enforces an ALU domain.
  static String? aluEmail(String? value) {
    final basic = email(value);
    if (basic != null) return basic;
    if (!isAluEmail(value!)) return 'Use your ALU email (e.g. name@alustudent.com)';
    return null;
  }

  static bool isAluEmail(String email) {
    final domain = email.trim().toLowerCase().split('@').last;
    return allowedEmailDomains.contains(domain);
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Mix letters and numbers';
    }
    return null;
  }

  static String? reportTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'A title is required';
    if (v.length < 5) return 'Make the title a little longer';
    if (v.length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? reportDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'A description is required';
    if (v.length < 15) return 'Add a bit more detail (at least 15 characters)';
    if (v.length > 1000) return 'Keep it under 1000 characters';
    return null;
  }

  static String? location(String? value) =>
      (value == null || value.isEmpty) ? 'Please choose where it is' : null;

  static String? locationDetail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Tell staff exactly where (room, floor or landmark)';
    if (v.length < 3) return 'Add a little more detail';
    if (v.length > 100) return 'Keep it under 100 characters';
    return null;
  }
}
