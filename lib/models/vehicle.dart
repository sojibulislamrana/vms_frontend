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
/// Maps 1:1 to the Spring Boot REST API VehicleResponse and VehicleRequest DTOs.
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

  /// Request body payload sent to Spring Boot (VehicleRequest DTO).
  Map<String, dynamic> toRequestBody() {
    return {
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.label,
      'brand': brand,
      'model': model,
      'status': status.label,
    };
  }

  /// Full serialization map for persistence / serialization.
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.label,
      'brand': brand,
      'model': model,
      'status': status.label,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Deserialization helper from backend JSON response (VehicleResponse DTO).
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] != null ? json['id'].toString() : '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      company: json['company'] as String? ?? '',
      type: VehicleType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
                (json['type']?.toString().toLowerCase() ?? '') ||
            e.label.toLowerCase() ==
                (json['type']?.toString().toLowerCase() ?? ''),
        orElse: () => VehicleType.sedan,
      ),
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      status: VehicleStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
                (json['status']?.toString().toLowerCase() ?? '') ||
            e.label.toLowerCase() ==
                (json['status']?.toString().toLowerCase() ?? ''),
        orElse: () => VehicleStatus.active,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
