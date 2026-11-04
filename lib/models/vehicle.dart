/// Operational status of a fleet vehicle.
enum VehicleStatus {
  active('Active'),
  maintenance('Maintenance'),
  inactive('Inactive');

  final String label;
  const VehicleStatus(this.label);
}

/// Vehicle categorization.
enum VehicleType {
  sedan('Sedan'),
  suv('SUV'),
  truck('Truck'),
  van('Van'),
  electric('Electric');

  final String label;
  const VehicleType(this.label);
}

/// Domain model representing a vehicle in the fleet.
/// Core fields: Vehicle Number, Company, Type, Brand, Model, and Status.
class Vehicle {
  final String id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String brand;
  final String model;
  final VehicleStatus status;
  final DateTime? updatedAt;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    this.updatedAt,
  });

  /// Formatted full title for UI display (e.g., "Audi e-tron GT").
  String get displayName => '$brand $model';

  /// Create a copy with selected fields modified.
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    VehicleType? type,
    String? brand,
    String? model,
    VehicleStatus? status,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialization helper to easily interface with Spring Boot REST API later.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.name,
      'brand': brand,
      'model': model,
      'status': status.name,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Deserialization helper from JSON map.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      company: json['company'] as String,
      type: VehicleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VehicleType.sedan,
      ),
      brand: json['brand'] as String,
      model: json['model'] as String,
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VehicleStatus.active,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
