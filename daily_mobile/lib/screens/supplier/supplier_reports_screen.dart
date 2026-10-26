import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';

class SupplierReportsScreen extends StatefulWidget {
  const SupplierReportsScreen({super.key});

  @override
  State<SupplierReportsScreen> createState() => _SupplierReportsScreenState();
}

class _SupplierReportsScreenState extends State<SupplierReportsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _reports;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final rawUserId = session?['user_id'];
      final userId = rawUserId is int ? rawUserId : int.tryParse('$rawUserId');
      final rawSupplierId = session?['supplier_id'];
      final supplierId = rawSupplierId is int ? rawSupplierId : int.tryParse('$rawSupplierId');

      if (userId == null) {
        throw const RoleApiException('No authenticated Supplier session found.');
      }

      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierReports(userId, supplierId: supplierId);

      if (!mounted) return;
      setState(() {
        _reports = Map<String, dynamic>.from(response['reports'] as Map? ?? {});
        _loading = false;
      });
    } on RoleApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to generate supplier reports. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DailyColors.burgundy),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: DailyColors.burgundy, size: 36),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _loadReports, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }

    final summary = Map<String, dynamic>.from(_reports?['summary'] as Map? ?? {});
    final deliveries = Map<String, dynamic>.from(_reports?['deliveries'] as Map? ?? {});
    final revenue = Map<String, dynamic>.from(_reports?['revenue'] as Map? ?? {});
    final requests = Map<String, dynamic>.from(_reports?['requests'] as Map? ?? {});
    final topNewspapers = (_reports?['top_newspapers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return RefreshIndicator(
      color: DailyColors.burgundy,
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DAILY DISTRIBUTION',
              style: TextStyle(
                color: DailyColors.burgundy,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Operational Reports',
              style: TextStyle(
                color: DailyColors.charcoal,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Executive Summary KPIs
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _metricCard(
                      'TOTAL SUBSCRIBERS',
                      '${summary['total_subscribers'] ?? 0}',
                      '${summary['active_subscriptions'] ?? 0} active subscriptions',
                      Icons.people_outline,
                      width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                    ),
                    _metricCard(
                      'MONTHLY RECURRING',
                      '₹${summary['monthly_revenue'] ?? '0.00'}',
                      'Estimated active cycle revenue',
                      Icons.currency_rupee,
                      width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                    ),
                    _metricCard(
                      'DELIVERY FULFILLMENT',
                      '${summary['delivery_success_rate'] ?? '100.0'}%',
                      '${deliveries['delivered'] ?? 0} of ${deliveries['total'] ?? 0} delivered',
                      Icons.check_circle_outline,
                      width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Revenue & Deliveries Breakdown Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDeliveriesCard(deliveries)),
                      const SizedBox(width: 18),
                      Expanded(child: _buildRevenueCard(revenue)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildDeliveriesCard(deliveries),
                    const SizedBox(height: 18),
                    _buildRevenueCard(revenue),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Customer Requests Resolution Card
            _buildRequestsCard(requests),

            const SizedBox(height: 24),

            // Top Newspapers Section
            _buildTopNewspapersCard(topNewspapers),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, String subtitle, IconData icon, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: DailyColors.gray,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: DailyColors.burgundy),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: DailyColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesCard(Map<String, dynamic> deliveries) {
    final total = deliveries['total'] ?? 0;
    final delivered = deliveries['delivered'] ?? 0;
    final undelivered = deliveries['undelivered'] ?? 0;
    final rate = deliveries['success_rate'] ?? '100.0';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY PERFORMANCE',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: DailyColors.burgundy),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Success Rate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Text('$rate%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DailyColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: DailyColors.divider, height: 1),
          const SizedBox(height: 12),
          _statRow('Total Dispatches', '$total'),
          _statRow('Delivered Successfully', '$delivered', color: DailyColors.success),
          _statRow('Exceptions / Missed', '$undelivered', color: undelivered > 0 ? DailyColors.warning : DailyColors.charcoal),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(Map<String, dynamic> revenue) {
    final billed = revenue['total_billed'] ?? '0.00';
    final collected = revenue['total_collected'] ?? '0.00';
    final pending = revenue['total_pending'] ?? '0.00';
    final rate = revenue['collection_rate'] ?? '100.0';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BILLING & COLLECTIONS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: DailyColors.burgundy),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Collection Rate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Text('$rate%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DailyColors.burgundy)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: DailyColors.divider, height: 1),
          const SizedBox(height: 12),
          _statRow('Total Billed', '₹$billed'),
          _statRow('Collected', '₹$collected', color: DailyColors.success),
          _statRow('Outstanding Pending', '₹$pending', color: DailyColors.burgundy),
        ],
      ),
    );
  }

  Widget _buildRequestsCard(Map<String, dynamic> requests) {
    final total = requests['total'] ?? 0;
    final resolved = requests['resolved'] ?? 0;
    final pending = requests['pending'] ?? 0;
    final rate = requests['resolution_rate'] ?? '100.0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CUSTOMER REQUESTS & SERVICE',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: DailyColors.burgundy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: DailyColors.tan,
                child: Text('$rate% Resolved', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DailyColors.burgundy)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statItem('Total Inquiries', '$total')),
              Expanded(child: _statItem('Resolved', '$resolved', color: DailyColors.success)),
              Expanded(child: _statItem('In Progress / Pending', '$pending', color: pending > 0 ? DailyColors.warning : DailyColors.charcoal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNewspapersCard(List<Map<String, dynamic>> newspapers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEWSPAPER CIRCULATION BREAKDOWN',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: DailyColors.burgundy),
          ),
          const SizedBox(height: 14),
          if (newspapers.isEmpty)
            const Text('No newspapers currently supplied.', style: TextStyle(color: DailyColors.gray))
          else
            ...List.generate(newspapers.length, (i) {
              final n = newspapers[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: DailyColors.tan,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DailyColors.burgundy)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${n['name'] ?? 'Newspaper'}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${n['language'] ?? 'Regional'} edition',
                            style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${n['subscribers']} subs',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${n['revenue']}/mo',
                          style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: DailyColors.gray))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? DailyColors.charcoal)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: DailyColors.gray)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? DailyColors.charcoal)),
      ],
    );
  }
}
