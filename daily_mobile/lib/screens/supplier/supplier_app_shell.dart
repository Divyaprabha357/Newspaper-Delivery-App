import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'supplier_customers_screen.dart';
import 'supplier_dashboard_screen.dart';
import 'supplier_delivery_operations_screen.dart';
import 'supplier_distribution_screen.dart';
import 'supplier_design_system.dart';
import 'supplier_newspapers_screen.dart';
import 'supplier_payments_screen.dart';
import 'supplier_profile_screen.dart';
import 'supplier_reports_screen.dart';
import 'supplier_requests_screen.dart';

class SupplierAppShell extends StatefulWidget {
  const SupplierAppShell({super.key});

  @override
  State<SupplierAppShell> createState() => _SupplierAppShellState();
}

class _SupplierAppShellState extends State<SupplierAppShell> {
  int _index = 0;

  final List<_NavItem> _items = const [
    _NavItem('Home', Icons.home_outlined),
    _NavItem('Distribution', Icons.route_outlined),
    _NavItem('Newspapers', Icons.newspaper_outlined),
    _NavItem('Customers', Icons.people_alt_outlined),
    _NavItem('Delivery Operations', Icons.local_shipping_outlined),
    _NavItem('Payments', Icons.receipt_long_outlined),
    _NavItem('Requests & Complaints', Icons.report_problem_outlined),
    _NavItem('Reports', Icons.pie_chart_outline),
    _NavItem('Profile', Icons.person_outline),
  ];

  final List<Widget> _pages = const [
    SupplierDashboardScreen(),
    SupplierDistributionScreen(),
    SupplierNewspapersScreen(),
    SupplierCustomersScreen(),
    SupplierDeliveryOperationsScreen(),
    SupplierPaymentsScreen(),
    SupplierRequestsScreen(),
    SupplierReportsScreen(),
    SupplierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SupplierDesign.theme(context),
      child: Scaffold(
      backgroundColor: DailyColors.cream,
      drawer: Drawer(
        backgroundColor: DailyColors.cream,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'DAILY',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: DailyColors.burgundy,
                  ),
                ),
              ),
              const Divider(color: DailyColors.divider),
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = i == _index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: selected ? DailyColors.burgundy : DailyColors.charcoal,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? DailyColors.burgundy : DailyColors.charcoal,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: DailyColors.tan,
                  onTap: () {
                    setState(() => _index = i);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DailyHeader(
              title: 'DAILY',
              leading: Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, size: 28),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, size: 26),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: DailyColors.burgundy,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _pages[_index],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem(this.title, this.icon);
}


