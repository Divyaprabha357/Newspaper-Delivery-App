import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'partner_widgets.dart';

class PartnerHistoryScreen extends StatefulWidget {
  const PartnerHistoryScreen({super.key});
  @override
  State<PartnerHistoryScreen> createState() => _PartnerHistoryScreenState();
}

class _PartnerHistoryScreenState extends State<PartnerHistoryScreen> {
  bool loading = true;
  Object? error;
  List<Map<String, dynamic>> deliveries = const [];

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
      final userId = int.tryParse('${session?['user_id'] ?? session?['id']}');
      final partnerId = int.tryParse(
        '${session?['partner_id'] ?? session?['id']}',
      );
      if (userId == null && partnerId == null) {
        throw const RoleApiException(
          'Your delivery partner session has expired.',
        );
      }
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).partnerDeliveries(userId ?? partnerId!, partnerId: partnerId);
      final rows = (response['deliveries'] as List? ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      if (mounted) {
        setState(() {
          deliveries = rows;
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
    final delivered = deliveries
        .where((r) => '${r['delivery_status']}'.toUpperCase() == 'DELIVERED')
        .length;
    final partial = deliveries
        .where(
          (r) => '${r['delivery_status']}'.toUpperCase().contains('PARTIAL'),
        )
        .length;
    final issues = deliveries.length - delivered - partial;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PartnerTop(
            'Delivery history',
          ),
          const PartnerSection('DELIVERY SUMMARY'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _stat('$delivered', 'Delivered'),
                _stat('$partial', 'Partial'),
                _stat('$issues', 'Issues'),
              ],
            ),
          ),
          if (deliveries.isEmpty)
            partnerEmpty('No delivery history yet.')
          else ...[
            const PartnerSection('RECENT DELIVERIES'),
            ...deliveries.map((row) => _item(row)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.cardTitleLarge.copyWith(
              color: DailyColors.burgundy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: DailyColors.gray),
          ),
        ],
      ),
    ),
  );
  Widget _item(Map<String, dynamic> row) {
    final status = '${row['delivery_status'] ?? 'UNKNOWN'}';
    final color = status == 'DELIVERED'
        ? DailyColors.success
        : status.contains('PARTIAL')
        ? DailyColors.warning
        : DailyColors.burgundy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        color: DailyColors.white,
        child: Row(
          children: [
            Icon(
              status == 'DELIVERED' ? Icons.check : Icons.error_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row['customer_name'] ?? 'Customer'}',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$status • ${row['delivery_date'] ?? ''} ${row['scheduled_time'] ?? ''}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerEarningsScreen extends StatefulWidget {
  const PartnerEarningsScreen({super.key});
  @override
  State<PartnerEarningsScreen> createState() => _PartnerEarningsScreenState();
}

class _PartnerEarningsScreenState extends State<PartnerEarningsScreen> {
  bool loading = true;
  Object? error;
  List<Map<String, dynamic>> payments = const [];
  int completedDeliveries = 0;
  double calculatedEarnings = 0.0;
  double ratePerDelivery = 10.0;

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
      final userId = int.tryParse('${session?['user_id'] ?? session?['id']}');
      final partnerId = int.tryParse(
        '${session?['partner_id'] ?? session?['id']}',
      );
      if (userId == null && partnerId == null) {
        throw const RoleApiException(
          'Your delivery partner session has expired.',
        );
      }
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).partnerPayments(userId ?? partnerId!, partnerId: partnerId);

      final earnMap = response['earnings'] is Map
          ? Map<String, dynamic>.from(response['earnings'] as Map)
          : null;
      final completed =
          int.tryParse(
            '${earnMap?['completed_deliveries'] ?? response['completed_deliveries'] ?? 0}',
          ) ??
          0;
      final calcTotal =
          double.tryParse(
            '${earnMap?['calculated_total'] ?? earnMap?['total_earnings'] ?? response['calculated_earnings'] ?? 0}',
          ) ??
          0.0;
      final rate =
          double.tryParse('${earnMap?['rate_per_delivery'] ?? 10}') ?? 10.0;
      final rows = (response['payments'] as List? ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      if (mounted) {
        setState(() {
          completedDeliveries = completed;
          calculatedEarnings = calcTotal;
          ratePerDelivery = rate;
          payments = rows;
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

  double _amount(Map<String, dynamic> row) =>
      double.tryParse('${row['amount']}') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return partnerError(error!, _load);
    final paidAmount = payments
        .where((r) => '${r['status']}'.toUpperCase() == 'PAID')
        .fold<double>(0.0, (sum, row) => sum + _amount(row));
    final pendingAmount = (calculatedEarnings - paidAmount).clamp(
      0.0,
      double.infinity,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartnerTop(
            'My earnings',
            subtitle: payments.isEmpty
                ? '$completedDeliveries completed ${completedDeliveries == 1 ? 'delivery' : 'deliveries'} (₹${ratePerDelivery.toInt()}/delivery)'
                : '$completedDeliveries completed ${completedDeliveries == 1 ? 'delivery' : 'deliveries'} • ${payments.length} payment ${payments.length == 1 ? 'record' : 'records'}',
          ),
          const PartnerSection('CALCULATED EARNINGS'),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: DailyColors.charcoal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL EARNINGS',
                    style: AppTextStyles.sectionHeaderDark,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${calculatedEarnings.toStringAsFixed(2)}',
                    style: AppTextStyles.pageTitleLight,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DELIVERIES: $completedDeliveries',
                        style: AppTextStyles.caption.copyWith(
                          color: DailyColors.tan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'RATE: ₹${ratePerDelivery.toStringAsFixed(0)}/delivery',
                        style: AppTextStyles.caption.copyWith(
                          color: DailyColors.tan,
                        ),
                      ),
                    ],
                  ),
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DISBURSED: ₹${paidAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.caption.copyWith(
                            color: DailyColors.tan,
                          ),
                        ),
                        Text(
                          'PENDING: ₹${pendingAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.caption.copyWith(
                            color: DailyColors.tan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const PartnerSection('PAYMENT HISTORY'),
          if (payments.isEmpty)
            partnerEmpty('No payment history recorded yet.')
          else ...[
            ...payments.map((row) => _payment(row)),
          ],
        ],
      ),
    );
  }

  Widget _payment(Map<String, dynamic> row) {
    final status = '${row['status'] ?? 'UNKNOWN'}'.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${row['payment_period'] ?? 'Payment'}',
                style: AppTextStyles.cardTitle,
              ),
            ),
            Text(
              '₹${_amount(row).toStringAsFixed(2)}',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(width: 15),
            Text(
              status,
              style: AppTextStyles.status.copyWith(
                fontSize: 14,
                color: status == 'PAID'
                    ? DailyColors.success
                    : DailyColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
