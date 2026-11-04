import 'session_storage.dart';

SessionStorage createSessionStorage() => StubSessionStorage();

/// In-memory storage implementation for non-web environments (tests, VM).
class StubSessionStorage implements SessionStorage {
  String? _session;
  String? _hash;

  @override
  void saveSession(String sessionJson) {
    _session = sessionJson;
  }

  @override
  String? getSession() => _session;

  @override
  void clearSession() {
    _session = null;
  }

  @override
  String? getRouteHash() => _hash;

  @override
  void setRouteHash(String route) {
    _hash = route;
  }
}

