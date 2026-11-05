import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repo);

  final NotificationRepository _repo;
  StreamSubscription<List<AppNotification>>? _sub;
  String? _uid;
  List<AppNotification> _items = [];
  bool _loading = false;

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  int get unreadCount => _items.where((n) => !n.read).length;

  void updateUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _items = [];
    if (uid == null) {
      _loading = false;
      // updateUser runs inside the proxy provider's build; defer the notify.
      scheduleMicrotask(notifyListeners);
      return;
    }
    _loading = true;
    _sub = _repo
        .watchFor(uid)
        .listen(
          (list) {
            _items = list;
            _loading = false;
            notifyListeners();
          },
          onError: (_) {
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<void> markRead(AppNotification n) async {
    if (!n.read) await _repo.markRead(n.id);
  }

  Future<void> markAllRead() => _repo.markAllRead(_items);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
