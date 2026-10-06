import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

import 'delivery_history_screen.dart';
import 'subscription_catalog_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';
import 'service_request_screen.dart';
import 'notifications_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      const SubscriptionCatalogScreen(),
      const PaymentScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: DailyColors.cream,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: DailyColors.cream,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            children: [
              const Text(
                'DAILY',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.burgundy,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: DailyColors.divider),
              _drawerItem(context, 'Home', Icons.home_outlined, 0),
              _drawerItem(
                context,
                'Subscriptions',
                Icons.menu_book_outlined,
                1,
              ),
              _drawerItem(context, 'Payments', Icons.credit_card_outlined, 2),
              _drawerItem(context, 'Profile', Icons.person_outline, 3),
              const Divider(color: DailyColors.divider),
              ListTile(
                leading: const Icon(
                  Icons.support_agent_outlined,
                  color: DailyColors.burgundy,
                ),
                title: const Text('Ask Help'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServiceRequestScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: pages[index]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServiceRequestScreen()),
        ),
        backgroundColor: DailyColors.burgundy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.support_agent_outlined, size: 20),
        label: const Text(
          'ASK HELP',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: DailyBottomNav(
        selectedIndex: index,
        onTap: (i) {
          setState(() {
            index = i;
          });
        },
      ),
    );
  }

  Widget _home() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyHeader(
            title: 'DAILY',
            leading: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, size: 24),
                tooltip: 'Open menu',
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_none, size: 22),
            ),
          ),

          const Text(
            'Welcome back, Reader',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 18),

          // TODAY'S DELIVERY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel("Today's Delivery"),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeliveryHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'History →',
                  style: TextStyle(color: DailyColors.burgundy, fontSize: 10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Container(
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.55,
                  child: SvgPicture.asset(
                    'assets/icons/newspaper.svg',
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The Times of India',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const StatusDot(DailyColors.success),

                          const SizedBox(width: 6),

                          const Text(
                            'Delivered • 7:02 AM',
                            style: TextStyle(fontSize: 10),
                          ),

                          const Spacer(),

                          const Text(
                            'Rahul Patil',
                            style: TextStyle(
                              fontSize: 9,
                              color: DailyColors.gray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Supplier: National Daily Editions',
                        style: TextStyle(fontSize: 11, color: DailyColors.gray),
                      ),

                      const SizedBox(height: 9),

                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DailyColors.burgundy,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: const Text(
                            'VIEW DETAILS',
                            style: TextStyle(fontSize: 9, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // METRICS
          Row(
            children: [
              Expanded(
                child: _metric('ACTIVE\nSUBSCRIPTIONS', '2', 'VIEW ALL', () {
                  setState(() {
                    index = 1;
                  });
                }),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _metric('PENDING\nPAYMENT', '₹356', 'PAY NOW', () {
                  setState(() {
                    index = 2;
                  });
                }),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const SectionLabel('Active Subscriptions'),
          const SizedBox(height: 8),
          _subscriptionSummary('The Times of India', 'Active • 7:30 AM'),
          _subscriptionSummary('The Hindu', 'Active • 7:30 AM'),

          const SizedBox(height: 18),

          const SectionLabel('Quick Services'),

          const SizedBox(height: 8),

          _service('Report Missed Delivery', Icons.report_problem_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceRequestScreen()),
            );
          }),

          _service('Pause Subscription', Icons.pause_circle_outline, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceRequestScreen()),
            );
          }),

          _service('Manage Address', Icons.location_on_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceRequestScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    String value,
    String action,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 1.2,
              color: DailyColors.gray,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: DailyColors.charcoal,
            ),
          ),

          const SizedBox(height: 4),

          InkWell(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 8,
                color: DailyColors.burgundy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _service(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: DailyColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: DailyColors.burgundy),

            const SizedBox(width: 10),

            Expanded(child: Text(text, style: const TextStyle(fontSize: 10))),

            const Icon(Icons.chevron_right, size: 18, color: DailyColors.gray),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int destination,
  ) {
    return ListTile(
      leading: Icon(icon, color: DailyColors.burgundy),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: DailyColors.gray),
      onTap: () {
        Navigator.pop(context);
        setState(() => index = destination);
      },
    );
  }

  Widget _subscriptionSummary(String name, String details) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DailyColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.newspaper_outlined,
            size: 18,
            color: DailyColors.burgundy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            details,
            style: const TextStyle(fontSize: 11, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }
}
