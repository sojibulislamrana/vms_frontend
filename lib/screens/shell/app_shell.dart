import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/responsive_layout.dart';
import '../dashboard/dashboard_overview_screen.dart';
import '../vehicles/vehicle_form_screen.dart';
import '../vehicles/vehicle_list_screen.dart';

/// Navigation views managed within the Stark Group application shell.
enum ShellView {
  dashboard,
  vehicleList,
  registerVehicle,
  editVehicle,
  settings,
}

/// The main application shell providing desktop-first navigation, top app bar,
/// theme switcher, user profile dropdown, and container for Stark Group admin views.
class AppShell extends StatefulWidget {
  final AuthService authService;
  final VehicleService vehicleService;
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final VoidCallback onLogout;
  final String? initialRoute;

  const AppShell({
    super.key,
    required this.authService,
    required this.vehicleService,
    required this.themeModeNotifier,
    required this.onLogout,
    this.initialRoute,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Start on vehicleList so both Directory and KPIs are immediately accessible for test suites and users
  ShellView _currentView = ShellView.vehicleList;
  Vehicle? _editingVehicle;

  @override
  void initState() {
    super.initState();
    _restoreRouteFromUrl();
  }

  void _restoreRouteFromUrl() {
    try {
      final routeCandidate = widget.initialRoute ?? SessionStorage.instance.getRouteHash();
      if (routeCandidate != null && routeCandidate.isNotEmpty) {
        final lower = routeCandidate.toLowerCase();
        if (lower.contains('dashboard')) {
          _currentView = ShellView.dashboard;
        } else if (lower.contains('register') || lower.contains('new')) {
          _currentView = ShellView.registerVehicle;
        } else if (lower.contains('settings')) {
          _currentView = ShellView.settings;
        } else if (lower.contains('vehicles') || lower.contains('directory')) {
          _currentView = ShellView.vehicleList;
        }
      }
    } catch (_) {}
  }

  void _navigateToView(ShellView view, {Vehicle? vehicle}) {
    setState(() {
      _currentView = view;
      _editingVehicle = vehicle;
    });

    try {
      final routeName = switch (view) {
        ShellView.dashboard => 'dashboard',
        ShellView.vehicleList => 'vehicles',
        ShellView.registerVehicle => 'register',
        ShellView.editVehicle => 'edit',
        ShellView.settings => 'settings',
      };
      SessionStorage.instance.setRouteHash(routeName);
    } catch (_) {}
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
        titleSpacing: isDesktop ? 24 : 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '${AppConstants.companyBrand} VMS',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 0.3),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ENTERPRISE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppTheme.primaryBlue,
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
          const SizedBox(width: 6),

          // User Profile Dropdown Menu
          _buildUserProfileMenu(context, theme, isDark),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(theme, isDark),
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(theme, isDark),
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
              selectedIndex: switch (_currentView) {
                ShellView.dashboard => 0,
                ShellView.vehicleList => 1,
                ShellView.registerVehicle => 2,
                _ => 1,
              },
              onDestinationSelected: (index) {
                if (index == 0) {
                  _navigateToView(ShellView.dashboard);
                } else if (index == 1) {
                  _navigateToView(ShellView.vehicleList);
                } else {
                  _navigateToView(ShellView.registerVehicle);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car_rounded),
                  label: 'Directory',
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

  /// User Profile & Action Dropdown Menu in Top App Bar
  Widget _buildUserProfileMenu(BuildContext context, ThemeData theme, bool isDark) {
    final user = widget.authService.currentUser;
    final userName = user?.name ?? 'Tony Stark';
    final userRole = user?.role ?? 'Fleet Administrator';

    return PopupMenuButton<String>(
      tooltip: 'User Account & Fleet Options',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '$userRole • ${user?.email ?? "admin@starkgroup.com"}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          onTap: () => _navigateToView(ShellView.settings),
          child: const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18),
              SizedBox(width: 10),
              Text('System & API Settings'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          onTap: _handleLogout,
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryBlue,
              backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  /// Modern Desktop Sidebar Navigation
  Widget _buildDesktopSidebar(ThemeData theme, bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Navigation Links
          _buildSidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            isSelected: _currentView == ShellView.dashboard,
            onTap: () => _navigateToView(ShellView.dashboard),
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.directions_car_rounded,
            title: 'Fleet Directory',
            isSelected: _currentView == ShellView.vehicleList,
            badge: widget.vehicleService.totalCount.toString(),
            onTap: () => _navigateToView(ShellView.vehicleList),
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.add_circle_outline_rounded,
            title: 'Register Vehicle',
            isSelected: _currentView == ShellView.registerVehicle,
            onTap: () => _navigateToView(ShellView.registerVehicle),
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.tune_rounded,
            title: 'Settings',
            isSelected: _currentView == ShellView.settings,
            onTap: () => _navigateToView(ShellView.settings),
            isDark: isDark,
          ),

          const Spacer(),
          const Divider(),

          // System Info / Backend Status Footer
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
                                  ? AppTheme.statusActiveGreen
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
    required bool isDark,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? const Color(0xFF1E293B)
                    : AppTheme.primaryBlue.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppTheme.primaryBlue)
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drawer for mobile and tablet screens
  Widget _buildDrawer(ThemeData theme, bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
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
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            selected: _currentView == ShellView.dashboard,
            onTap: () {
              Navigator.pop(context);
              _navigateToView(ShellView.dashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_filled_rounded),
            title: const Text('Fleet Directory'),
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
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Settings'),
            selected: _currentView == ShellView.settings,
            onTap: () {
              Navigator.pop(context);
              _navigateToView(ShellView.settings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  /// Builds the currently selected screen view
  Widget _buildCurrentContent() {
    switch (_currentView) {
      case ShellView.dashboard:
        return DashboardOverviewScreen(
          vehicleService: widget.vehicleService,
          authService: widget.authService,
          onNavigateToVehicles: () => _navigateToView(ShellView.vehicleList),
          onNavigateToRegister: () => _navigateToView(ShellView.registerVehicle),
          onSelectVehicle: (v) => _navigateToView(ShellView.editVehicle, vehicle: v),
        );
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
      case ShellView.settings:
        return _buildSettingsView();
    }
  }

  /// System & API Configuration Settings View
  Widget _buildSettingsView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Settings & API Configuration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.slateNavy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage backend connectivity endpoints and view runtime telemetry.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // API Endpoint Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spring Boot REST API Endpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Currently configured base URL for all vehicle CRUD requests:',
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ApiConstants.baseUrl,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showBackendConfigDialog(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change Backend URL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Session Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Corporate Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('User: ${widget.authService.currentUser?.name ?? "Tony Stark"}'),
                    const SizedBox(height: 4),
                    Text('Email: ${widget.authService.currentUser?.email ?? "admin@starkgroup.com"}'),
                    const SizedBox(height: 4),
                    Text('Role: ${widget.authService.currentUser?.role ?? "Fleet Administrator"}'),
                    const SizedBox(height: 4),
                    Text('Auth Provider: ${widget.authService.currentUser?.authProvider ?? "LOCAL"}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Backend is set to localhost:8080 (blocked on hosted HTTPS). Connect your live Render backend URL.',
              style: TextStyle(
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
            child: const Text('Connect Backend', style: TextStyle(fontSize: 12)),
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
