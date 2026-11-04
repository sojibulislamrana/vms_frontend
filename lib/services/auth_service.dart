import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Manages authentication state and session for the Stark Group admin console.
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Default demo credentials for quick testing:
  /// Email: admin@starkgroup.com
  /// Password: stark123
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    // Simulate minor network latency
    await Future.delayed(const Duration(milliseconds: 300));

    _isLoading = false;

    // Static frontend authentication check
    if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
      _currentUser = AppUser(
        id: 'usr-001',
        email: email.trim(),
        name: 'Tony Stark',
        role: 'Fleet Director',
      );
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  /// Sign out the current user.
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
