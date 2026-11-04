import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/vehicle_image.dart';
import '../../widgets/vehicle_status_badge.dart';

/// Main Dashboard Overview Screen following Reference Image 2:
/// Four attractive SaaS summary cards with tinted backgrounds, operational readiness
/// metrics, fleet distribution charts, and a featured recent vehicles showcase.
class DashboardOverviewScreen extends StatelessWidget {
  final VehicleService vehicleService;
  final AuthService authService;
  final VoidCallback onNavigateToVehicles;
  final VoidCallback onNavigateToRegister;
  final Function(Vehicle) onSelectVehicle;

  const DashboardOverviewScreen({
    super.key,
    required this.vehicleService,
    required this.authService,
    required this.onNavigateToVehicles,
    required this.onNavigateToRegister,
    required this.onSelectVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: vehicleService,
      builder: (context, _) {
        final total = vehicleService.totalCount;
        final active = vehicleService.activeCount;
        final maintenance = vehicleService.maintenanceCount;
        final inactive = vehicleService.inactiveCount;

        final activePercent = total > 0 ? (active / total * 100).round() : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Executive Header
              _buildHeader(context, theme, isDark),

              const SizedBox(height: 24),

              // Four SaaS Summary Cards
              _buildSummaryCardsGrid(context, isDark, total, active, maintenance, inactive),

              const SizedBox(height: 28),

              // Analytics & Operational Breakdown
              if (ResponsiveLayout.isDesktop(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildOperationalReadinessCard(theme, isDark, total, activePercent, active, maintenance, inactive),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: _buildFleetDistributionCard(theme, isDark),
                    ),
                  ],
                )
              else ...[
                _buildOperationalReadinessCard(theme, isDark, total, activePercent, active, maintenance, inactive),
                const SizedBox(height: 20),
                _buildFleetDistributionCard(theme, isDark),
              ],

              const SizedBox(height: 28),

              // Recent Fleet Vehicles Showcase
              _buildRecentVehiclesSection(context, theme, isDark),
            ],
          ),
        );
      },
    );
  }

  /// Dashboard Header with Greeting and Quick Action Buttons
  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    final userName = authService.currentUser?.name ?? 'Tony Stark';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $userName',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.slateNavy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live fleet operations, health telemetry, and vehicle inventory.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Header Actions
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => vehicleService.fetchVehicles(),
              icon: vehicleService.isLoading
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
              onPressed: onNavigateToRegister,
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

  /// Four Attractive SaaS Summary Cards with Tinted Backgrounds
  Widget _buildSummaryCardsGrid(
    BuildContext context,
    bool isDark,
    int total,
    int active,
    int maintenance,
    int inactive,
  ) {
    final cards = [
      StatCard(
        title: 'Total Vehicles',
        value: total.toString(),
        icon: Icons.directions_car_filled_rounded,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFEFF6FF),
        badgeText: '100% Cataloged',
        subtitle: 'Registered corporate fleet',
      ),
      StatCard(
        title: 'Active Vehicles',
        value: active.toString(),
        icon: Icons.check_circle_rounded,
        color: AppTheme.statusActiveGreen,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFF0FDF4),
        badgeText: 'Operational',
        subtitle: 'Dispatched & road-ready',
      ),
      StatCard(
        title: 'Under Maintenance',
        value: maintenance.toString(),
        icon: Icons.build_circle_rounded,
        color: AppTheme.statusMaintenanceOrange,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFFFFBEB),
        badgeText: 'Inspection Req.',
        subtitle: 'Scheduled repair / audit',
      ),
      StatCard(
        title: 'Inactive Vehicles',
        value: inactive.toString(),
        icon: Icons.pause_circle_rounded,
        color: AppTheme.statusInactiveGray,
        backgroundColor: isDark ? const Color(0xFF151D2A) : const Color(0xFFF8FAFC),
        badgeText: 'Reserve Fleet',
        subtitle: 'Depot standby / archived',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 650
                ? 2
                : 1;

        if (crossAxisCount == 1) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 4 ? 1.45 : 1.7,
          children: cards,
        );
      },
    );
  }

  /// Operational Readiness Progress Card
  Widget _buildOperationalReadinessCard(
    ThemeData theme,
    bool isDark,
    int total,
    int activePercent,
    int active,
    int maintenance,
    int inactive,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fleet Operational Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusActiveGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activePercent% Live',
                  style: const TextStyle(
                    color: AppTheme.statusActiveGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Multi-Segment Operational Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (active > 0)
                    Expanded(
                      flex: active,
                      child: Container(color: AppTheme.statusActiveGreen),
                    ),
                  if (maintenance > 0)
                    Expanded(
                      flex: maintenance,
                      child: Container(color: AppTheme.statusMaintenanceOrange),
                    ),
                  if (inactive > 0)
                    Expanded(
                      flex: inactive,
                      child: Container(color: AppTheme.statusInactiveGray),
                    ),
                  if (total == 0)
                    Expanded(
                      child: Container(color: Colors.grey.shade300),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Metric Details
          _buildMetricLegendItem(
            'Active in Service',
            '$active vehicles ($activePercent%)',
            AppTheme.statusActiveGreen,
          ),
          const SizedBox(height: 10),
          _buildMetricLegendItem(
            'Under Maintenance',
            '$maintenance vehicles (${total > 0 ? (maintenance / total * 100).round() : 0}%)',
            AppTheme.statusMaintenanceOrange,
          ),
          const SizedBox(height: 10),
          _buildMetricLegendItem(
            'Reserve / Standby',
            '$inactive vehicles (${total > 0 ? (inactive / total * 100).round() : 0}%)',
            AppTheme.statusInactiveGray,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Fleet Distribution by Type & Subsidiary
  Widget _buildFleetDistributionCard(ThemeData theme, bool isDark) {
    final vehicles = vehicleService.vehicles;

    // Group counts
    final suvCount = vehicles.where((v) => v.type == VehicleType.suv).length;
    final sedanCount = vehicles.where((v) => v.type == VehicleType.sedan).length;
    final truckCount = vehicles.where((v) => v.type == VehicleType.truck).length;
    final vanCount = vehicles.where((v) => v.type == VehicleType.van).length;
    final electricCount = vehicles.where((v) => v.type == VehicleType.electric).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fleet Allocation by Vehicle Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onNavigateToVehicles,
                child: const Text('View All', style: TextStyle(color: AppTheme.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Types Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTypeCard('SUVs', suvCount, Icons.airport_shuttle_rounded, AppTheme.primaryBlue, isDark),
              _buildTypeCard('Sedans', sedanCount, Icons.directions_car_rounded, const Color(0xFF0284C7), isDark),
              _buildTypeCard('Trucks', truckCount, Icons.local_shipping_rounded, const Color(0xFF8B5CF6), isDark),
              _buildTypeCard('Vans', vanCount, Icons.airport_shuttle_outlined, const Color(0xFF10B981), isDark),
              _buildTypeCard('Electric', electricCount, Icons.bolt_rounded, const Color(0xFF06B6D4), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String typeName, int count, IconData icon, Color color, bool isDark) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            typeName,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Recent Vehicles Showcase with Modern Car Visuals
  Widget _buildRecentVehiclesSection(BuildContext context, ThemeData theme, bool isDark) {
    final recentVehicles = vehicleService.vehicles.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Fleet Inventory',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'High-priority operational assets across business divisions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onNavigateToVehicles,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Open Directory'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (recentVehicles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 48,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'No Fleet Vehicles Registered Yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register your first corporate vehicle to populate live telemetry.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onNavigateToRegister,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Register Vehicle Now'),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 3
                  : constraints.maxWidth > 650
                      ? 2
                      : 1;

              return GridView.builder(
                itemCount: recentVehicles.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final vehicle = recentVehicles[index];
                  return _buildVehicleCard(context, vehicle, isDark);
                },
              );
            },
          ),
      ],
    );
  }

  /// Individual Vehicle Asset Showcase Card with Image
  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle, bool isDark) {
    return InkWell(
      onTap: () => onSelectVehicle(vehicle),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image Header
            Stack(
              children: [
                VehicleImage(
                  type: vehicle.type,
                  brand: vehicle.brand,
                  model: vehicle.model,
                  height: 130,
                  width: double.infinity,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: VehicleStatusBadge(status: vehicle.status),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle.vehicleNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business_outlined,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle.company,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vehicle.type.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
