import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/models/vehicle.dart';
import 'package:vms_frontend/services/vehicle_service.dart';

void main() {
  group('VehicleService in-memory operations', () {
    late VehicleService service;

    setUp(() {
      service = VehicleService();
    });

    test('Loads initial mock fleet items', () {
      expect(service.vehicles.isNotEmpty, isTrue);
      expect(service.totalCount, equals(service.vehicles.length));
      expect(service.activeCount, greaterThan(0));
    });

    test('Adds a new vehicle successfully', () {
      final initialCount = service.totalCount;
      final newVehicle = Vehicle(
        id: 'test-001',
        vehicleNumber: 'STK-9999',
        company: 'Stark Logistics',
        type: VehicleType.truck,
        brand: 'Rivian',
        model: 'R1T Commercial',
        status: VehicleStatus.active,
      );

      service.addVehicle(newVehicle);

      expect(service.totalCount, equals(initialCount + 1));
      expect(service.getById('test-001'), isNotNull);
      expect(service.getById('test-001')!.brand, equals('Rivian'));
    });

    test('Updates an existing vehicle', () {
      final target = service.vehicles.first;
      final updated = target.copyWith(
        company: 'Stark Security',
        status: VehicleStatus.maintenance,
      );

      service.updateVehicle(updated);

      final result = service.getById(target.id);
      expect(result?.company, equals('Stark Security'));
      expect(result?.status, equals(VehicleStatus.maintenance));
    });

    test('Deletes a vehicle', () {
      final target = service.vehicles.first;
      final initialCount = service.totalCount;

      service.deleteVehicle(target.id);

      expect(service.totalCount, equals(initialCount - 1));
      expect(service.getById(target.id), isNull);
    });

    test('Filters vehicles by query, status, type, and company', () {
      final results = service.filterVehicles(query: 'Audi');
      expect(results.every((v) => v.brand.contains('Audi') || v.model.contains('Audi')), isTrue);

      final activeOnly = service.filterVehicles(status: VehicleStatus.active);
      expect(activeOnly.every((v) => v.status == VehicleStatus.active), isTrue);

      final electricOnly = service.filterVehicles(type: VehicleType.electric);
      expect(electricOnly.every((v) => v.type == VehicleType.electric), isTrue);

      final logisticsOnly = service.filterVehicles(company: 'Stark Logistics');
      expect(logisticsOnly.every((v) => v.company == 'Stark Logistics'), isTrue);
    });
  });
}
