import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/auth_service.dart';
import '../services/incident_repository.dart';
import 'incident_filter.dart';

/// Single source of truth for incident data. Every screen (home stats,
/// reports list, details, staff dashboard) reads from this provider, so a
/// status change made by staff appears everywhere at once via the
/// Firestore snapshot stream.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._repo);

  final IncidentRepository _repo;
  StreamSubscription<List<Incident>>? _sub;

  AppUser? _user;
  List<Incident> _all = [];
  bool _loading = false;
  String? _loadError;
  IncidentFilter _filter = const IncidentFilter();

  // Submission state (drives the "Sending…" screen state).
  bool _saving = false;
  double? _uploadProgress;

  List<Incident> get all => _all;
  bool get loading => _loading;
  String? get loadError => _loadError;
  IncidentFilter get filter => _filter;
  bool get saving => _saving;
  double? get uploadProgress => _uploadProgress;
  AppUser? get user => _user;

  List<Incident> get visible => _filter.apply(_all, uid: _user?.uid);
  List<Incident> get mine => _all.where((i) => i.isOwnedBy(_user?.uid)).toList();

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  int countMine(IncidentStatus s) => mine.where((i) => i.status == s).length;
  int countAll(IncidentStatus s) => _all.where((i) => i.status == s).length;

  /// Called by ChangeNotifierProxyProvider whenever the auth profile changes.
  void updateUser(AppUser? user) {
    if (user?.uid == _user?.uid && user?.role == _user?.role) {
      _user = user;
      return;
    }
    _user = user;
    _sub?.cancel();
    _all = [];
    _filter = const IncidentFilter();
    if (user == null) {
      _loading = false;
      // updateUser runs inside the proxy provider's build; defer the notify.
      scheduleMicrotask(notifyListeners);
      return;
    }
    _loading = true;
    _loadError = null;
    _sub = _repo.watchAll().listen(
      (items) {
        _all = items;
        _loading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _loadError = AuthService.describe(e);
        notifyListeners();
      },
    );
  }

  // ---- Filtering ---------------------------------------------------------

  void setQuery(String q) {
    _filter = _filter.copyWith(query: q);
    notifyListeners();
  }

  void setStatus(IncidentStatus? s) {
    _filter = _filter.copyWith(status: () => s);
    notifyListeners();
  }

  void applyFilter(IncidentFilter f) {
    _filter = f.copyWith(query: _filter.query);
    notifyListeners();
  }

  void showOnlyMine() {
    _filter = const IncidentFilter(onlyMine: true);
    notifyListeners();
  }

  void resetFilter() {
    _filter = const IncidentFilter();
    notifyListeners();
  }

  // ---- CRUD --------------------------------------------------------------

  Future<T> _saveWith<T>(Future<T> Function() action) async {
    _saving = true;
    _uploadProgress = null;
    notifyListeners();
    try {
      return await action();
    } finally {
      _saving = false;
      _uploadProgress = null;
      notifyListeners();
    }
  }

  void _onProgress(double p) {
    _uploadProgress = p;
    notifyListeners();
  }

  Future<Incident> submit(IncidentDraft draft, {File? photo}) {
    final user = _requireUser();
    return _saveWith(
      () => _repo.create(reporter: user, draft: draft, photo: photo, onUploadProgress: _onProgress),
    );
  }

  Future<void> edit(Incident incident, IncidentDraft draft, {File? newPhoto, bool removePhoto = false}) {
    _requireOwnerOfEditable(incident);
    return _saveWith(
      () => _repo.updateDetails(
        incident: incident,
        draft: draft,
        newPhoto: newPhoto,
        removePhoto: removePhoto,
        onUploadProgress: _onProgress,
      ),
    );
  }

  Future<void> delete(Incident incident) {
    _requireOwnerOfEditable(incident);
    return _saveWith(() => _repo.delete(incident));
  }

  /// Staff only. Also checked by Firestore security rules.
  Future<void> updateStatus(Incident incident, IncidentStatus status, String? note) {
    final user = _requireUser();
    if (!user.isStaff) {
      throw StateError('Only staff can change a report’s status.');
    }
    return _saveWith(() => _repo.updateStatus(incident: incident, status: status, staff: user, note: note));
  }

  AppUser _requireUser() {
    final u = _user;
    if (u == null) throw StateError('You are signed out.');
    return u;
  }

  void _requireOwnerOfEditable(Incident i) {
    final u = _requireUser();
    if (!i.isOwnedBy(u.uid)) throw StateError('You can only change your own reports.');
    if (!i.isEditable) {
      throw StateError('This report is already being handled and can’t be changed.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
