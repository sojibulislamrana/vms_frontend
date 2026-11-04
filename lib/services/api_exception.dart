/// Custom exception encapsulating REST API errors from the Spring Boot backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String>? validationErrors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.validationErrors,
  });

  bool get isDuplicate => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400;

  @override
  String toString() => message;
}

