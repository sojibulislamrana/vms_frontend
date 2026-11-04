import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/models/vehicle.dart';
import 'package:vms_frontend/services/api_exception.dart';
import 'package:vms_frontend/services/auth_service.dart';
import 'package:vms_frontend/services/vehicle_api_client.dart';
import 'package:vms_frontend/services/vehicle_service.dart';

void main() {
  group('VehicleService with REST API Client', () {
    final sampleJsonList = [
      {
        'id': 1,
        'vehicleNumber': 'STK-1001',
        'company': 'Stark Logistics',
        'type': 'Electric',
        'brand': 'Audi',
        'model': 'e-tron GT',
        'status': 'Active',
      },
      {
        'id': 2,
        'vehicleNumber': 'STK-1002',
        'company': 'Stark Security',
        'type': 'SUV',
        'brand': 'Tesla',
        'model': 'Model X Plaid',
        'status': 'Maintenance',
      },
      {
        'id': 3,
        'vehicleNumber': 'STK-1003',
        'company': 'Stark Industries',
        'type': 'Sedan',
        'brand': 'Mercedes-Benz',
        'model': 'EQS 580',
        'status': 'Inactive',
      },
    ];

    test('fetchVehicles loads vehicle catalog and updates metric counters', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/vehicles') && request.method == 'GET') {
          return http.Response(jsonEncode(sampleJsonList), 200, headers: {
            'content-type': 'application/json; charset=utf-8',
          });
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      expect(service.vehicles.isEmpty, isTrue);
      expect(service.isLoading, isFalse);

      await service.fetchVehicles();

      expect(service.isLoading, isFalse);
      expect(service.hasError, isFalse);
      expect(service.isBackendConnected, isTrue);
      expect(service.totalCount, equals(3));
      expect(service.activeCount, equals(1));
      expect(service.maintenanceCount, equals(1));
      expect(service.inactiveCount, equals(1));
      expect(service.vehicles.first.vehicleNumber, equals('STK-1001'));
    });

    test('fetchVehicles handles network/server errors gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 500,
            'error': 'Internal Server Error',
            'message': 'Database connection pool exhausted',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      await service.fetchVehicles();

      expect(service.hasError, isTrue);
      expect(service.isBackendConnected, isFalse);
      expect(service.errorMessage, contains('Database connection pool exhausted'));
      expect(service.vehicles.isEmpty, isTrue);
    });

    test('addVehicle successfully creates record and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 101,
              'vehicleNumber': body['vehicleNumber'],
              'company': body['company'],
              'type': body['type'],
              'brand': body['brand'],
              'model': body['model'],
              'status': body['status'],
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Bad request', 400);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      final newVehicle = const Vehicle(
        id: '',
        vehicleNumber: 'STK-9000',
        company: 'Stark Logistics',
        type: VehicleType.truck,
        brand: 'Rivian',
        model: 'R1T Commercial',
        status: VehicleStatus.active,
      );

      final created = await service.addVehicle(newVehicle);

      expect(created.id, equals('101'));
      expect(created.vehicleNumber, equals('STK-9000'));
      expect(service.totalCount, equals(1));
      expect(service.vehicles.first.id, equals('101'));
    });

    test('addVehicle propagates 409 Conflict for duplicate vehicleNumber', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 409,
            'error': 'Conflict',
            'message': "Vehicle with number 'STK-DUPLICATE' already exists",
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      final duplicateVehicle = const Vehicle(
        id: '',
        vehicleNumber: 'STK-DUPLICATE',
        company: 'Stark Logistics',
        type: VehicleType.sedan,
        brand: 'Audi',
        model: 'A6',
        status: VehicleStatus.active,
      );

      expect(
        () => service.addVehicle(duplicateVehicle),
        throwsA(isA<ApiException>().having(
          (e) => e.isDuplicate,
          'isDuplicate',
          isTrue,
        )),
      );
    });

    test('updateVehicle updates local cached record upon successful PUT', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(sampleJsonList), 200, headers: {'content-type': 'application/json'});
        }
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 1,
              'vehicleNumber': body['vehicleNumber'],
              'company': body['company'],
              'type': body['type'],
              'brand': body['brand'],
              'model': body['model'],
              'status': body['status'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Bad request', 400);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);
      await service.fetchVehicles();

      final target = service.vehicles.first;
      final updated = target.copyWith(
        company: 'Stark Security',
        status: VehicleStatus.maintenance,
      );

      final result = await service.updateVehicle(updated);

      expect(result.company, equals('Stark Security'));
      expect(result.status, equals(VehicleStatus.maintenance));
      expect(service.getById('1')?.company, equals('Stark Security'));
    });

    test('deleteVehicle removes vehicle from local state upon successful DELETE', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(sampleJsonList), 200, headers: {'content-type': 'application/json'});
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('Bad request', 400);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);
      await service.fetchVehicles();

      expect(service.totalCount, equals(3));
      await service.deleteVehicle('1');

      expect(service.totalCount, equals(2));
      expect(service.getById('1'), isNull);
    });

    test('filterVehicles filters in-memory cache accurately', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleJsonList), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);
      await service.fetchVehicles();

      final audiVehicles = service.filterVehicles(query: 'Audi');
      expect(audiVehicles.length, equals(1));
      expect(audiVehicles.first.brand, equals('Audi'));

      final activeOnly = service.filterVehicles(status: VehicleStatus.active);
      expect(activeOnly.length, equals(1));
      expect(activeOnly.first.vehicleNumber, equals('STK-1001'));

      final suvOnly = service.filterVehicles(type: VehicleType.suv);
      expect(suvOnly.length, equals(1));
      expect(suvOnly.first.model, equals('Model X Plaid'));

      final logisticsOnly = service.filterVehicles(company: 'Stark Logistics');
      expect(logisticsOnly.length, equals(1));
      expect(logisticsOnly.first.company, equals('Stark Logistics'));
    });

    test('Protects vehicle operations when user is not authenticated', () async {
      final authService = AuthService();
      expect(authService.isAuthenticated, isFalse);

      final service = VehicleService(authService: authService);

      expect(
        () => service.fetchVehicles(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      final testVehicle = const Vehicle(
        id: '',
        vehicleNumber: 'STK-0001',
        company: 'Stark Logistics',
        type: VehicleType.sedan,
        brand: 'Audi',
        model: 'A6',
        status: VehicleStatus.active,
      );

      expect(
        () => service.addVehicle(testVehicle),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(
        () => service.updateVehicle(testVehicle),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(
        () => service.deleteVehicle('1'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('clearCache empties local state on session logout', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleJsonList), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final service = VehicleService(apiClient: apiClient);
      await service.fetchVehicles();

      expect(service.vehicles.length, equals(3));
      service.clearCache();
      expect(service.vehicles.isEmpty, isTrue);
      expect(service.isBackendConnected, isFalse);
    });
  });
}