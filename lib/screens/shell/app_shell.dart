import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/responsive_layout.dart';
import '../vehicles/vehicle_form_screen.dart';
import '../vehicles/vehicle_list_screen.dart';

/// Navigation views managed within the Stark Group application shell.
enum ShellView {
  vehicleList,
  registerVehicle,
  editVehicle,
}

/// The main application shell providing desktop-first navigation, app bar,
/// theme switcher, and container for Stark Group admin views.
class AppShell extends StatefulWidget {
  final AuthService authService;
  final VehicleService vehicleService;
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.authService,
    required this.vehicleService,
    required this.themeModeNotifier,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellView _currentView = ShellView.vehicleList;
  Vehicle? _editingVehicle;

  void _navigateToView(ShellView view, {Vehicle? vehicle}) {
    setState(() {
      _currentView = view;
      _editingVehicle = vehicle;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out of Fleet Console',
      message: 'Are you sure you want to end your Stark Group administrative session?',
      confirmLabel: 'Sign Out',
    );

    if (confirmed == true && mounted) {
      widget.authService.logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = widget.themeModeNotifier.value == ThemeMode.dark ||
        (widget.themeModeNotifier.value == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.shield_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '${AppConstants.companyBrand} • VMS',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                AppConstants.appVersion,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Theme mode toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              widget.themeModeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 4),

          // User Profile Pill (Visible on tablets and desktop)
          if (!ResponsiveLayout.isMobile(context)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (widget.authService.currentUser?.name ?? 'S')[0],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.authService.currentUser?.name ?? 'Tony Stark',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Sign Out button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(theme),
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(theme),
          Expanded(
            child: Column(
              children: [
                if (_isHostedOnCloudWithLocalhostBackend())
                  _buildBackendWarningBanner(theme),
                Expanded(child: _buildCurrentContent()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop && ResponsiveLayout.isMobile(context)
          ? NavigationBar(
              selectedIndex: _currentView == ShellView.vehicleList ? 0 : 1,
              onDestinationSelected: (index) {
                if (index == 0) {
                  _navigateToView(ShellView.vehicleList);
                } else {
                  _navigateToView(ShellView.registerVehicle);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car_rounded),
                  label: 'Vehicles',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  selectedIcon: Icon(Icons.add_circle_rounded),
                  label: 'Register',
                ),
              ],
            )
          : null,
    );
  }

  /// Persistent desktop sidebar for wide displays.
  Widget _buildDesktopSidebar(ThemeData theme) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'FLEET MANAGEMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Navigation items
          _buildSidebarItem(
            icon: Icons.directions_car_filled_rounded,
            title: 'Vehicles Directory',
            isSelected: _currentView == ShellView.vehicleList,
            onTap: () => _navigateToView(ShellView.vehicleList),
            badge: widget.vehicleService.totalCount.toString(),
          ),
          _buildSidebarItem(
            icon: Icons.add_circle_outline_rounded,
            title: 'Register Vehicle',
            isSelected: _currentView == ShellView.registerVehicle,
            onTap: () => _navigateToView(ShellView.registerVehicle),
          ),

          const Spacer(),
          const Divider(),

          // System info footer
          ListenableBuilder(
            listenable: widget.vehicleService,
            builder: (context, _) {
              final connected = widget.vehicleService.isBackendConnected;
              return InkWell(
                onTap: () => _showBackendConfigDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: connected
                                  ? const Color(0xFF16A34A)
                                  : Colors.amber.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              connected ? 'Spring Boot Online' : 'REST API Ready',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ApiConstants.baseUrl,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? activeColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? activeColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? activeColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Drawer for mobile and tablet screens.
  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  '${AppConstants.companyBrand} VMS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.authService.currentUser?.email ?? 'admin@starkgroup.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_filled_rounded),
            title: const Text('Vehicles Directory'),
            selected: _currentView == ShellView.vehicleList,
            onTap: () {
              Navigator.pop(context);
              _navigateToView(ShellView.vehicleList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline_rounded),
            title: const Text('Register Vehicle'),
            selected: _currentView == ShellView.registerVehicle,
            onTap: () {
              Navigator.pop(context);
              _navigateToView(ShellView.registerVehicle);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Backend API URL'),
            subtitle: Text(
              ApiConstants.baseUrl,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            onTap: () {
              Navigator.pop(context);
              _showBackendConfigDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  /// Builds the currently selected screen view.
  Widget _buildCurrentContent() {
    switch (_currentView) {
      case ShellView.vehicleList:
        return VehicleListScreen(
          vehicleService: widget.vehicleService,
          onAddVehicle: () => _navigateToView(ShellView.registerVehicle),
          onEditVehicle: (vehicle) =>
              _navigateToView(ShellView.editVehicle, vehicle: vehicle),
        );
      case ShellView.registerVehicle:
        return VehicleFormScreen(
          key: const ValueKey('register_vehicle_form'),
          vehicleService: widget.vehicleService,
          onSaved: () => _navigateToView(ShellView.vehicleList),
          onCancel: () => _navigateToView(ShellView.vehicleList),
        );
      case ShellView.editVehicle:
        return VehicleFormScreen(
          key: ValueKey('edit_vehicle_${_editingVehicle?.id}'),
          initialVehicle: _editingVehicle,
          vehicleService: widget.vehicleService,
          onSaved: () => _navigateToView(ShellView.vehicleList),
          onCancel: () => _navigateToView(ShellView.vehicleList),
        );
    }
  }

  bool _isHostedOnCloudWithLocalhostBackend() {
    try {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return ApiConstants.baseUrl.contains('localhost');
      }
    } catch (_) {}
    return false;
  }

  Widget _buildBackendWarningBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backend is pointing to localhost:8080 (blocked on hosted HTTPS). Connect your live Render backend URL.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF451A03),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _showBackendConfigDialog(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child:
                const Text('Connect Backend', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showBackendConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backend API Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your deployed Spring Boot REST API URL (e.g. from Render):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://vms-backend.onrender.com',
                labelText: 'Backend Base URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConstants.setBaseUrl(newUrl);
                Navigator.of(dialogContext).pop();
                setState(() {});
                await widget.vehicleService.fetchVehicles();
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}
