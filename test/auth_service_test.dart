import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/services/auth_service.dart';

void main() {
  group('Supabase-backed authentication', () {
    test('starts signed out when no Supabase project is configured', () {
      final auth = AuthService();
      expect(auth.isConfigured, isFalse);
      expect(auth.hasSession, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      auth.dispose();
    });

    test('does not accept fabricated demo credentials without a provider', () async {
      final auth = AuthService();
      final result = await auth.login(email: 'admin@starkgroup.com', password: 'stark123');
      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, contains('not configured'));
      await auth.logout();
      auth.dispose();
    });

    test('validates empty login details before contacting the provider', () async {
      final auth = AuthService();
      expect(await auth.login(email: '', password: 'secret-password'), isFalse);
      expect(auth.errorMessage, 'Enter your email address.');
      expect(await auth.login(email: 'person@example.com', password: ''), isFalse);
      expect(auth.errorMessage, 'Enter your password.');
      auth.dispose();
    });
  });
}
