import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/models/vehicle.dart';

void main() {
  group('Vehicle Model', () {
    test('computes display name correctly', () {
      final vehicle = Vehicle(
        id: 'v-1',
        vehicleNumber: 'STK-1001',
        company: 'Stark Logistics',
        type: VehicleType.electric,
        brand: 'Audi',
        model: 'e-tron GT',
        status: VehicleStatus.active,
      );

      expect(vehicle.displayName, equals('Audi e-tron GT'));
      expect(vehicle.vehicleNumber, equals('STK-1001'));
      expect(vehicle.company, equals('Stark Logistics'));
    });

    test('serializes to JSON and deserializes back faithfully', () {
      final vehicle = Vehicle(
        id: 'v-2',
        vehicleNumber: 'STK-1002',
        company: 'Stark Security',
        type: VehicleType.suv,
        brand: 'Tesla',
        model: 'Model X Plaid',
        status: VehicleStatus.active,
        updatedAt: DateTime(2026, 11, 2, 12, 0),
      );

      final json = vehicle.toJson();
      final reconstructed = Vehicle.fromJson(json);

      expect(reconstructed.id, equals(vehicle.id));
      expect(reconstructed.vehicleNumber, equals(vehicle.vehicleNumber));
      expect(reconstructed.company, equals(vehicle.company));
      expect(reconstructed.type, equals(vehicle.type));
      expect(reconstructed.brand, equals(vehicle.brand));
      expect(reconstructed.model, equals(vehicle.model));
      expect(reconstructed.status, equals(vehicle.status));
    });
  });
}
