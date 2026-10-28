import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'delivery_partner_app_screen.dart';
import 'partner_models.dart';
import 'partner_widgets.dart';

class PartnerDashboardScreen extends StatefulWidget {
  final VoidCallback onStartRoute;
  final VoidCallback onReportIssue;
  final RoleApiService? apiService;
  const PartnerDashboardScreen({
    super.key,
    required this.onStartRoute,
    required this.onReportIssue,
    this.apiService,
  });

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  bool loading = true;
  Object? error;
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> routes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await RoleSessionService.getPartner();
      final userId = int.tryParse('${session?['user_id']}');
      final partnerId = int.tryParse('${session?['partner_id']}');
      if (userId == null && partnerId == null) {
        await RoleSessionService.clearPartner();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DeliveryPartnerAppScreen()),
          (route) => false,
        );
        return;
      }
      final api =
          widget.apiService ??
          RoleApiService(authToken: session?['session_token']?.toString());
      final responses = await Future.wait([
        api.partnerProfile(userId ?? partnerId!, partnerId: partnerId),
        api.partnerRoutes(userId ?? partnerId!, partnerId: partnerId),
      ]);
      final routeRows = (responses[1]['routes'] as List? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (mounted) {
        setState(() {
          profile = responses[0]['profile'] as Map<String, dynamic>?;
          routes = routeRows;
          loading = false;
        });
      }
    } on RoleApiException catch (e) {
      if (e.isUnauthorized) {
        await RoleSessionService.clearPartner();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DeliveryPartnerAppScreen()),
          (route) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return partnerError(error!, _load);
    final name = '${profile?['name'] ?? 'Delivery partner'}';
    final route = routes.isEmpty ? null : routes.first;
    final assigned = routes.where((r) => r['customer_id'] != null).length;
    final delivered = routes
        .where((r) => '${r['assignment_status']}'.toUpperCase() == 'DELIVERED')
        .length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartnerTop(
            'Good morning, \n$name.',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Rule(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: DailyColors.charcoal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S ROUTE", style: AppTextStyles.sectionHeaderDark),
                  const SizedBox(height: 12),
                  Text(
                    '${route?['route_name'] ?? 'No route assigned'}',
                    style: AppTextStyles.cardTitleDark,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${route?['shift_start'] ?? '—'} — ${route?['shift_end'] ?? '—'}  •  $assigned CUSTOMERS',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: DailyColors.tan,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onStartRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DailyColors.tan,
                        foregroundColor: DailyColors.charcoal,
                        shape: const RoundedRectangleBorder(),
                        textStyle: AppTextStyles.button.copyWith(
                          color: DailyColors.charcoal,
                        ),
                      ),
                      child: const Text('START ROUTE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PartnerSection("TODAY'S PROGRESS"),
          PartnerProgress(delivered: delivered, total: assigned),
          const PartnerSection('QUICK ACTIONS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    "Today's Route",
                    Icons.route_outlined,
                    widget.onStartRoute,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _action(
                    'Report Issue',
                    Icons.report_problem_outlined,
                    widget.onReportIssue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _action(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DailyColors.burgundy),
            const SizedBox(height: 10),
            Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class PartnerRouteScreen extends StatelessWidget {
  final List<RouteCustomer> customers;
  final ValueChanged<int> onCustomerSelected;
  const PartnerRouteScreen({
    super.key,
    required this.customers,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final delivered = customers
        .where((customer) => customer.deliveryStatus == 'DELIVERED')
        .length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartnerTop(
            'Today\'s route',
          ),
          PartnerProgress(delivered: delivered, total: customers.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$delivered / ${customers.length} Customers',
                  style: AppTextStyles.bodyBold,
                ),
                Text(
                  '${customers.isEmpty ? 0 : (delivered * 100 ~/ customers.length)}% Complete',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const PartnerSection('ROUTE CUSTOMERS'),
          ...customers.asMap().entries.map(
            (entry) => _customer(entry.key, entry.value),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _customer(int index, RouteCustomer item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: InkWell(
        onTap: () => onCustomerSelected(index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DailyColors.white,
            border: Border.all(color: DailyColors.divider),
          ),
          child: Row(
            children: [
              Text(
                item.number,
                style: AppTextStyles.cardTitleLarge.copyWith(
                  color: DailyColors.burgundy,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(item.address, style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    Text(
                      '${item.newspapers.length} newspapers • ${item.time}',
                      style: AppTextStyles.caption.copyWith(
                        color: DailyColors.burgundy,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: DailyColors.burgundy),
            ],
          ),
        ),
      ),
    );
  }
}
