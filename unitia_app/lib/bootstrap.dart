import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/l10n/app_localizations.dart';

import 'core/config/admin_config.dart';
import 'core/config/app_flavor.dart';
import 'core/models/app_user.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/restaurant/restaurant_home.dart';
import 'screens/cause/cause_home.dart';
import 'screens/customer/customer_login_screen.dart';
import 'screens/admin/admin_password_screen.dart';
import 'screens/customer/customer_home.dart';

Future<void> bootstrap(AppFlavor flavor) async {
  FlavorConfig.flavor = flavor;
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Notificaciones solo en la app del restaurante
  if (flavor == AppFlavor.restaurant) {
    await NotificationService.init();
  }

  runApp(const UnitiaApp());
}

class UnitiaApp extends StatelessWidget {
  const UnitiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          title: FlavorConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  /// Rol esperado según el flavor activo.
  UserRole get _expectedRole => switch (FlavorConfig.flavor) {
        AppFlavor.restaurant => UserRole.restaurant,
        AppFlavor.cause      => UserRole.cause,
        AppFlavor.customer   => UserRole.customer,
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FlavorConfig.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    // Admin → pantalla de contraseña (en cualquier flavor)
    if (auth.user != null && auth.user!.email == AdminConfig.adminEmail) {
      return const AdminPasswordScreen();
    }

    // Usuario autenticado pero con rol incorrecto → cerrar sesión
    if (auth.user != null && auth.user!.role != _expectedRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await auth.signOut();
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.authWrongRole(FlavorConfig.appName)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      });
      return const Scaffold(backgroundColor: Colors.white);
    }

    return switch (FlavorConfig.flavor) {
      AppFlavor.restaurant => auth.user == null
          ? const LoginScreen()
          : const RestaurantHome(),
      AppFlavor.cause => auth.user == null
          ? const LoginScreen()
          : const CauseHome(),
      AppFlavor.customer => auth.user == null
          ? const CustomerLoginScreen()
          : const CustomerHome(),
    };
  }
}
