import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';
import '../../theme/mobile_role_design.dart';
import '../../widgets/daily_widgets.dart';
import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';

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
  bool loading = true;
  String? loadError;
  Map<String, dynamic>? customer;
  List<dynamic> subscriptions = [];
  List<dynamic> deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final customerId = await SessionService.getCustomerId();
    if (customerId == null) {
      if (mounted) setState(() { loading = false; loadError = 'Your session has expired. Please sign in again.'; });
      return;
    }
    try {
      final api = CustomerApiService();
      final results = await Future.wait([api.profile(customerId), api.subscriptions(customerId), api.deliveryHistory(customerId)]);
      if (!mounted) return;
      setState(() {
        customer = Map<String, dynamic>.from(results[0]['user'] as Map? ?? {});
        subscriptions = List<dynamic>.from(results[1]['subscriptions'] as List? ?? []);
        deliveries = List<dynamic>.from(results[2]['deliveries'] as List? ?? []);
        loading = false;
      });
    } on CustomerApiException catch (error) {
      if (mounted) setState(() { loading = false; loadError = error.message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      const SubscriptionCatalogScreen(),
      const PaymentScreen(),
      const ProfileScreen(),
    ];

    return Theme(
      data: MobileRoleDesign.theme(context),
      child: Scaffold(
      backgroundColor: DailyColors.cream,
      extendBody: true,
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _home() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: DailyColors.burgundy));
    }
    if (loadError != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, color: DailyColors.burgundy, size: 40),
        const SizedBox(height: 12),
        Text(loadError!, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: () { setState(() { loading = true; loadError = null; }); _loadCustomerData(); }, child: const Text('TRY AGAIN')),
      ])));
    }
    final firstName = (customer?['name'] as String? ?? 'Reader').split(' ').first;
    final latestDelivery = deliveries.isNotEmpty ? Map<String, dynamic>.from(deliveries.first as Map) : null;
    final latestName = latestDelivery?['newspaper_name'] as String? ?? 'No delivery recorded';
    final latestStatus = latestDelivery?['item_status'] ?? latestDelivery?['delivery_status'] ?? 'Awaiting delivery';
    final latestTime = latestDelivery?['actual_time'] ?? latestDelivery?['scheduled_time'] ?? '—';
    final partnerName = latestDelivery?['partner_name'] ?? 'Not assigned';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyHeader(
            title: 'DAILY',
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

          Text(
            'Welcome back, $firstName',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: DailyColors.burgundy, fontSize: 14),
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
                      Text(
                        latestName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const StatusDot(DailyColors.success),

                          const SizedBox(width: 6),

                          Text(
                            '${latestStatus.toString().replaceAll('_', ' ')} â€¢ $latestTime',
                            style: TextStyle(fontSize: 14),
                          ),

                          const Spacer(),

                          Text(
                            '$partnerName',
                            style: TextStyle(
                              fontSize: 12,
                              color: DailyColors.gray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supplier: ${latestDelivery?['supplier_name'] ?? '—'}',
                        style: TextStyle(fontSize: 12, color: DailyColors.gray),
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
                            style: TextStyle(fontSize: 12, letterSpacing: 1),
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
                child: _metric('ACTIVE\nSUBSCRIPTIONS', '${subscriptions.where((item) => item['status'] == 'ACTIVE').length}', 'VIEW ALL', () {
                  setState(() {
                    index = 1;
                  });
                }),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _metric('PENDING\nPAYMENT', '—', 'VIEW PAYMENTS', () {
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
          if (subscriptions.isEmpty)
            const Text('No active subscriptions.', style: TextStyle(color: DailyColors.gray))
          else
            ...subscriptions.take(3).map((item) => _subscriptionSummary(
              item['newspaper_name'] as String? ?? 'Newspaper',
              '${item['status'] ?? '—'} â€¢ ${item['scheduled_delivery_time'] ?? '—'}',
            )),

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
              fontSize: 12,
              letterSpacing: 1.2,
              color: DailyColors.gray,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
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
                fontSize: 12,
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

            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),

            const Icon(Icons.chevron_right, size: 18, color: DailyColors.gray),
          ],
        ),
      ),
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
            style: const TextStyle(fontSize: 12, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }
}


