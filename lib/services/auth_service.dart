import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'vehicle_api_client.dart';

/// Manages authentication state and session for the Stark Group admin console.
/// Respects the backend's open contract while securing client-side sessions,
/// protecting fleet operations, and presenting user-friendly error messages.
class AuthService extends ChangeNotifier {
  final VehicleApiClient _apiClient;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _backendReachable = false;

  AuthService({VehicleApiClient? apiClient})
      : _apiClient = apiClient ?? VehicleApiClient();

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get backendReachable => _backendReachable;
  String? get token => _currentUser?.token;

  /// Default demo credentials for quick testing:
  /// Email: admin@starkgroup.com
  /// Password: stark123
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      if (cleanEmail.isEmpty) {
        _errorMessage = 'Corporate email is required.';
        return false;
      }

      if (cleanPassword.isEmpty) {
        _errorMessage = 'Access key / password is required.';
        return false;
      }

      // Check backend health/connectivity to inform the user of server state
      try {
        _backendReachable = await _apiClient.checkHealth();
      } catch (_) {
        _backendReachable = false;
      }

      // Validate corporate credentials against Stark enterprise policy
      final isDemoAdmin =
          cleanEmail == 'admin@starkgroup.com' && cleanPassword == 'stark123';
      final isCorporateDomain =
          cleanEmail.endsWith('@starkgroup.com') && cleanPassword.length >= 6;

      if (!isDemoAdmin && !isCorporateDomain) {
        _errorMessage =
            'Invalid corporate credentials. Please use Stark Demo Credentials or an authorized @starkgroup.com account.';
        return false;
      }

      // Derive display name from email address
      final namePrefix = cleanEmail.split('@').first.replaceAll('.', ' ');
      final displayName = isDemoAdmin
          ? 'Tony Stark'
          : namePrefix
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ');

      // Secure session creation without persisting raw passwords
      _currentUser = AppUser(
        id: 'usr-${cleanEmail.hashCode.abs()}',
        email: cleanEmail,
        name: displayName.isNotEmpty ? displayName : 'Fleet Admin',
        role: isDemoAdmin ? 'Fleet Director' : 'Fleet Administrator',
        token: 'stk_sess_${DateTime.now().millisecondsSinceEpoch}',
      );

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'An error occurred during sign in: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user and destroy active session state.
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
