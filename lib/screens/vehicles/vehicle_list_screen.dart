import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/vehicle_image.dart';
import '../../widgets/vehicle_status_badge.dart';

/// Redesigned Vehicles Directory screen following Reference Image 2:
/// Clean, minimal, premium SaaS aesthetic with search & multi-tier filters,
/// high-fidelity data table with vehicle thumbnails, elegant status badges,
/// and responsive mobile cards.
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
            backgroundColor: const Color(0xFF0F172A),
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

  void _showVehicleDetailsModal(Vehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.vehicleNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            VehicleStatusBadge(status: vehicle.status),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VehicleImage(
                  type: vehicle.type,
                  brand: vehicle.brand,
                  model: vehicle.model,
                  height: 160,
                ),
              ),
              const SizedBox(height: 18),
              _buildModalDetailRow('Assigned Company', vehicle.company, Icons.business_rounded, isDark),
              const Divider(height: 16),
              _buildModalDetailRow('Vehicle Classification', vehicle.type.label, Icons.category_rounded, isDark),
              const Divider(height: 16),
              _buildModalDetailRow('Manufacturer Brand', vehicle.brand, Icons.verified_rounded, isDark),
              const Divider(height: 16),
              _buildModalDetailRow('Model Name', vehicle.model, Icons.directions_car_rounded, isDark),
              const Divider(height: 16),
              _buildModalDetailRow('Database Record ID', vehicle.id, Icons.tag_rounded, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              widget.onEditVehicle(vehicle);
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListenableBuilder(
      listenable: widget.vehicleService,
      builder: (context, _) {
        final isLoading = widget.vehicleService.isLoading;
        final hasError = widget.vehicleService.hasError;

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Heading & Actions
              _buildPageHeader(isDesktop, isLoading),

              const SizedBox(height: 20),

              // KPI Metric Cards
              _buildStatCards(
                totalCount: widget.vehicleService.totalCount,
                activeCount: widget.vehicleService.activeCount,
                maintenanceCount: widget.vehicleService.maintenanceCount,
                inactiveCount: widget.vehicleService.inactiveCount,
                isDesktop: isDesktop,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // Filter & Search Toolbar
              _buildFilterToolbar(theme, isDark, isDesktop, hasActiveFilters),

              const SizedBox(height: 20),

              // Content: Error / Loading / Table or Cards
              if (hasError && widget.vehicleService.vehicles.isEmpty)
                _buildErrorState(theme, isDark)
              else if (isLoading && widget.vehicleService.vehicles.isEmpty)
                _buildLoadingState(isDark)
              else if (filteredVehicles.isEmpty)
                _buildEmptyState(hasActiveFilters, isDark)
              else if (isDesktop)
                _buildDesktopTable(filteredVehicles, isDark)
              else
                _buildMobileCardList(filteredVehicles, isDark),
            ],
          ),
        );
      },
    );
  }

  /// Modern Page Heading with Subtitle & Primary Actions
  Widget _buildPageHeader(bool isDesktop, bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Directory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.slateNavy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage, filter and audit all corporate vehicles registered across Stark Group entities.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => widget.vehicleService.fetchVehicles(),
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: widget.onAddVehicle,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Register Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// KPI Metric Cards
  Widget _buildStatCards({
    required int totalCount,
    required int activeCount,
    required int maintenanceCount,
    required int inactiveCount,
    required bool isDesktop,
    required bool isDark,
  }) {
    final cards = <Widget>[
      StatCard(
        title: 'TOTAL FLEET',
        value: totalCount.toString(),
        icon: Icons.directions_car_filled_rounded,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFEFF6FF),
        badgeText: 'All Units',
      ),
      StatCard(
        title: 'Active Fleet',
        value: activeCount.toString(),
        icon: Icons.check_circle_rounded,
        color: AppTheme.statusActiveGreen,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFF0FDF4),
        badgeText: 'Dispatched',
      ),
      StatCard(
        title: 'Under Maintenance',
        value: maintenanceCount.toString(),
        icon: Icons.build_circle_rounded,
        color: AppTheme.statusMaintenanceOrange,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFFFFBEB),
        badgeText: 'Inspection',
      ),
      StatCard(
        title: 'Inactive / Standby',
        value: inactiveCount.toString(),
        icon: Icons.pause_circle_rounded,
        color: AppTheme.statusInactiveGray,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFF8FAFC),
        badgeText: 'Reserve',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map<Widget>((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 550 ? 2 : 1;
        if (cols == 1) {
          return Column(
            children: cards
                .map<Widget>((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: c,
                    ))
                .toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: cards,
        );
      },
    );
  }

  /// Search & Multi-Tier Filter Toolbar
  Widget _buildFilterToolbar(
    ThemeData theme,
    bool isDark,
    bool isDesktop,
    bool hasActiveFilters,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Field
          SizedBox(
            width: isDesktop ? 280 : double.infinity,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search number, brand, model...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Status Filter Dropdown
          SizedBox(
            width: isDesktop ? 170 : double.infinity,
            child: DropdownButtonFormField<VehicleStatus?>(
              key: ValueKey(_selectedStatus),
              initialValue: _selectedStatus,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<VehicleStatus?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...VehicleStatus.values.map(
                  (s) => DropdownMenuItem<VehicleStatus?>(
                    value: s,
                    child: Text(s.label),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedStatus = val),
            ),
          ),

          // Vehicle Type Filter Dropdown
          SizedBox(
            width: isDesktop ? 160 : double.infinity,
            child: DropdownButtonFormField<VehicleType?>(
              key: ValueKey(_selectedType),
              initialValue: _selectedType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Type',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<VehicleType?>(
                  value: null,
                  child: Text('All Types'),
                ),
                ...VehicleType.values.map(
                  (t) => DropdownMenuItem<VehicleType?>(
                    value: t,
                    child: Text(t.label),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedType = val),
            ),
          ),

          // Company Filter Dropdown
          SizedBox(
            width: isDesktop ? 200 : double.infinity,
            child: DropdownButtonFormField<String?>(
              key: ValueKey(_selectedCompany),
              initialValue: _selectedCompany,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Company Entity',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Companies'),
                ),
                ...AppConstants.defaultCompanies.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCompany = val),
            ),
          ),

          // Clear Filters Button
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }

  /// Clean, Professional Data Table with Vehicle Thumbnails
  Widget _buildDesktopTable(List<Vehicle> vehicles, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            horizontalMargin: 20,
            columnSpacing: 24,
            headingRowHeight: 48,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
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
              final isDeleting = _deletingId == v.id;
              return DataRow(
                cells: [
                  // Vehicle Number with Thumbnail
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: VehicleImage(
                            type: v.type,
                            brand: v.brand,
                            model: v.model,
                            width: 44,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            v.vehicleNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Company
                  DataCell(
                    Text(
                      v.company,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  // Type
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        v.type.label,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Brand
                  DataCell(Text(v.brand)),

                  // Model
                  DataCell(Text(v.model)),

                  // Status
                  DataCell(VehicleStatusBadge(status: v.status)),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quick View Details
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          tooltip: 'View Details',
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          onPressed: () => _showVehicleDetailsModal(v),
                        ),

                        // Edit
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Vehicle',
                          color: AppTheme.primaryBlue,
                          onPressed: () => widget.onEditVehicle(v),
                        ),

                        // Delete
                        isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                tooltip: 'Delete Vehicle',
                                color: const Color(0xFFEF4444),
                                onPressed: () => _handleDelete(v),
                              ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          // Footer Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${vehicles.length} vehicle${vehicles.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Spring Boot REST API • Live PostgreSQL Sync',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive Mobile Cards Layout
  Widget _buildMobileCardList(List<Vehicle> vehicles, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = vehicles[index];
        final isDeleting = _deletingId == v.id;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VehicleImage(
                      type: v.type,
                      brand: v.brand,
                      model: v.model,
                      width: 72,
                      height: 54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                v.vehicleNumber,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            VehicleStatusBadge(status: v.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${v.brand} ${v.model}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${v.company} • ${v.type.label}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showVehicleDetailsModal(v),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => widget.onEditVehicle(v),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  isDeleting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _handleDelete(v),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Empty State with Clear Filters CTA
  Widget _buildEmptyState(bool hasFilters, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off_rounded : Icons.directions_car_outlined,
            size: 56,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? 'No Matching Vehicles Found' : 'No Vehicles in Fleet Catalog',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try adjusting your search terms or clearing active filters.'
                : 'Get started by registering a new corporate vehicle asset.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear All Filters'),
            )
          else
            ElevatedButton.icon(
              onPressed: widget.onAddVehicle,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register First Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Error State with Retry Button
  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          const Text(
            'Unable to Connect to Fleet Backend API',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 6),
          Text(
            widget.vehicleService.errorMessage ?? 'Please check your connection and retry.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => widget.vehicleService.fetchVehicles(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading State
  Widget _buildLoadingState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading fleet catalog from REST API...',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
