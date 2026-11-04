import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/vehicle_status_badge.dart';

/// Screen displaying the Stark Group fleet vehicle catalog with high-contrast
/// scanning, highlighted Vehicle Number and Status, multi-dimensional filters,
/// loading, error, empty, and success states.
class VehicleListScreen extends StatefulWidget {
  final VehicleService vehicleService;
  final VoidCallback onAddVehicle;
  final ValueChanged<Vehicle> onEditVehicle;

  const VehicleListScreen({
    super.key,
    required this.vehicleService,
    required this.onAddVehicle,
    required this.onEditVehicle,
  });

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();
  VehicleStatus? _selectedStatus;
  VehicleType? _selectedType;
  String? _selectedCompany;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    // Load initial real vehicle data from Spring Boot REST API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.vehicleService.vehicles.isEmpty) {
        widget.vehicleService.fetchVehicles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedType = null;
      _selectedCompany = null;
    });
  }

  Future<void> _handleDelete(Vehicle vehicle) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Decommission Vehicle Record',
      message:
          'Are you sure you want to delete vehicle "${vehicle.vehicleNumber}" (${vehicle.displayName}) assigned to ${vehicle.company}? This change will be permanently applied to the SQL database.',
      confirmLabel: 'Delete Record',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _deletingId = vehicle.id);
      try {
        await widget.vehicleService.deleteVehicle(vehicle.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vehicle "${vehicle.vehicleNumber}" was deleted from the database.'),
            backgroundColor: Colors.blueGrey.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete vehicle: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _deletingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return ListenableBuilder(
      listenable: widget.vehicleService,
      builder: (context, _) {
        final isLoading = widget.vehicleService.isLoading;
        final hasError = widget.vehicleService.hasError;
        final totalCount = widget.vehicleService.totalCount;
        final activeCount = widget.vehicleService.activeCount;
        final maintenanceCount = widget.vehicleService.maintenanceCount;
        final inactiveCount = widget.vehicleService.inactiveCount;

        final filteredVehicles = widget.vehicleService.filterVehicles(
          query: _searchController.text.trim(),
          status: _selectedStatus,
          type: _selectedType,
          company: _selectedCompany,
        );

        final hasActiveFilters = _searchController.text.isNotEmpty ||
            _selectedStatus != null ||
            _selectedType != null ||
            _selectedCompany != null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section Header & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fleet Directory',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Live operational data connected to Spring Boot backend.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Refresh Button
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh from API',
                              onPressed: isLoading
                                  ? null
                                  : () => widget.vehicleService.fetchVehicles(),
                            ),
                            const SizedBox(width: 8),
                            if (!isMobile)
                              ElevatedButton.icon(
                                onPressed: widget.onAddVehicle,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Register Vehicle'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Executive Metric Cards
                    _buildStatCards(
                      totalCount: totalCount,
                      activeCount: activeCount,
                      maintenanceCount: maintenanceCount,
                      inactiveCount: inactiveCount,
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 24),

                    // Search & Filter Toolbar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Search Input
                                SizedBox(
                                  width: isMobile ? double.infinity : 280,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search number, brand, model...',
                                      prefixIcon: const Icon(Icons.search_rounded,
                                          size: 20),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded,
                                                  size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),

                                // Status Filter
                                SizedBox(
                                  width: isMobile ? double.infinity : 175,
                                  child: DropdownButtonFormField<VehicleStatus?>(
                                    key: ValueKey(_selectedStatus),
                                    initialValue: _selectedStatus,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('All Statuses'),
                                      ),
                                      ...VehicleStatus.values.map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.label),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _selectedStatus = val),
                                  ),
                                ),

                                // Type Filter
                                SizedBox(
                                  width: isMobile ? double.infinity : 170,
                                  child: DropdownButtonFormField<VehicleType?>(
                                    key: ValueKey(_selectedType),
                                    initialValue: _selectedType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('All Types'),
                                      ),
                                      ...VehicleType.values.map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t.label),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _selectedType = val),
                                  ),
                                ),

                                // Company Filter
                                SizedBox(
                                  width: isMobile ? double.infinity : 200,
                                  child: DropdownButtonFormField<String?>(
                                    key: ValueKey(_selectedCompany),
                                    initialValue: _selectedCompany,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Company',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('All Companies'),
                                      ),
                                      ...AppConstants.defaultCompanies.map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _selectedCompany = val),
                                  ),
                                ),

                                // Clear Filters Action
                                if (hasActiveFilters)
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.filter_alt_off_rounded,
                                        size: 16),
                                    label: const Text('Reset'),
                                  ),

                                // Mobile Register Action
                                if (isMobile) ...[
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: widget.onAddVehicle,
                                      icon: const Icon(Icons.add_rounded, size: 20),
                                      label: const Text('Register Vehicle'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content View: Loading, Error, Empty, or Table List
                    if (isLoading && widget.vehicleService.vehicles.isEmpty)
                      _buildLoadingState(theme)
                    else if (hasError && widget.vehicleService.vehicles.isEmpty)
                      _buildErrorState(theme, widget.vehicleService.errorMessage!)
                    else if (filteredVehicles.isEmpty)
                      _buildEmptyState(theme, hasActiveFilters)
                    else if (isMobile)
                      _buildMobileList(filteredVehicles, theme)
                    else
                      _buildDesktopTable(filteredVehicles, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCards({
    required int totalCount,
    required int activeCount,
    required int maintenanceCount,
    required int inactiveCount,
    required bool isDesktop,
  }) {
    final cards = [
      StatCard(
        title: 'Total Fleet',
        value: totalCount.toString(),
        icon: Icons.directions_car_filled_rounded,
        color: const Color(0xFF0F172A),
        subtitle: 'Registered in database',
      ),
      StatCard(
        title: 'Active Fleet',
        value: activeCount.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        subtitle: 'Dispatched & operational',
      ),
      StatCard(
        title: 'Maintenance',
        value: maintenanceCount.toString(),
        icon: Icons.build_circle_rounded,
        color: const Color(0xFFD97706),
        subtitle: 'Inspections & servicing',
      ),
      StatCard(
        title: 'Inactive',
        value: inactiveCount.toString(),
        icon: Icons.pause_circle_filled_rounded,
        color: const Color(0xFF64748B),
        subtitle: 'Reserved or decommissioned',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((c) => SizedBox(
                  width: 280,
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              'Connecting to VMS REST Backend...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Retrieving latest fleet assets from SQL database',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Backend Connection Error',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => widget.vehicleService.fetchVehicles(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Vehicle> vehicles, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1040),
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('VEHICLE NUMBER')),
              DataColumn(label: Text('COMPANY')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('BRAND')),
              DataColumn(label: Text('MODEL')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: vehicles.map((v) {
              return DataRow(
                onSelectChanged: (_) => widget.onEditVehicle(v),
                cells: [
                  // 1. VEHICLE NUMBER (Highlighted Monospace Badge)
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        v.vehicleNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  // 2. COMPANY
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.company,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // 3. TYPE (Icon + Label)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(v.type),
                            size: 18,
                            color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(v.type.label),
                      ],
                    ),
                  ),

                  // 4. BRAND
                  DataCell(
                    Text(
                      v.brand,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  // 5. MODEL
                  DataCell(
                    Text(
                      v.model,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  // 6. STATUS (Highlighted Status Badge)
                  DataCell(
                    VehicleStatusBadge(status: v.status),
                  ),

                  // 7. ACTIONS (Clear Edit and Delete)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Edit Vehicle',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => widget.onEditVehicle(v),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Delete Vehicle',
                          child: _deletingId == v.id
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _handleDelete(v),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Vehicle> vehicles, ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = vehicles[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Highlighted Vehicle Number & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        v.vehicleNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    VehicleStatusBadge(status: v.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Vehicle Brand & Model
                Text(
                  v.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                // Company and Type
                Row(
                  children: [
                    Icon(Icons.apartment_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      v.company,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(_getTypeIcon(v.type),
                        size: 14, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      v.type.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => widget.onEditVehicle(v),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    _deletingId == v.id
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: theme.colorScheme.error),
                            tooltip: 'Delete Vehicle',
                            onPressed: () => _handleDelete(v),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool hasActiveFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Fleet Records Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                hasActiveFilters
                    ? 'No vehicles match your active search terms or filter selections. Try broadening your criteria or reset the filters.'
                    : 'There are currently no vehicles registered in the database.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (hasActiveFilters)
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset All Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: widget.onAddVehicle,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Register First Vehicle'),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(VehicleType type) {
    return switch (type) {
      VehicleType.sedan => Icons.directions_car_rounded,
      VehicleType.suv => Icons.airport_shuttle_rounded,
      VehicleType.truck => Icons.local_shipping_rounded,
      VehicleType.van => Icons.directions_bus_rounded,
      VehicleType.electric => Icons.electric_car_rounded,
    };
  }
}
