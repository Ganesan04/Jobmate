import 'package:flutter/foundation.dart';

import '../models/enums.dart';

/// Which tab is active inside each role's bottom-navigation shell.
class NavigationState extends ChangeNotifier {
  int _workerIndex = 0;
  int _giverIndex = 0;

  int get workerIndex => _workerIndex;
  int get giverIndex => _giverIndex;

  int indexFor(UserRole role) =>
      role == UserRole.worker ? _workerIndex : _giverIndex;

  void setIndex(UserRole role, int index) {
    if (role == UserRole.worker) {
      if (_workerIndex == index) return;
      _workerIndex = index;
    } else {
      if (_giverIndex == index) return;
      _giverIndex = index;
    }
    notifyListeners();
  }

  /// Returns to the first tab of the shell (used by FABs and "Go to home").
  void resetToHome(UserRole role) => setIndex(role, 0);
}
