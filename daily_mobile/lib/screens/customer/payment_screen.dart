import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'service_request_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _api = CustomerApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await SessionService.getCustomerId();
      if (id == null) throw const CustomerApiException('Please sign in again.');
      final result = await Future.wait([
        _api.payments(id),
        _api.subscriptions(id),
      ]);
      if (!mounted) return;
      setState(() {
        _payments = _list(result[0], 'payments');
        _subscriptions = _list(result[1], 'subscriptions');
        _loading = false;
      });
    } on CustomerApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) =>
      (data[key] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  String _date(dynamic value) {
    if (value == null) return '—';
    final str = '$value';
    return str.contains('T') ? str.split('T').first : str;
  }

  String _amount(dynamic value) {
    if (value == null) return '₹0.00';
    return '₹$value';
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;
    if (s == 'PAID' || s == 'SUCCESS' || s == 'COMPLETED') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (s == 'PENDING' || s == 'DUE' || s == 'PROCESSING') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
    } else {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        s,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Payments & Bills',
                trailing: const Icon(Icons.notifications_none, size: 19),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DailyColors.burgundy,
                      ),
                    )
                  : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      color: DailyColors.burgundy,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                        children: [
                          _buildCurrentBillSection(),
                          const SizedBox(height: 24),
                          _buildTransactionsSection(),
                          const SizedBox(height: 24),
                          _buildSubscriptionsSection(),
                          const SizedBox(height: 24),
                          _buildHelpBanner(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBillSection() {
    final bill = _payments.isNotEmpty ? _payments.first : null;
    final billStatus =
        ((bill?['bill_status'] ?? bill?['payment_status'] ?? 'PAID') as String)
            .toUpperCase();
    final isPaid = billStatus == 'PAID' || billStatus == 'SUCCESS';
    final total = bill?['total_amount'] ?? bill?['amount'] ?? '0.00';
    final periodStart = _date(bill?['billing_period_start']);
    final periodEnd = _date(bill?['billing_period_end']);
    final hasPeriod = periodStart != '—' && periodEnd != '—';
    final paidDate = _date(bill?['payment_date']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Current Bill'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
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
                  Text(
                    isPaid ? 'OUTSTANDING BALANCE' : 'AMOUNT DUE',
                    style: AppTextStyles.sectionHeader,
                  ),
                  _statusBadge(
                    isPaid ? 'PAID' : (bill?['bill_status'] ?? 'DUE'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isPaid ? '₹0.00' : '₹$total',
                style: AppTextStyles.metricValueLarge.copyWith(
                  color: isPaid ? DailyColors.charcoal : DailyColors.burgundy,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: DailyColors.divider, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Period',
                          style: TextStyle(
                            fontSize: 11,
                            color: DailyColors.gray,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasPeriod
                              ? '$periodStart — $periodEnd'
                              : 'Active Cycle',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPaid ? 'Paid On' : 'Due Date',
                          style: const TextStyle(
                            fontSize: 11,
                            color: DailyColors.gray,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPaid ? paidDate : periodEnd,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!isPaid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showPayModal(context, bill ?? {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DailyColors.burgundy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'PAY NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else if (bill != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Your account is current',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => _showReceipt(context, bill),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DailyColors.burgundy,
                        side: const BorderSide(color: DailyColors.divider),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'VIEW RECEIPT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Payment History'),
        const SizedBox(height: 8),
        if (_payments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: const Text(
              'No previous payments found.',
              style: TextStyle(color: DailyColors.gray, fontSize: 13),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _desktopTransactionsTable(_payments);
              }
              return Column(
                children: _payments
                    .map((p) => _mobileTransactionItem(context, p))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _desktopTransactionsTable(List<Map<String, dynamic>> payments) {
    return Container(
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.8),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.1),
          5: FlexColumnWidth(1.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: DailyColors.cream),
            children: [
              _th('DATE'),
              _th('REFERENCE'),
              _th('METHOD'),
              _th('AMOUNT'),
              _th('STATUS'),
              _th('RECEIPT'),
            ],
          ),
          ...payments.map((p) {
            final date = _date(p['payment_date'] ?? p['billing_period_end']);
            final ref =
                p['transaction_reference'] ?? 'REF-${p['payment_id'] ?? '—'}';
            final method = '${p['payment_method'] ?? 'UPI'}';
            final amount = _amount(p['amount'] ?? p['total_amount']);
            final status =
                '${p['payment_status'] ?? p['bill_status'] ?? 'SUCCESS'}';
            return TableRow(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DailyColors.divider)),
              ),
              children: [
                _td(date),
                _td(ref, isBold: true),
                _td(method),
                _td(amount, color: DailyColors.burgundy, isBold: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _statusBadge(status),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: TextButton(
                    onPressed: () => _showReceipt(context, p),
                    style: TextButton.styleFrom(
                      foregroundColor: DailyColors.burgundy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _th(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: DailyColors.gray,
      ),
    ),
  );

  Widget _td(String text, {Color? color, bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color ?? DailyColors.charcoal,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _mobileTransactionItem(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final date = _date(
      payment['payment_date'] ?? payment['billing_period_end'],
    );
    final ref =
        payment['transaction_reference'] ??
        'REF-${payment['payment_id'] ?? '—'}';
    final method = '${payment['payment_method'] ?? 'UPI'}';
    final amount = _amount(payment['amount'] ?? payment['total_amount']);
    final status =
        '${payment['payment_status'] ?? payment['bill_status'] ?? 'SUCCESS'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
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
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: DailyColors.gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '$method • $ref',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.burgundy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: DailyColors.divider, height: 1),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showReceipt(context, payment),
              icon: const Icon(
                Icons.receipt_outlined,
                size: 14,
                color: DailyColors.burgundy,
              ),
              label: const Text(
                'View Receipt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.burgundy,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Active Subscriptions'),
        const SizedBox(height: 8),
        if (_subscriptions.isEmpty)
          const Text(
            'No active subscriptions found.',
            style: TextStyle(color: DailyColors.gray, fontSize: 13),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _subscriptions.map((s) {
              final name = '${s['newspaper_name'] ?? 'Newspaper'}';
              final price = _amount(s['agreed_price']);
              return Container(
                width: 155,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DailyColors.white,
                  border: Border.all(color: DailyColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NewspaperThumb(title: name, width: 34),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$price / day',
                      style: const TextStyle(
                        fontSize: 11,
                        color: DailyColors.gray,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHelpBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: DailyColors.burgundy, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions about your bill?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Submit a billing dispute or question via Service Requests.',
                  style: TextStyle(
                    fontSize: 11,
                    color: DailyColors.gray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceRequestScreen()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: DailyColors.burgundy,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'GET HELP',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> payment) {
    final ref =
        payment['transaction_reference'] ??
        'REF-${payment['payment_id'] ?? '—'}';
    final amount = _amount(payment['amount'] ?? payment['total_amount']);
    final date = _date(
      payment['payment_date'] ?? payment['billing_period_end'],
    );
    final method = '${payment['payment_method'] ?? 'Online UPI'}';
    final status =
        '${payment['payment_status'] ?? payment['bill_status'] ?? 'SUCCESS'}'
            .toUpperCase();
    final billId = payment['bill_id'] != null ? '#${payment['bill_id']}' : '—';
    final periodStart = _date(payment['billing_period_start']);
    final periodEnd = _date(payment['billing_period_end']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DailyColors.white,
        shape: const RoundedRectangleBorder(),
        title: const Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: DailyColors.burgundy,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Payment Receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow('Bill Number', billId),
            _receiptRow('Transaction Ref', '$ref'),
            _receiptRow('Payment Date', date),
            if (periodStart != '—' && periodEnd != '—')
              _receiptRow('Billing Period', '$periodStart to $periodEnd'),
            _receiptRow('Payment Method', method),
            _receiptRow('Status', status),
            const Divider(color: DailyColors.divider, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: DailyColors.burgundy,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                color: DailyColors.burgundy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: DailyColors.gray),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> bill, String method) async {
    try {
      final customerId = await SessionService.getCustomerId();
      if (customerId == null) {
        throw const CustomerApiException(
          'Customer session not found. Please sign in again.',
        );
      }

      final billId = bill['bill_id'] is int
          ? bill['bill_id'] as int
          : int.tryParse('${bill['bill_id']}');
      final amountVal = bill['total_amount'] ?? bill['amount'];
      final double? parsedAmount = amountVal != null
          ? double.tryParse('$amountVal')
          : null;

      final res = await _api.payBill(
        customerId: customerId,
        billId: billId,
        amount: parsedAmount,
        paymentMethod: method,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Bill paid successfully.'),
          backgroundColor: DailyColors.burgundy,
        ),
      );

      await _load();

      if (mounted && res['payment'] is Map) {
        _showReceipt(context, Map<String, dynamic>.from(res['payment'] as Map));
      }
    } on CustomerApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red[800]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process payment. Please try again.'),
        ),
      );
    }
  }

  void _showPayModal(BuildContext context, Map<String, dynamic> bill) {
    final amount = _amount(bill['total_amount'] ?? bill['amount']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DailyColors.white,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'Pay Bill (Simulated / Demo Mode)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DailyColors.cream,
                border: Border.all(color: DailyColors.divider),
              ),
              child: const Text(
                'Demo Payment: Settles bill in DAILY database without charging real money.',
                style: TextStyle(
                  fontSize: 11,
                  color: DailyColors.gray,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount Due: $amount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DailyColors.burgundy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select payment option:',
              style: TextStyle(fontSize: 13, color: DailyColors.gray),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: DailyColors.burgundy,
              ),
              title: const Text(
                'UPI (Simulated Instant Transfer)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Simulates real-time settlement',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(context);
                _processPayment(bill, 'UPI');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.payments_outlined,
                color: DailyColors.burgundy,
              ),
              title: const Text(
                'Cash on Delivery (Partner Collected)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Recorded for delivery partner verification',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(context);
                _processPayment(bill, 'CASH');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: DailyColors.gray),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: DailyColors.burgundy,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    ),
  );
}
