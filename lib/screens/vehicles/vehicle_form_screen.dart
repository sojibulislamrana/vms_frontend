import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/responsive_layout.dart';

/// Screen for registering a new fleet vehicle or updating an existing vehicle's record.
/// Employs clear field grouping, accessible labels, robust validation, and Stark Group styling.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? initialVehicle;
  final VehicleService vehicleService;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const VehicleFormScreen({
    super.key,
    this.initialVehicle,
    required this.vehicleService,
    required this.onSaved,
    required this.onCancel,
  });

  bool get isEditing => initialVehicle != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _companyController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;

  late VehicleType _selectedType;
  late VehicleStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;

    _numberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _companyController = TextEditingController(
      text: v?.company ?? AppConstants.defaultCompanies.first,
    );
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');

    _selectedType = v?.type ?? VehicleType.sedan;
    _selectedStatus = v?.status ?? VehicleStatus.active;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    if (!_formKey.currentState!.validate()) return;

    final vehicleNumber = _numberController.text.trim().toUpperCase();
    final company = _companyController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    if (widget.isEditing) {
      final updated = widget.initialVehicle!.copyWith(
        vehicleNumber: vehicleNumber,
        company: company,
        type: _selectedType,
        brand: brand,
        model: model,
        status: _selectedStatus,
      );
      widget.vehicleService.updateVehicle(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle "$vehicleNumber" updated successfully.'),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final newVehicle = Vehicle(
        id: 'veh-${DateTime.now().millisecondsSinceEpoch % 100000}',
        vehicleNumber: vehicleNumber,
        company: company,
        type: _selectedType,
        brand: brand,
        model: model,
        status: _selectedStatus,
        updatedAt: DateTime.now(),
      );
      widget.vehicleService.addVehicle(newVehicle);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Vehicle "$vehicleNumber" was registered to the fleet.'),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Breadcrumb & Action Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back to fleet directory',
                      onPressed: widget.onCancel,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Edit Vehicle Record'
                                : 'Register New Fleet Asset',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isEditing
                                ? 'Updating specifications for ${widget.initialVehicle!.vehicleNumber} (${widget.initialVehicle!.displayName})'
                                : 'Enter identification, specifications, and organizational allocation.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // GROUP 1: Identification & Company Assignment
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_rounded,
                                      size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Fleet Identification & Company Assignment',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Unique fleet code and operating division.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildVehicleNumberField()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildCompanyField()),
                                  ],
                                )
                              else ...[
                                _buildVehicleNumberField(),
                                const SizedBox(height: 16),
                                _buildCompanyField(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // GROUP 2: Vehicle Specifications (Brand, Model, Type)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_car_filled_rounded,
                                      size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Vehicle Specifications',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manufacturer details and vehicle class categorization.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (isDesktop) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildBrandField()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildModelField()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTypeDropdown(),
                              ] else ...[
                                _buildBrandField(),
                                const SizedBox(height: 16),
                                _buildModelField(),
                                const SizedBox(height: 16),
                                _buildTypeDropdown(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // GROUP 3: Operational Status
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.traffic_rounded,
                                      size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Operational Status',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Current readiness level in the active dispatch pool.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildStatusDropdown(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Actions Row (Cancel & Submit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _saveVehicle,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(widget.isEditing
                                ? 'Save Changes'
                                : 'Register Vehicle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller: _numberController,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
      ],
      decoration: const InputDecoration(
        labelText: 'Vehicle Number *',
        hintText: 'e.g. STK-1001',
        prefixIcon: Icon(Icons.tag_rounded, size: 20),
        helperText: 'Unique identifier code (e.g. STK-1001)',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Vehicle number is required';
        }
        if (v.trim().length < 3) {
          return 'Enter a valid identifier (min 3 characters)';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyField() {
    return TextFormField(
      controller: _companyController,
      decoration: const InputDecoration(
        labelText: 'Company *',
        hintText: 'e.g. Stark Logistics',
        prefixIcon: Icon(Icons.apartment_rounded, size: 20),
        helperText: 'Operating branch or company division',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Company assignment is required';
        }
        return null;
      },
    );
  }

  Widget _buildBrandField() {
    return TextFormField(
      controller: _brandController,
      decoration: const InputDecoration(
        labelText: 'Brand *',
        hintText: 'e.g. Audi, Tesla, Ford',
        prefixIcon: Icon(Icons.business_rounded, size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Brand name is required';
        }
        return null;
      },
    );
  }

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,
      decoration: const InputDecoration(
        labelText: 'Model *',
        hintText: 'e.g. e-tron GT, Model X, F-150',
        prefixIcon: Icon(Icons.directions_car_rounded, size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Model name is required';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<VehicleType>(
      initialValue: _selectedType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type *',
        prefixIcon: Icon(Icons.category_rounded, size: 20),
      ),
      items: VehicleType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.label),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedType = val);
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<VehicleStatus>(
      initialValue: _selectedStatus,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Status *',
        prefixIcon: Icon(Icons.traffic_rounded, size: 20),
      ),
      items: VehicleStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.label),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedStatus = val);
      },
    );
  }
}
