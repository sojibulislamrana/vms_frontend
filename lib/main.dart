import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/password_reset_screen.dart';
import 'screens/auth/workspace_setup_screen.dart';
import 'screens/marketing/marketing_home_screen.dart';
import 'screens/shell/app_shell.dart';
import 'services/auth_service.dart';
import 'services/vehicle_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL'),
  );
  const supabaseKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'),
  );
  SupabaseClient? supabaseClient;
  final resetPasswordRoute = Uri.base.queryParameters['mode'] == 'reset-password';
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    supabaseClient = Supabase.instance.client;
  }
  runApp(VmsApp(supabaseClient: supabaseClient, resetPasswordRoute: resetPasswordRoute));
}

/// The root widget of the Vehicle Management System frontend application.
class VmsApp extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final bool resetPasswordRoute;

  const VmsApp({super.key, this.supabaseClient, this.resetPasswordRoute = false});

  @override
  State<VmsApp> createState() => _VmsAppState();
}

class _VmsAppState extends State<VmsApp> {
  bool _passwordResetComplete = false;
  late final AuthService _authService;
  late final VehicleService _vehicleService;
  final ValueNotifier<ThemeMode> _themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  void initState() {
    super.initState();
    _authService = AuthService(client: widget.supabaseClient);
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
              home: widget.resetPasswordRoute && !_passwordResetComplete
                  ? PasswordResetScreen(authService: _authService, onComplete: () => setState(() => _passwordResetComplete = true))
                  : _authService.hasSession
                  ? (_authService.isWorkspaceLoading
                      ? const _LoadingHome()
                      : (_authService.workspaceId == null
                          ? WorkspaceSetupScreen(authService: _authService)
                          : AppShell(
                      authService: _authService,
                      vehicleService: _vehicleService,
                      themeModeNotifier: _themeModeNotifier,
                      onLogout: _handleLogout,
                    )))
                  : const MarketingHomeScreen(),
              routes: {
                '/login': (context) => LoginScreen(
                      authService: _authService,
                      onLoginSuccess: () => Navigator.of(context).pop(),
                    ),
                '/signup': (context) => LoginScreen(
                      authService: _authService,
                      startingOnSignUp: true,
                      onLoginSuccess: () => Navigator.of(context).pop(),
                    ),
              },
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
                      : const MarketingHomeScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFF6F6F1),
        body: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF315E4B)))),
      );
}
