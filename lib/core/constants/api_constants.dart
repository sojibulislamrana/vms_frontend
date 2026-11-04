/// Configuration constants for backend REST API connectivity.
/// Allows setting custom base URL via dart-define for development and production:
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
class ApiConstants {
  ApiConstants._();

  /// Raw base URL of the Spring Boot backend server.
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Normalized base URL of the Spring Boot backend server without trailing slash.
  static String get baseUrl {
    final trimmed = _rawBaseUrl.trim();
    if (trimmed.isEmpty) {
      return 'http://localhost:8080';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// REST endpoint for Vehicle management CRUD.
  static String get vehiclesEndpoint => '$baseUrl/api/v1/vehicles';

  /// Endpoint for server and database connectivity health checks.
  static String get healthEndpoint => '$baseUrl/api/health';

  /// HTTP request timeout duration.
  static const Duration requestTimeout = Duration(seconds: 10);
}

