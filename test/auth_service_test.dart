import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/services/auth_service.dart';
import 'package:vms_frontend/services/vehicle_api_client.dart';

void main() {
  group('AuthService Corporate Session Management', () {
    test('Initial state is unauthenticated without session', () {
      final authService = AuthService();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.isLoading, isFalse);
      expect(authService.errorMessage, isNull);
      expect(authService.token, isNull);
    });

    test('Validates empty email and password gracefully', () async {
      final authService = AuthService();

      final emptyEmailSuccess = await authService.login(email: '', password: 'password123');
      expect(emptyEmailSuccess, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.errorMessage, contains('email is required'));

      final emptyPasswordSuccess = await authService.login(email: 'user@starkgroup.com', password: '');
      expect(emptyPasswordSuccess, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.errorMessage, contains('password is required'));
    });

    test('Rejects non-corporate or invalid credentials with user-friendly error', () async {
      final authService = AuthService();

      final result = await authService.login(
        email: 'hacker@external.com',
        password: 'wrongpassword',
      );

      expect(result, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.errorMessage, contains('Invalid corporate credentials'));
    });

    test('Authenticates Stark demo credentials successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response(jsonEncode({'status': 'UP', 'databaseConnected': true}), 200, headers: {
            'content-type': 'application/json',
          });
        }
        return http.Response('Not found', 404);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final authService = AuthService(apiClient: apiClient);

      final result = await authService.login(
        email: 'admin@starkgroup.com',
        password: 'stark123',
      );

      expect(result, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.name, equals('Tony Stark'));
      expect(authService.currentUser!.role, equals('Fleet Director'));
      expect(authService.token, isNotNull);
      expect(authService.backendReachable, isTrue);
      expect(authService.errorMessage, isNull);
    });

    test('Authenticates general corporate employee credentials', () async {
      final authService = AuthService();

      final result = await authService.login(
        email: 'pepper.potts@starkgroup.com',
        password: 'secureAccess2026',
      );

      expect(result, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser!.name, equals('Pepper Potts'));
      expect(authService.currentUser!.role, equals('Fleet Administrator'));
      expect(authService.token, isNotNull);
    });

    test('logout clears user, session token, and resets error message', () async {
      final authService = AuthService();

      await authService.login(
        email: 'admin@starkgroup.com',
        password: 'stark123',
      );
      expect(authService.isAuthenticated, isTrue);

      authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.token, isNull);
      expect(authService.errorMessage, isNull);
    });
  });
}

