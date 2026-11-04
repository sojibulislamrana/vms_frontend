import 'package:flutter/foundation.dart';
import '../data/mock_vehicles.dart';
import '../models/vehicle.dart';

/// In-memory reactive service for vehicle data management.
/// Manages vehicle list with mock data and provides reactive fleet metrics.
class VehicleService extends ChangeNotifier {
  final List<Vehicle> _vehicles = List.from(initialMockVehicles);

  /// Unmodifiable view of all vehicles.
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  // Fleet summary metrics
  int get totalCount => _vehicles.length;
  int get activeCount =>
      _vehicles.where((v) => v.status == VehicleStatus.active).length;
  int get maintenanceCount =>
      _vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
  int get inactiveCount =>
      _vehicles.where((v) => v.status == VehicleStatus.inactive).length;

  /// Find vehicle by unique identifier.
  Vehicle? getById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Register a new vehicle in the fleet.
  void addVehicle(Vehicle vehicle) {
    _vehicles.insert(0, vehicle);
    notifyListeners();
  }

  /// Update an existing vehicle's attributes.
  void updateVehicle(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  /// Remove a vehicle from the fleet.
  void deleteVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  /// Filter and search vehicles by query, status, vehicle type, and company.
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
      final matchesCompany = company == null || company.isEmpty || v.company == company;

      return matchesQuery && matchesStatus && matchesType && matchesCompany;
    }).toList();
  }
}
