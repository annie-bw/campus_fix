import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, unverified, signedIn }

/// Owns the session. The AuthGate widget rebuilds from [status], so
/// navigation between the auth screens and the app is fully state driven.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthStatus _status = AuthStatus.unknown;
  User? _firebaseUser;
  AppUser? _profile;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get profile => _profile;
  String? get uid => _firebaseUser?.uid;
  String get email => _firebaseUser?.email ?? '';
  bool get busy => _busy;
  bool get isStaff => _profile?.isStaff ?? false;

  void _onAuthChanged(User? user) {
    _firebaseUser = user;
    _profileSub?.cancel();
    _profile = null;

    if (user == null) {
      _status = AuthStatus.signedOut;
    } else if (!user.emailVerified) {
      _status = AuthStatus.unverified;
    } else {
      _listenToProfile(user.uid);
      return;
    }
    notifyListeners();
  }

  void _listenToProfile(String uid) {
    var repairTried = false;
    _profileSub = _service
        .profileStream(uid)
        .listen(
          (p) {
            if (p == null && !repairTried) {
              // Profile doc is missing (sign-up was interrupted). Recreate it;
              // the stream emits again once it exists.
              repairTried = true;
              _service.ensureProfile().timeout(const Duration(seconds: 10)).catchError((_) {
                // Backend unreachable: continue into the app rather than hang.
                _status = AuthStatus.signedIn;
                notifyListeners();
              });
              return;
            }
            // Non-ALU emails get in only as admin-created staff accounts.
            if (!Validators.isAluEmail(email) && !(p?.isStaff ?? false)) {
              _service.signOut();
              return;
            }
            _profile = p;
            _status = AuthStatus.signedIn;
            notifyListeners();
          },
          onError: (_) {
            _status = AuthStatus.signedIn;
            notifyListeners();
          },
        );
  }

  /// Runs [action] with a busy flag; returns a friendly error or null.
  Future<String?> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e) {
      return AuthService.describe(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// ALU emails sign in normally. Any other email must belong to a staff
  /// account; otherwise it is signed straight back out.
  Future<String?> signIn(String email, String password) => _run(() async {
    await _service.signIn(email, password);
    if (Validators.isAluEmail(email) || await _service.currentUserIsStaff()) return;
    // An invited staff member whose profile didn't save at sign-up: create
    // it now (ensureProfile picks up the invite), then check again.
    try {
      await _service.ensureProfile().timeout(const Duration(seconds: 10));
    } catch (_) {}
    if (!await _service.currentUserIsStaff()) {
      await _service.signOut();
      throw const AccessDeniedException();
    }
  });

  /// ALU emails register as students; invited emails (staffInvites) as staff.
  /// The service rejects everything else.
  Future<String?> register(String name, String email, String password) =>
      _run(() => _service.register(name: name, email: email, password: password));

  Future<String?> resendVerification() => _run(_service.sendVerificationEmail);

  /// Called from "I've verified my email". Returns an error if not yet verified.
  Future<String?> checkVerified() async {
    String? error;
    final runError = await _run(() async {
      final ok = await _service.reloadAndCheckVerified();
      if (!ok) {
        error = 'Not verified yet. Open the link in your email, then try again.';
        return;
      }
      _onAuthChanged(_service.currentUser);
    });
    return runError ?? error;
  }

  Future<String?> sendPasswordReset(String email) => _run(() => _service.sendPasswordReset(email));

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
