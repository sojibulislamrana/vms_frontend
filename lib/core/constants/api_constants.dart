/// Configuration constants for backend REST API connectivity.
/// Allows setting custom base URL via dart-define for development and production:
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
class ApiConstants {
  ApiConstants._();

  /// Base URL of the Spring Boot backend server.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// REST endpoint for Vehicle management CRUD.
  static const String vehiclesEndpoint = '$baseUrl/api/v1/vehicles';

  /// Endpoint for server and database connectivity health checks.
  static const String healthEndpoint = '$baseUrl/api/health';

  /// HTTP request timeout duration.
  static const Duration requestTimeout = Duration(seconds: 10);
}

