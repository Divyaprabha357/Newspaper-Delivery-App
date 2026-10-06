import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'partner_auth_screen.dart';
import 'partner_dashboard_screen.dart';
import 'partner_delivery_screen.dart';
import 'partner_history_earnings_screen.dart';
import 'partner_models.dart';
import 'partner_profile_screen.dart';

class DeliveryPartnerAppScreen extends StatefulWidget {
  const DeliveryPartnerAppScreen({super.key});

  @override
  State<DeliveryPartnerAppScreen> createState() => _DeliveryPartnerAppScreenState();
}

enum _PartnerTab { dashboard, routes, history, earnings, profile }

class _DeliveryPartnerAppScreenState extends State<DeliveryPartnerAppScreen> {
  bool authenticated = false;
  _PartnerTab tab = _PartnerTab.dashboard;
  RouteCustomer? selectedCustomer;
  ProfileSubScreen? profileSubScreen;

  @override
  Widget build(BuildContext context) {
    if (!authenticated) {
      return PartnerAuthScreen(onSignedIn: () => setState(() => authenticated = true));
    }
    if (selectedCustomer != null) {
      return PartnerCustomerScreen(customer: selectedCustomer!, onBack: () => setState(() => selectedCustomer = null));
    }
    if (profileSubScreen != null) {
      return PartnerProfileSubScreen(screen: profileSubScreen!, onBack: () => setState(() => profileSubScreen = null));
    }
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(child: _content()),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: DailyColors.cream,
        indicatorColor: Colors.transparent,
        selectedIndex: _PartnerTab.values.indexOf(tab),
        onDestinationSelected: (index) => setState(() => tab = _PartnerTab.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Routes'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _content() {
    switch (tab) {
      case _PartnerTab.dashboard:
        return PartnerDashboardScreen(
          onStartRoute: () => setState(() => tab = _PartnerTab.routes),
          onReportIssue: () => setState(() => selectedCustomer = partnerCustomers.first),
        );
      case _PartnerTab.routes:
        return PartnerRouteScreen(onCustomerSelected: (index) => setState(() => selectedCustomer = partnerCustomers[index]));
      case _PartnerTab.history:
        return const PartnerHistoryScreen();
      case _PartnerTab.earnings:
        return const PartnerEarningsScreen();
      case _PartnerTab.profile:
        return PartnerProfileScreen(
          onOpen: (screen) => setState(() => profileSubScreen = screen),
          onLogout: () => setState(() {
            authenticated = false;
            tab = _PartnerTab.dashboard;
          }),
        );
    }
  }
}
