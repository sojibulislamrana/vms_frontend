import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/vehicle.dart';
import 'api_exception.dart';

/// HTTP Client that directly interacts with the Spring Boot REST API.
/// Encapsulates all raw network operations, URL handling, and response deserialization.
class VehicleApiClient {
  final http.Client _client;
  final String? Function()? tokenProvider;

  VehicleApiClient({
    http.Client? client,
    this.tokenProvider,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Fetch all vehicles from the backend: GET /api/v1/vehicles
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConstants.vehiclesEndpoint), headers: _headers)
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw _handleError(response);
    } on TimeoutException {
      throw const ApiException('Network request timed out. Please try again.');
    } on http.ClientException {
      throw _networkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _networkException();
    }
  }

  /// Fetch single vehicle by ID: GET /api/v1/vehicles/{id}
  Future<Vehicle> getVehicleById(String id) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConstants.vehiclesEndpoint}/$id'), headers: _headers)
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }

      throw _handleError(response);
    } on TimeoutException {
      throw const ApiException('Network request timed out. Please try again.');
    } on http.ClientException {
      throw _networkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _networkException();
    }
  }

  /// Create a new vehicle: POST /api/v1/vehicles
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.vehiclesEndpoint),
            headers: _headers,
            body: jsonEncode(vehicle.toRequestBody()),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }

      throw _handleError(response);
    } on TimeoutException {
      throw const ApiException('Network request timed out. Please try again.');
    } on http.ClientException {
      throw _networkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _networkException();
    }
  }

  /// Update an existing vehicle: PUT /api/v1/vehicles/{id}
  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${ApiConstants.vehiclesEndpoint}/$id'),
            headers: _headers,
            body: jsonEncode(vehicle.toRequestBody()),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }

      throw _handleError(response);
    } on TimeoutException {
      throw const ApiException('Network request timed out. Please try again.');
    } on http.ClientException {
      throw _networkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _networkException();
    }
  }

  /// Delete vehicle by ID: DELETE /api/v1/vehicles/{id}
  Future<void> deleteVehicle(String id) async {
    try {
      final response = await _client
          .delete(Uri.parse('${ApiConstants.vehiclesEndpoint}/$id'), headers: _headers)
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }

      throw _handleError(response);
    } on TimeoutException {
      throw const ApiException('Network request timed out. Please try again.');
    } on http.ClientException {
      throw _networkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _networkException();
    }
  }

  /// Check connectivity against the Spring Boot health check: GET /api/health
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConstants.healthEndpoint), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] == 'UP' && data['databaseConnected'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Convert backend error payload into an ApiException
  ApiException _handleError(http.Response response) {
    try {
      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] as String? ??
          body['error'] as String? ??
          'Request failed with status ${response.statusCode}';

      Map<String, String>? validationErrors;
      if (body['validationErrors'] is Map) {
        validationErrors = (body['validationErrors'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }

      return ApiException(
        message,
        statusCode: response.statusCode,
        validationErrors: validationErrors,
      );
    } catch (_) {
      return ApiException(
        'Request failed with status code ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  ApiException _networkException() {
    return ApiException(
      'Unable to connect to the backend server. Please verify Spring Boot is running at ${ApiConstants.baseUrl}.',
      statusCode: 0,
    );
  }

  void close() {
    _client.close();
  }
}
