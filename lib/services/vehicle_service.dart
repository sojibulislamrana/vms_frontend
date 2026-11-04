import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'vehicle_api_client.dart';

/// Reactive service managing fleet vehicle state via the Spring Boot REST API.
/// Widgets interact exclusively with this service and remain completely free of HTTP code.
class VehicleService extends ChangeNotifier {
  final VehicleApiClient _apiClient;
  final AuthService? authService;

  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBackendConnected = false;

  VehicleService({
    VehicleApiClient? apiClient,
    this.authService,
  }) : _apiClient = apiClient ?? VehicleApiClient();

  /// Unmodifiable view of currently loaded vehicles.
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isBackendConnected => _isBackendConnected;

  // Fleet summary metrics calculated from real data
  int get totalCount => _vehicles.length;
  int get activeCount =>
      _vehicles.where((v) => v.status == VehicleStatus.active).length;
  int get maintenanceCount =>
      _vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
  int get inactiveCount =>
      _vehicles.where((v) => v.status == VehicleStatus.inactive).length;

  void _assertAuthenticated() {
    if (authService != null && !authService!.isAuthenticated) {
      throw const ApiException(
        'Unauthorized: Active corporate session required.',
        statusCode: 401,
      );
    }
  }

  /// Reset in-memory cached fleet records when session terminates.
  void clearCache() {
    _vehicles = [];
    _errorMessage = null;
    _isBackendConnected = false;
    notifyListeners();
  }

  /// Fetch vehicle catalog from the Spring Boot REST API.
  Future<void> fetchVehicles() async {
    _assertAuthenticated();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _apiClient.getVehicles();
      _vehicles = fetched;
      _isBackendConnected = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _isBackendConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new vehicle via POST /api/v1/vehicles.
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    _assertAuthenticated();
    try {
      final created = await _apiClient.createVehicle(vehicle);
      _vehicles.insert(0, created);
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      // Re-throw so callers (e.g. Form UI) can display specific error feedback
      rethrow;
    }
  }

  /// Update an existing vehicle via PUT /api/v1/vehicles/{id}.
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    _assertAuthenticated();
    try {
      final updated = await _apiClient.updateVehicle(vehicle.id, vehicle);
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = updated;
      }
      _errorMessage = null;
      notifyListeners();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a vehicle via DELETE /api/v1/vehicles/{id}.
  Future<void> deleteVehicle(String id) async {
    _assertAuthenticated();
    try {
      await _apiClient.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Locate a vehicle in the current local cache.
  Vehicle? getById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search and filter vehicles currently loaded in memory.
  List<Vehicle> filterVehicles({
    String query = '',
    VehicleStatus? status,
    VehicleType? type,
    String? company,
  }) {
    final trimmedQuery = query.trim().toLowerCase();

    return _vehicles.where((v) {
      final matchesQuery = trimmedQuery.isEmpty ||
          v.vehicleNumber.toLowerCase().contains(trimmedQuery) ||
          v.company.toLowerCase().contains(trimmedQuery) ||
          v.brand.toLowerCase().contains(trimmedQuery) ||
          v.model.toLowerCase().contains(trimmedQuery);

      final matchesStatus = status == null || v.status == status;
      final matchesType = type == null || v.type == type;
      final matchesCompany =
          company == null || company.isEmpty || v.company == company;

      return matchesQuery && matchesStatus && matchesType && matchesCompany;
    }).toList();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }
}
