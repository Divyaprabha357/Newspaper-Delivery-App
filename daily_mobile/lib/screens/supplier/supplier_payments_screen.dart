import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'supplier_design_system.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  const SupplierPaymentsScreen({super.key});

  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tab = 0;
  String _status = 'All Status';

  final _bills = const [
    _Bill('R. Sharma', '\u20B9850', '10 Oct 2026', 'Paid', 'Customer bill preview'),
    _Bill('S. Mehta', '\u20B9450', '11 Oct 2026', 'Pending', 'Customer bill preview'),
    _Bill('A. Verma', '\u20B9600', '12 Oct 2026', 'Paid', 'Customer bill preview'),
    _Bill('P. Singh', '\u20B9750', '15 Oct 2026', 'Overdue', 'Customer bill preview'),
  ];

  final _payouts = const [
    _Payout('R. Kumar', 'September 2026', '\u20B93,200', 'Paid', '5 Oct 2026'),
    _Payout('A. Singh', 'September 2026', '\u20B92,800', 'Paid', '5 Oct 2026'),
    _Payout('S. Patil', 'September 2026', '\u20B93,600', 'Paid', '6 Oct 2026'),
    _Payout('V. Rao', 'September 2026', '\u20B92,400', 'Pending', '\u2014'),
    _Payout('R. Khan', 'September 2026', '\u20B93,200', 'Pending', '\u2014'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Bill> get _filteredBills {
    final query = _searchController.text.trim().toLowerCase();
    return _bills.where((bill) {
      return (query.isEmpty || bill.customer.toLowerCase().contains(query)) &&
          (_status == 'All Status' || bill.status == _status);
    }).toList();
  }

  List<_Payout> get _filteredPayouts {
    final query = _searchController.text.trim().toLowerCase();
    return _payouts.where((payout) {
      final matchesSearch = query.isEmpty ||
          payout.partner.toLowerCase().contains(query) ||
          payout.period.toLowerCase().contains(query);
      return matchesSearch &&
          (_status == 'All Status' || payout.status == _status);
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _status = 'All Status';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bills = _filteredBills;
    final payouts = _filteredPayouts;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
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
            'Payments',
            style: TextStyle(
              color: DailyColors.charcoal,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _summaryRow(),
          const SizedBox(height: 18),
          _tabs(),
          const SizedBox(height: 10),
          _toolbar(),
          const SizedBox(height: 12),
          _tab == 0 ? _billingTable(bills) : _payoutTable(payouts),
          if ((_tab == 0 && bills.isEmpty) || (_tab == 1 && payouts.isEmpty))
            _emptyState(),
          const SizedBox(height: 9),
          const Text(
            'Illustrative preview data only. No payments or payouts can be processed here.',
            style: TextStyle(fontSize: 15, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryCard(
            icon: Icons.receipt_long_outlined,
            title: 'Customer Payments (Collected)',
            amount: _currencyTotal(_bills.map((bill) => bill.amount)),
            detail: 'of \u20B926,000 expected',
          ),
          _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Partner Payouts (Paid)',
            amount: _currencyTotal(
              _payouts
                  .where((payout) => payout.status == 'Paid')
                  .map((payout) => payout.amount),
            ),
            detail: 'of \u20B915,200 due',
          ),
        ];
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 9),
              cards[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  String _currencyTotal(Iterable<String> values) {
    final total = values.fold<int>(0, (sum, value) {
      return sum + int.parse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    });
    return supplierCurrency(total);
  }

  Widget _tabs() {
    const labels = ['Customer Billing', 'Partner Payments'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: TextButton(
              onPressed: () => setState(() {
                _tab = i;
                _status = 'All Status';
                _searchController.clear();
              }),
              style: TextButton.styleFrom(
                backgroundColor:
                    _tab == i ? DailyColors.burgundy : DailyColors.white,
                foregroundColor: _tab == i ? Colors.white : DailyColors.charcoal,
                side: const BorderSide(color: DailyColors.divider),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(
                labels[i].toUpperCase(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toolbar() {
    final statuses = _tab == 0
        ? const ['All Status', 'Paid', 'Pending', 'Overdue']
        : const ['All Status', 'Paid', 'Pending'];
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search customer or transaction...',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            onChanged: (value) => setState(() => _status = value!),
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            ),
            items: statuses
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status, style: const TextStyle(fontSize: 18)),
                  ),
                )
                .toList(),
          ),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text(
            'CLEAR FILTERS',
            style: TextStyle(
              color: DailyColors.burgundy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _billingTable(List<_Bill> bills) {
    return _table(
      widths: const [3.8, 2.0, 2.0, 2.2],
      headers: const ['CUSTOMER', 'AMOUNT', 'DUE DATE', 'STATUS'],
      rows: bills.map((bill) {
        return _row(
          [
            _cell(bill.customer, bold: true),
            _cell(supplierCurrency(bill.amount), alignRight: true),
            _cell(bill.dueDate),
            _statusCell(bill.status),
          ],
          () => _showDetails(
            bill.customer,
            [
              'Customer: ${bill.customer}',
              'Amount: ${supplierCurrency(bill.amount)}',
              'Due date: ${bill.dueDate}',
              'Status: ${bill.status}',
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _payoutTable(List<_Payout> payouts) {
    return _table(
      widths: const [2.6, 2.2, 1.8, 1.6, 1.8],
      headers: const [
        'DELIVERY PARTNER',
        'PAYMENT PERIOD',
        'AMOUNT',
        'STATUS',
        'PAID DATE',
      ],
      rows: payouts.map((payout) {
        return _row(
          [
            _cell(payout.partner, bold: true),
            _cell(payout.period),
            _cell(supplierCurrency(payout.amount), alignRight: true),
            _statusCell(payout.status),
            _cell(payout.paidDate),
          ],
          () => _showDetails(
            payout.partner,
            [
              'Delivery partner: ${payout.partner}',
              'Payment period: ${payout.period}',
              'Amount: ${supplierCurrency(payout.amount)}',
              'Status: ${payout.status}',
              'Paid date: ${payout.paidDate}',
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _table({
    required List<double> widths,
    required List<String> headers,
    required List<TableRow> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Table(
        columnWidths: {
          for (var i = 0; i < widths.length; i++) i: FlexColumnWidth(widths[i]),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: DailyColors.divider),
        ),
        children: [
          TableRow(
            children: headers.map(_headerCell).toList(),
          ),
          ...rows,
        ],
      ),
    );
  }

  TableRow _row(List<Widget> cells, VoidCallback onTap) {
    return TableRow(
      children: cells
          .map((cell) => InkWell(onTap: onTap, child: cell))
          .toList(),
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 8, 11),
      child: Text(
        label,
        style: const TextStyle(
          color: DailyColors.gray,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cell(String value, {bool bold = false, bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: DailyColors.charcoal,
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _statusCell(String status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          color: color.withValues(alpha: .12),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return DailyColors.success;
      case 'Pending':
        return DailyColors.warning;
      case 'Overdue':
        return DailyColors.burgundy;
      default:
        return DailyColors.gray;
    }
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 30, color: DailyColors.gray),
          SizedBox(height: 9),
          Text(
            'No payment records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search or filters.',
            style: TextStyle(fontSize: 16, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(String title, List<String> details) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details
              .map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(detail, style: const TextStyle(fontSize: 18)),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: DailyColors.burgundy),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final String detail;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: DailyColors.tan,
            child: Icon(icon, color: DailyColors.burgundy, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: DailyColors.gray),
                ),
                const SizedBox(height: 5),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DailyColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 15, color: DailyColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bill {
  final String customer;
  final String amount;
  final String dueDate;
  final String status;
  final String detail;

  const _Bill(this.customer, this.amount, this.dueDate, this.status, this.detail);
}

class _Payout {
  final String partner;
  final String period;
  final String amount;
  final String status;
  final String paidDate;

  const _Payout(this.partner, this.period, this.amount, this.status, this.paidDate);
}
