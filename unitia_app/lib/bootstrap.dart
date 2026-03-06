import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/config/app_flavor.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/restaurant/restaurant_home.dart';
import 'screens/cause/cause_home.dart';
import 'screens/customer/customer_login_screen.dart';
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
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

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
