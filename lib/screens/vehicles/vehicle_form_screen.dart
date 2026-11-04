import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/api_exception.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/vehicle_image.dart';
import '../../widgets/vehicle_status_badge.dart';

/// Redesigned Vehicle Registration & Editing Form following Reference Image 2:
/// Clean field groups, modern inputs with subtle borders, real-time live preview card,
/// clear validation feedback, and professional action buttons.
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

  bool _isSaving = false;
  String? _serverError;

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

    _selectedType = v?.type ?? VehicleType.suv;
    _selectedStatus = v?.status ?? VehicleStatus.active;

    // Listeners to update the live preview dynamically
    _numberController.addListener(() => setState(() {}));
    _brandController.addListener(() => setState(() {}));
    _modelController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numberController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _serverError = null;
    });

    final vehicle = Vehicle(
      id: widget.initialVehicle?.id ?? '',
      vehicleNumber: _numberController.text.trim().toUpperCase(),
      company: _companyController.text.trim(),
      type: _selectedType,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      status: _selectedStatus,
    );

    try {
      if (widget.isEditing) {
        await widget.vehicleService.updateVehicle(vehicle);
      } else {
        await widget.vehicleService.addVehicle(vehicle);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Vehicle "${vehicle.vehicleNumber}" updated successfully.'
              : 'Vehicle "${vehicle.vehicleNumber}" registered in corporate fleet.'),
          backgroundColor: AppTheme.statusActiveGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onSaved();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = 'An unexpected error occurred while persisting vehicle record: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              _buildFormHeader(theme, isDark),

              const SizedBox(height: 24),

              // Server Error Alert Banner
              if (_serverError != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFDC2626), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Validation / API Conflict',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serverError!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Two-Column Layout (Form Fields + Live Preview Card)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left 65%: Form Fields Groups
                    Expanded(
                      flex: 65,
                      child: _buildFormCard(theme, isDark),
                    ),
                    const SizedBox(width: 24),

                    // Right 35%: Live Visual Preview Card
                    Expanded(
                      flex: 35,
                      child: _buildLivePreviewCard(theme, isDark),
                    ),
                  ],
                )
              else ...[
                _buildLivePreviewCard(theme, isDark),
                const SizedBox(height: 20),
                _buildFormCard(theme, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Top Form Header
  Widget _buildFormHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to Directory',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isEditing ? 'Edit Vehicle Asset' : 'Register New Vehicle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.slateNavy,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.isEditing
                  ? 'Update operational specs and allocation details for vehicle record ${widget.initialVehicle?.vehicleNumber}.'
                  : 'Add a new vehicle to the Stark Group corporate fleet inventory.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Form Container with Field Groups
  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Identification
            _buildSectionHeader('1. Vehicle Identification', Icons.tag_rounded),
            const SizedBox(height: 16),

            // Vehicle Number Field
            Text(
              'Vehicle Plate / Registration Number *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.slateNavy,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _numberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. STK-8821',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vehicle registration number is required';
                }
                if (val.trim().length < 3) {
                  return 'Vehicle number must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Company Entity Dropdown
            Text(
              'Assigned Corporate Subsidiary *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.slateNavy,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: AppConstants.defaultCompanies.contains(_companyController.text)
                  ? _companyController.text
                  : AppConstants.defaultCompanies.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.business_outlined),
              ),
              items: AppConstants.defaultCompanies.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _companyController.text = val);
                }
              },
            ),
            const SizedBox(height: 28),

            // Section 2: Classification & Status
            _buildSectionHeader('2. Classification & Operational Status', Icons.tune_rounded),
            const SizedBox(height: 16),

            Row(
              children: [
                // Vehicle Type Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Type *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.slateNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<VehicleType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: VehicleType.values.map(
                          (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle Status Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Status *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.slateNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<VehicleStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.sensors_rounded),
                        ),
                        items: VehicleStatus.values.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Section 3: Technical Specifications
            _buildSectionHeader('3. Technical Specifications', Icons.directions_car_outlined),
            const SizedBox(height: 16),

            Row(
              children: [
                // Brand Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manufacturer Brand *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.slateNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Tesla, Audi, Ford',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Brand is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Model Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Name *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.slateNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Model X, F-150',
                          prefixIcon: Icon(Icons.directions_car_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Model is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Form Actions (Submit & Cancel)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    widget.isEditing ? 'Save Changes' : 'Register Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Live Interactive Preview Card
  Widget _buildLivePreviewCard(ThemeData theme, bool isDark) {
    final plate = _numberController.text.trim().isEmpty
        ? 'STK-0000'
        : _numberController.text.trim().toUpperCase();
    final brand = _brandController.text.trim().isEmpty ? 'Brand' : _brandController.text.trim();
    final model = _modelController.text.trim().isEmpty ? 'Model' : _modelController.text.trim();
    final company = _companyController.text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE CARD PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Live Sync', style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                VehicleImage(
                  type: _selectedType,
                  brand: brand,
                  model: model,
                  height: 140,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: VehicleStatusBadge(status: _selectedStatus),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            '$brand $model',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$company • ${_selectedType.label}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Record will be verified and stored in PostgreSQL.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
