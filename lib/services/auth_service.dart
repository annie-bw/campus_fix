import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import 'storage_service.dart';

/// Thrown when someone uses a non-ALU email that an admin has not set up
/// as staff (or the staff invite can't be checked).
class AccessDeniedException implements Exception {
  const AccessDeniedException([this.message = 'CampusFix is for ALU accounts. Sign in with your ALU email.']);
  final String message;
}

/// Thin wrapper around Firebase Auth + the users collection.
/// No UI code and no state here: providers call these methods.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> profileStream(String uid) =>
      _users.doc(uid).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Students sign up with an ALU email. Anyone else (e.g. staff on Gmail)
  /// may sign up only if an admin added staffInvites/{email}; they become staff.
  Future<void> register({required String name, required String email, required String password}) async {
    final isAlu = Validators.isAluEmail(email);
    // For a non-ALU email the invite is the only way in, so a failed lookup
    // must surface (e.g. rules not published, offline) instead of reading
    // as "not invited".
    final invite = await _staffInvite(email, throwOnError: !isAlu);
    if (invite == null && !isAlu) {
      throw AccessDeniedException(
        'No staff invite found for ${email.trim().toLowerCase()}. '
        'Check that an admin added this exact email, or sign up with your ALU email if you are a student.',
      );
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    // Send the email first: it is the step the user is waiting on.
    await user.sendEmailVerification();
    // Firestore writes never "fail" offline, they queue and retry. Don't let
    // a slow or misconfigured backend freeze the sign-up screen; the write
    // keeps syncing in the background and ensureProfile() repairs it later.
    try {
      await _writeNewProfile(user.uid, name, email, invite).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// The staffInvites/{email} doc's data, or null if this email is not
  /// invited. If the lookup fails it returns null (student rules apply)
  /// unless [throwOnError] is set.
  Future<Map<String, dynamic>?> _staffInvite(String email, {bool throwOnError = false}) async {
    final id = email.trim().toLowerCase();
    if (id.isEmpty) return null;
    try {
      final doc = await _db
          .collection('staffInvites')
          .doc(id)
          .get(const GetOptions(source: Source.server)) // never trust a stale cache here
          .timeout(const Duration(seconds: 10));
      return doc.exists ? (doc.data() ?? {}) : null;
    } on FirebaseException catch (e) {
      if (!throwOnError) return null;
      if (e.code == 'permission-denied') {
        throw const AccessDeniedException(
          'Staff sign-up isn’t set up yet: the latest Firestore rules haven’t been published.',
        );
      }
      rethrow;
    } catch (_) {
      if (!throwOnError) return null;
      throw const AccessDeniedException('Couldn’t check your staff invite. Check your connection and retry.');
    }
  }

  Future<void> _writeNewProfile(String uid, String name, String email, Map<String, dynamic>? invite) {
    final department = invite?['department'];
    return _users
        .doc(uid)
        .set(
          AppUser(
            uid: uid,
            name: name.trim(),
            email: email.trim().toLowerCase(),
            role: invite != null ? UserRole.staff : UserRole.student,
            department: department is String && department.trim().isNotEmpty ? department : null,
          ).toNewUserMap(),
        );
  }

  /// Creates the users/{uid} doc if it is missing (e.g. sign-up was
  /// interrupted before the profile saved). Never touches an existing doc,
  /// so a staff role set in the console is preserved.
  Future<void> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return;
    final email = user.email ?? '';
    final name = (user.displayName?.trim().isNotEmpty ?? false) ? user.displayName! : email.split('@').first;
    await _writeNewProfile(user.uid, name, email, await _staffInvite(email));
  }

  /// True when the signed-in user's profile has role 'staff'. Used to let
  /// admin-created staff accounts in with a non-ALU email.
  Future<bool> currentUserIsStaff() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _users.doc(user.uid).get().timeout(const Duration(seconds: 10));
      return doc.exists && doc.data()?['role'] == UserRole.staff.name;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendVerificationEmail() async => _auth.currentUser?.sendEmailVerification();

  /// Reloads the Firebase user and returns whether the email is verified.
  /// The ID token is refreshed so security rules see email_verified = true.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final fresh = _auth.currentUser;
    if (fresh?.emailVerified ?? false) {
      await fresh!.getIdToken(true);
      return true;
    }
    return false;
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Turns Firebase error codes into sentences a student understands.
  static String describe(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-login-credentials':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists for this email. Try signing in.';
        case 'weak-password':
          return 'Choose a stronger password.';
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and retry.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'Sign-up isn’t available right now. Please try again later.';
        case 'internal-error':
          if ((error.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
            return 'Sign-up isn’t available right now. Please try again later.';
          }
          return 'Couldn’t reach the server. Check your connection and retry.';
      }
      return error.message ?? 'Something went wrong. Please try again.';
    }
    if (error is PhotoStorageException) return error.message;
    if (error is AccessDeniedException) return error.message;
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You don’t have permission to do that.';
      }
      if (error.code == 'unavailable') {
        return 'Can’t reach the server. Check your connection.';
      }
      return error.message ?? 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
