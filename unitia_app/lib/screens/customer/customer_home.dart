import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import 'customer_causes_screen.dart';
import 'customer_eats_screen.dart';
import 'customer_impact_screen.dart';
import 'customer_account_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid  = auth.user?.uid ?? '';

    final screens = [
      const CustomerCausesScreen(),
      const CustomerEatsScreen(),
      CustomerImpactScreen(uid: uid),
      CustomerAccountScreen(uid: uid),
    ];

    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism),
              label: AppLocalizations.of(context).tabCauses,
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront_rounded),
              label: AppLocalizations.of(context).tabEats,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart_rounded),
              label: AppLocalizations.of(context).tabImpact,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: AppLocalizations.of(context).tabAccount,
            ),
          ],
        ),
      ),
    );
  }
}
