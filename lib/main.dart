import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/app_shell.dart';
import 'services/auth_service.dart';
import 'services/vehicle_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VmsApp());
}

/// The root widget of the Vehicle Management System frontend application.
class VmsApp extends StatefulWidget {
  const VmsApp({super.key});

  @override
  State<VmsApp> createState() => _VmsAppState();
}

class _VmsAppState extends State<VmsApp> {
  late final AuthService _authService;
  late final VehicleService _vehicleService;
  final ValueNotifier<ThemeMode> _themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _vehicleService = VehicleService(authService: _authService);
  }

  void _handleLogout() {
    _vehicleService.clearCache();
    setState(() {});
  }

  @override
  void dispose() {
    _authService.dispose();
    _vehicleService.dispose();
    _themeModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, themeMode, _) {
        return ListenableBuilder(
          listenable: _authService,
          builder: (context, _) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => _authService.isAuthenticated
                      ? AppShell(
                          authService: _authService,
                          vehicleService: _vehicleService,
                          themeModeNotifier: _themeModeNotifier,
                          onLogout: _handleLogout,
                          initialRoute: settings.name,
                        )
                      : LoginScreen(
                          authService: _authService,
                          onLoginSuccess: () => setState(() {}),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}
