import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart';

/// Abstract storage service for persisting authentication cookies and session state
/// across browser page reloads in Flutter Web and native environments.
abstract class SessionStorage {
  void saveSession(String sessionJson);
  String? getSession();
  void clearSession();
  String? getRouteHash();
  void setRouteHash(String route);

  static final SessionStorage instance = createSessionStorage();
}

