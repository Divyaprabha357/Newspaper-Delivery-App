import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  const SupplierPaymentsScreen({super.key});
  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int? _number(dynamic value) => int.tryParse(value?.toString() ?? '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final supplierId = _number(session?['supplier_id'] ?? session?['id']);
      final userId = _number(session?['user_id'] ?? session?['id']);

      if (userId == null && supplierId == null) {
        throw const RoleApiException('Supplier session is unavailable. Please sign in again.');
      }

      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierPayments(userId ?? supplierId!, supplierId: supplierId);

      final values = response['payments'];
      if (values is! List) {
        throw const RoleApiException('The server returned no payment list.');
      }

      final records = values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final summary = response['summary'] is Map
          ? Map<String, dynamic>.from(response['summary'] as Map)
          : null;

      if (mounted) {
        setState(() {
          _records = records;
          _summary = summary;
          _loading = false;
        });
      }
    } on RoleApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load payments right now. Please check your connection and retry.';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _records.where((r) {
      final matchQuery = q.isEmpty ||
          [
            r['customer_name'],
            r['bill_id'],
            r['payment_id'],
            r['bill_status'],
            r['payment_status'],
            r['payment_method'],
            r['transaction_reference'],
            r['newspaper_names'],
          ].any((v) => v != null && v.toString().toLowerCase().contains(q));

      if (!matchQuery) return false;

      if (_statusFilter == 'ALL') return true;
      final paymentStatus = (r['payment_status'] ?? '').toString().toUpperCase();
      final billStatus = (r['bill_status'] ?? '').toString().toUpperCase();

      if (_statusFilter == 'SUCCESS') {
        return paymentStatus == 'SUCCESS' || billStatus == 'PAID';
      }
      if (_statusFilter == 'PENDING') {
        return paymentStatus == 'PENDING' || paymentStatus == 'FAILED' || billStatus == 'PENDING';
      }
      return true;
    }).toList();
  }

  double get _totalEarnings {
    if (_summary?['total_earnings'] != null) {
      return double.tryParse('${_summary!['total_earnings']}') ?? 0.0;
    }
    return _records.fold<double>(0.0, (sum, r) {
      final val = double.tryParse('${r['supplier_item_total'] ?? r['amount'] ?? r['total_amount'] ?? 0}');
      return sum + (val ?? 0.0);
    });
  }

  double get _amountReceived {
    if (_summary?['amount_received'] != null) {
      return double.tryParse('${_summary!['amount_received']}') ?? 0.0;
    }
    return _records.fold<double>(0.0, (sum, r) {
      final status = (r['payment_status'] ?? '').toString().toUpperCase();
      final billStatus = (r['bill_status'] ?? '').toString().toUpperCase();
      if (status == 'SUCCESS' || billStatus == 'PAID') {
        final val = double.tryParse('${r['amount'] ?? r['supplier_item_total'] ?? 0}');
        return sum + (val ?? 0.0);
      }
      return sum;
    });
  }

  double get _pendingAmount {
    if (_summary?['pending_amount'] != null) {
      return double.tryParse('${_summary!['pending_amount']}') ?? 0.0;
    }
    return _totalEarnings - _amountReceived;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'PAID':
        return DailyColors.success;
      case 'PENDING':
        return DailyColors.warning;
      case 'FAILED':
        return DailyColors.burgundy;
      default:
        return DailyColors.charcoal;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Unavailable';
    final str = value.toString().split('T').first;
    return str;
  }

  void _showPaymentDetails(Map<String, dynamic> r) {
    final customer = r['customer_name']?.toString() ?? 'Unavailable';
    final billId = r['bill_id']?.toString() ?? '—';
    final paymentId = r['payment_id']?.toString() ?? '—';
    final txnRef = r['transaction_reference']?.toString() ?? 'Unavailable';
    final amount = r['amount'] ?? r['supplier_item_total'] ?? r['total_amount'] ?? '0.00';
    final method = r['payment_method']?.toString() ?? 'Standard';
    final paymentStatus = (r['payment_status'] ?? 'PENDING').toString().toUpperCase();
    final billStatus = (r['bill_status'] ?? 'PENDING').toString().toUpperCase();
    final paymentDate = _formatDate(r['payment_date'] ?? r['generated_at']);
    final periodStart = _formatDate(r['billing_period_start']);
    final periodEnd = _formatDate(r['billing_period_end']);
    final newspapers = r['newspaper_names']?.toString() ?? 'Assigned Edition';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DailyColors.white,
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: DailyColors.burgundy),
            const SizedBox(width: 10),
            const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Customer', customer),
              _detailRow('Newspapers', newspapers),
              _detailRow('Bill ID', '#BILL-$billId'),
              if (paymentId != '—') _detailRow('Payment ID', '#PAY-$paymentId'),
              _detailRow('Amount', '₹$amount', isBold: true),
              _detailRow('Billing Period', '$periodStart to $periodEnd'),
              _detailRow('Payment Status', paymentStatus, statusColor: _statusColor(paymentStatus)),
              _detailRow('Bill Status', billStatus, statusColor: _statusColor(billStatus)),
              _detailRow('Payment Method', method),
              _detailRow('Transaction Ref', txnRef),
              _detailRow('Date', paymentDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: DailyColors.gray, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: statusColor ?? DailyColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return RefreshIndicator(
      color: DailyColors.burgundy,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DAILY DISTRIBUTION',
              style: TextStyle(
                color: DailyColors.burgundy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payments',
                  style: TextStyle(
                    color: DailyColors.charcoal,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: DailyColors.burgundy),
                  tooltip: 'Refresh',
                  onPressed: _load,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics Summary Cards
            if (_error == null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final earningsText = _loading ? '—' : '₹${_totalEarnings.toStringAsFixed(2)}';
                  final receivedText = _loading ? '—' : '₹${_amountReceived.toStringAsFixed(2)}';
                  final pendingText = _loading ? '—' : '₹${_pendingAmount.toStringAsFixed(2)}';

                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: _metricCard('TOTAL EARNINGS', earningsText, DailyColors.charcoal)),
                            const SizedBox(width: 12),
                            Expanded(child: _metricCard('AMOUNT RECEIVED', receivedText, DailyColors.success)),
                            const SizedBox(width: 12),
                            Expanded(child: _metricCard('PENDING AMOUNT', pendingText, DailyColors.warning)),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _metricCard('TOTAL EARNINGS', earningsText, DailyColors.charcoal)),
                                const SizedBox(width: 10),
                                Expanded(child: _metricCard('RECEIVED', receivedText, DailyColors.success)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _metricCard('PENDING AMOUNT', pendingText, DailyColors.warning),
                          ],
                        );
                },
              ),

            const SizedBox(height: 18),

            // Search Bar
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search customer, bill, newspaper, reference...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'All Records'),
                  const SizedBox(width: 8),
                  _filterChip('SUCCESS', 'Paid / Success'),
                  const SizedBox(width: 8),
                  _filterChip('PENDING', 'Pending / Unpaid'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // State Handling
            if (_loading)
              const _StateMessage(
                icon: Icons.hourglass_empty,
                text: 'Loading payments...',
              )
            else if (_error != null)
              _StateMessage(
                icon: Icons.error_outline,
                text: _error!,
                retry: _load,
              )
            else if (_records.isEmpty)
              const _StateMessage(
                icon: Icons.payments_outlined,
                text: 'No payment records yet',
              )
            else if (rows.isEmpty)
              const _StateMessage(
                icon: Icons.search_off,
                text: 'No matching payment records found.',
              )
            else
              _tableOrList(rows),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : DailyColors.charcoal,
        ),
      ),
      selected: isSelected,
      selectedColor: DailyColors.burgundy,
      backgroundColor: DailyColors.white,
      side: const BorderSide(color: DailyColors.divider),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableOrList(List<Map<String, dynamic>> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return _table(rows);
        }
        return _cardsList(rows);
      },
    );
  }

  Widget _cardsList(List<Map<String, dynamic>> rows) {
    return Column(
      children: rows.map((r) {
        final customer = r['customer_name']?.toString() ?? 'Unavailable';
        final amount = r['amount'] ?? r['supplier_item_total'] ?? r['total_amount'] ?? '0.00';
        final status = (r['payment_status'] ?? r['bill_status'] ?? 'PENDING').toString().toUpperCase();
        final date = _formatDate(r['payment_date'] ?? r['generated_at']);
        final newspapers = r['newspaper_names']?.toString() ?? 'Newspaper Edition';
        final billId = r['bill_id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: DailyColors.white,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: DailyColors.divider),
          ),
          child: InkWell(
            onTap: () => _showPaymentDetails(r),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          customer,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          border: Border.all(color: _statusColor(status), width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    newspapers,
                    style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#BILL-$billId • $date',
                        style: const TextStyle(fontSize: 11, color: DailyColors.gray),
                      ),
                      Text(
                        '₹$amount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DailyColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _table(List<Map<String, dynamic>> rows) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: DailyColors.divider),
          ),
          children: [
            const TableRow(
              children: [
                _Header('CUSTOMER'),
                _Header('EDITION'),
                _Header('AMOUNT'),
                _Header('STATUS'),
                _Header('DATE'),
                _Header('ACTION'),
              ],
            ),
            ...rows.map(
              (r) {
                final status = (r['payment_status'] ?? r['bill_status'] ?? 'PENDING').toString().toUpperCase();
                return TableRow(
                  children: [
                    _cell(r['customer_name']?.toString() ?? 'Unavailable', bold: true),
                    _cell(r['newspaper_names']?.toString() ?? '—'),
                    _cell('₹${r['amount'] ?? r['supplier_item_total'] ?? r['total_amount'] ?? '0.00'}', alignRight: true, bold: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          border: Border.all(color: _statusColor(status), width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ),
                    _cell(_formatDate(r['payment_date'] ?? r['generated_at'])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: TextButton(
                        onPressed: () => _showPaymentDetails(r),
                        child: const Text('DETAILS', style: TextStyle(fontSize: 11, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

  Widget _cell(String value, {bool bold = false, bool alignRight = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: DailyColors.charcoal,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 13, 8, 11),
        child: Text(
          text,
          style: const TextStyle(
            color: DailyColors.gray,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? retry;
  const _StateMessage({required this.icon, required this.text, this.retry});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: DailyColors.gray),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (retry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: retry,
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: DailyColors.burgundy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
