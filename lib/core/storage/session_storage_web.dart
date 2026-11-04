import 'package:web/web.dart' as web;
import 'session_storage.dart';

SessionStorage createSessionStorage() => WebSessionStorage();

/// Production browser storage implementation utilizing document.cookie and localStorage.
class WebSessionStorage implements SessionStorage {
  @override
  void saveSession(String sessionJson) {
    try {
      final encoded = Uri.encodeComponent(sessionJson);
      // Persist cookie for 7 days with path=/ and SameSite=Lax
      web.document.cookie = 'vms_auth_session=$encoded; path=/; max-age=604800; SameSite=Lax';
    } catch (_) {}

    try {
      web.window.localStorage.setItem('vms_user_session', sessionJson);
    } catch (_) {}
  }

  @override
  String? getSession() {
    // 1. First priority: read from browser document.cookie
    try {
      final cookieString = web.document.cookie;
      if (cookieString.isNotEmpty) {
        final cookies = cookieString.split(';');
        for (final cookie in cookies) {
          final trimmed = cookie.trim();
          if (trimmed.startsWith('vms_auth_session=')) {
            final val = trimmed.substring('vms_auth_session='.length);
            final decoded = Uri.decodeComponent(val);
            if (decoded.isNotEmpty) return decoded;
          }
        }
      }
    } catch (_) {}

    // 2. Second priority: read from localStorage
    try {
      final stored = web.window.localStorage.getItem('vms_user_session');
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }
    } catch (_) {}

    return null;
  }

  @override
  void clearSession() {
    try {
      web.document.cookie =
          'vms_auth_session=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax';
    } catch (_) {}
    try {
      web.window.localStorage.removeItem('vms_user_session');
    } catch (_) {}
  }

  @override
  String? getRouteHash() {
    try {
      final hash = web.window.location.hash;
      if (hash.isNotEmpty) {
        return hash.replaceFirst(RegExp(r'^#\/?'), '');
      }
      final pathname = web.window.location.pathname;
      if (pathname.isNotEmpty && pathname != '/') {
        return pathname.replaceFirst(RegExp(r'^\/'), '');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void setRouteHash(String route) {
    try {
      final clean = route.startsWith('/') ? route : '/$route';
      web.window.location.hash = clean;
    } catch (_) {}
  }
}
