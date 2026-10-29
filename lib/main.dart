import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/responsive.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation.dart';

import 'screens/profile_screen.dart';
import 'admin/screens/super_admin_dashboard.dart';
import 'admin/screens/office_admin_dashboard.dart';
import 'admin/widgets/role_guard.dart';
import 'package:provider/provider.dart';
import 'admin/services/admin_service.dart';
import 'services/driver_service.dart';
import 'services/api_service.dart';
import 'screens/dev_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => DriverService()),
      ],
      child: const SabcargoApp(),
    ),
  );
}

class SabcargoApp extends StatelessWidget {
  const SabcargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabcargo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scaled = mq.textScaler
            .scale(1.0)
            .clamp(AppBreakpoints.minTextScale, AppBreakpoints.maxTextScale);
        final wrapped = MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scaled)),
          child: child ?? const SizedBox.shrink(),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            if (w > AppBreakpoints.maxAppWidth) {
              return ColoredBox(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.maxAppWidth,
                    ),
                    child: Material(
                      elevation: 6,
                      shadowColor: Colors.black26,
                      child: wrapped,
                    ),
                  ),
                ),
              );
            }
            return wrapped;
          },
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dev-settings': (context) => const DevSettingsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/pin-login': (context) => const PinLoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const RoleGate(
          allowedRoles: ['Admin', 'SuperAdmin'],
          child: OfficeAdminDashboard(),
        ),
        '/superadmin': (context) => const RoleGate(
          allowedRoles: ['SuperAdmin'],
          child: SuperAdminDashboard(),
        ),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}
