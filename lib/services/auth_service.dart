import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';

/// Authentication adapter for Supabase Auth. Passwords never pass through VMS.
class AuthService extends ChangeNotifier {
  AuthService({SupabaseClient? client}) : _client = client {
    if (client != null) {
      _currentUser = _mapUser(client.auth.currentUser);
      _authSubscription = client.auth.onAuthStateChange.listen((event) {
        _currentUser = _mapUser(event.session?.user);
        _errorMessage = null;
        _workspaceId = null;
        if (event.session != null) unawaited(loadWorkspace());
        notifyListeners();
      });
      if (client.auth.currentSession != null) unawaited(loadWorkspace());
    }
  }

  final SupabaseClient? _client;
  final http.Client _httpClient = http.Client();
  StreamSubscription<AuthState>? _authSubscription;
  AppUser? _currentUser;
  String? _workspaceId;
  String _subscriptionStatus = 'starter';
  bool _isWorkspaceLoading = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get isConfigured => _client != null;
  bool get hasSession => _client?.auth.currentSession != null;
  bool get isAuthenticated => hasSession && _workspaceId != null;
  String? get workspaceId => _workspaceId;
  String get subscriptionStatus => _subscriptionStatus;
  bool get isWorkspaceLoading => _isWorkspaceLoading;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  AppUser? get currentUser => _currentUser;
  String? get token => _client?.auth.currentSession?.accessToken;

  Future<bool> login({required String email, required String password}) async {
    return _run(() async {
      if (email.trim().isEmpty) throw const AuthException('Enter your email address.');
      if (password.isEmpty) throw const AuthException('Enter your password.');
      await _requireClient().auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await loadWorkspace();
      return true;
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _run(() async {
      if (name.trim().isEmpty) throw const AuthException('Enter your name.');
      if (email.trim().isEmpty || !email.contains('@')) throw const AuthException('Enter a valid email address.');
      if (password.length < 8) throw const AuthException('Use at least 8 characters for your password.');
      final response = await _requireClient().auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );
      if (response.session == null) {
        _infoMessage = 'Check your inbox to verify your email, then come back to sign in.';
        return false;
      }
      await loadWorkspace();
      return true;
    });
  }

  Future<bool> signInWithGoogle() async {
    return _run(() async {
      try {
        await _requireClient().auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : null,
        );
      } on AuthException catch (error) {
        final message = error.message.toLowerCase();
        if (message.contains('provider is not enabled') ||
            message.contains('unsupported provider')) {
          throw const AuthException(
            'Google sign-in needs to be enabled in Supabase Authentication → Sign In / Providers with a Google OAuth client.',
          );
        }
        rethrow;
      }
      // The browser navigates to Google and returns through Supabase Auth.
      return true;
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _run(() async {
      await _requireClient().auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? '${Uri.base.origin}/?mode=reset-password' : null,
      );
      _infoMessage = 'Password reset instructions are on their way if this address is registered.';
      return true;
    });
  }

  Future<bool> updatePassword(String password) async {
    return _run(() async {
      if (password.length < 8) throw const AuthException('Use at least 8 characters for your password.');
      await _requireClient().auth.updateUser(UserAttributes(password: password));
      _infoMessage = 'Your password has been updated.';
      return true;
    });
  }

  Future<void> loadWorkspace() async {
    final token = _client?.auth.currentSession?.accessToken;
    if (token == null) return;
    _isWorkspaceLoading = true;
    notifyListeners();
    try {
      final response = await _httpClient.get(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/workspaces/current'),
        headers: _sessionHeaders(token),
      ).timeout(ApiConstants.requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _workspaceId = data['id']?.toString();
        _subscriptionStatus = data['subscriptionStatus']?.toString() ?? 'starter';
        _errorMessage = null;
      } else if (response.statusCode != 404) {
        _errorMessage = _apiError(response.body, response.statusCode);
      }
    } catch (_) {
      _errorMessage = 'Could not reach your workspace service. Check that the VMS API is running.';
    } finally {
      _isWorkspaceLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createWorkspace(String name) async {
    return _run(() async {
      final token = _client?.auth.currentSession?.accessToken;
      if (token == null) throw const AuthException('Sign in again to create a workspace.');
      final response = await _httpClient.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/workspaces'),
        headers: _sessionHeaders(token),
        body: jsonEncode({'name': name.trim()}),
      ).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw AuthException(_apiError(response.body, response.statusCode));
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _workspaceId = data['id']?.toString();
      _subscriptionStatus = data['subscriptionStatus']?.toString() ?? 'starter';
      if (_workspaceId == null) throw const AuthException('Workspace was created, but its ID was missing.');
      return true;
    });
  }

  Map<String, String> _sessionHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String _apiError(String body, int status) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message']?.toString() ?? data['error']?.toString() ?? 'Request failed ($status).';
    } catch (_) {
      return 'Request failed ($status).';
    }
  }

  Future<void> logout() async {
    await _client?.auth.signOut();
    _currentUser = null;
    _workspaceId = null;
    notifyListeners();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthException(
        'Authentication is not configured. Add the Supabase project URL and publishable key to the local run configuration.',
      );
    }
    return client;
  }

  Future<bool> _run(Future<bool> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final identities = user.appMetadata['provider']?.toString() ?? 'email';
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: metadata['full_name']?.toString() ??
          metadata['name']?.toString() ??
          (user.email?.split('@').first ?? 'Fleet manager'),
      role: 'Workspace owner',
      token: _client?.auth.currentSession?.accessToken,
      avatarUrl: metadata['avatar_url']?.toString(),
      authProvider: identities.toUpperCase(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _httpClient.close();
    super.dispose();
  }

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }
}
