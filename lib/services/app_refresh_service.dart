/// app_refresh_service.dart — Global event bus for cross-provider data refresh.
///
/// When one provider writes data that affects other screens (e.g.
/// PomodoroProvider creates a session that Progress/Calendar need),
/// it calls [triggerRefresh] to notify all listeners to reload.

import 'package:flutter/foundation.dart';

/// Global event bus to notify all providers to refresh data.
/// Used when one provider writes data that other providers need.
class AppRefreshService extends ChangeNotifier {
  static final AppRefreshService _instance = AppRefreshService._();
  factory AppRefreshService() => _instance;
  AppRefreshService._();

  /// Call this after any data change that affects multiple screens.
  void triggerRefresh() {
    notifyListeners();
  }
}
