import 'package:flutter/foundation.dart';

/// Which bottom-nav tab is showing. Kept in a provider (not setState) so
/// other screens can switch tabs, e.g. Home's "View all" jumps to Reports.
class ShellProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void goTo(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void reset() => _index = 0;
}

/// Tab indexes, shared by both shells.
class Tabs {
  static const home = 0; // Dashboard for staff
  static const reports = 1;
  static const profile = 2;
}
