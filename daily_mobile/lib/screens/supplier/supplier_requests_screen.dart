import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SupplierRequestsScreen extends StatefulWidget {
  const SupplierRequestsScreen({super.key});

  @override
  State<SupplierRequestsScreen> createState() => _SupplierRequestsScreenState();
}

class _SupplierRequestsScreenState extends State<SupplierRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tab = 0;
  String _status = 'All Status';
  DateTimeRange? _dateRange;

  final _requests = [
    _RequestRecord('REQ-1001', 'R. Sharma', 'Change Address', DateTime(2026, 10, 10), 'Submitted', 'Customer requested an address update.',),
    _RequestRecord('REQ-1002', 'S. Mehta', 'Change Newspaper', DateTime(2026, 10, 11), 'Under Review', 'Customer requested a newspaper change.',),
    _RequestRecord('REQ-1003', 'A. Verma', 'Change Delivery Time', DateTime(2026, 10, 12), 'In Progress', 'Customer requested a delivery-time change.',),
    _RequestRecord('REQ-1004', 'P. Singh', 'Newspaper Availability', DateTime(2026, 10, 12), 'Completed', 'Customer asked about newspaper availability.',),
    _RequestRecord('REQ-1005', 'K. Iyer', 'Subscription Query', DateTime(2026, 10, 13), 'Submitted', 'Customer requested subscription information.',),
  ];

  final _complaints = [
    _ComplaintRecord('CMP-2001', 'R. Sharma', 'The Times of India', DateTime(2026, 10, 10), 'Missed Delivery', 'Submitted', 'The newspaper was not received.'),
    _ComplaintRecord('CMP-2002', 'S. Mehta', 'Hindustan Times', DateTime(2026, 10, 11), 'Late Delivery', 'Under Review', 'The newspaper arrived later than expected.'),
    _ComplaintRecord('CMP-2003', 'A. Verma', 'Dainik Jagran', DateTime(2026, 10, 12), 'Wrong Newspaper', 'In Progress', 'The received newspaper did not match the subscription.'),
    _ComplaintRecord('CMP-2004', 'P. Singh', 'The Hindu', DateTime(2026, 10, 12), 'Damaged Newspaper', 'Completed', 'The delivered newspaper was damaged.'),
    _ComplaintRecord('CMP-2005', 'K. Iyer', 'Loksatta', DateTime(2026, 10, 13), 'Missed Delivery', 'Submitted', 'The newspaper was not received.'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RequestRecord> get _filteredRequests => _requests
      .where((item) => _matches(item.customer, item.type, item.id, item.status, item.submitted))
      .toList();

  List<_ComplaintRecord> get _filteredComplaints => _complaints
      .where((item) => _matches(
            item.customer,
            '${item.newspaper} ${item.type}',
            item.id,
            item.status,
            item.deliveryDate,
          ))
      .toList();

  bool _matches(String customer, String description, String id, String status, DateTime date) {
    final query = _searchController.text.trim().toLowerCase();
    final matchesSearch = query.isEmpty ||
        customer.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query) ||
        id.toLowerCase().contains(query);
    final matchesStatus = _status == 'All Status' || status == _status;
    final matchesDate = _dateRange == null ||
        !date.isBefore(_dateRange!.start) &&
            !date.isAfter(_dateRange!.end.add(const Duration(days: 1)));
    return matchesSearch && matchesStatus && matchesDate;
  }

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      currentDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: DailyColors.burgundy),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _status = 'All Status';
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;
    final complaints = _filteredComplaints;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY DISTRIBUTION', style: TextStyle(color: DailyColors.burgundy, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.7)),
          const SizedBox(height: 7),
          const Text('Requests & Complaints', style: TextStyle(color: DailyColors.charcoal, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _summary(),
          const SizedBox(height: 18),
          _tabs(),
          const SizedBox(height: 10),
          _toolbar(),
          const SizedBox(height: 12),
          _tab == 0 ? _requestsTable(requests) : _complaintsTable(complaints),
          if ((_tab == 0 && requests.isEmpty) || (_tab == 1 && complaints.isEmpty)) _emptyState(),
          const SizedBox(height: 9),
          const Text('Illustrative preview data only. No request or complaint actions are available here.', style: TextStyle(fontSize: 15, color: DailyColors.gray)),
        ],
      ),
    );
  }

  Widget _summary() {
    final openRequests = _requests.where((item) => item.status != 'Completed').length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryCard(Icons.inbox_outlined, 'Open Requests', '$openRequests', 'Awaiting review'),
          _SummaryCard(Icons.report_problem_outlined, 'Delivery Complaints', '${_complaints.where((item) => item.status != 'Completed').length}', 'Reported by customers'),
          _SummaryCard(Icons.update_outlined, 'Recently Updated', '5', 'In the selected period'),
        ];
        if (constraints.maxWidth < 720) {
          return Column(children: [cards[0], const SizedBox(height: 8), cards[1], const SizedBox(height: 8), cards[2]]);
        }
        return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 10)]]);
      },
    );
  }

  Widget _tabs() {
    const labels = ['Customer Requests', 'Delivery Complaints'];
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
                backgroundColor: _tab == i ? DailyColors.burgundy : DailyColors.white,
                foregroundColor: _tab == i ? Colors.white : DailyColors.charcoal,
                side: const BorderSide(color: DailyColors.divider),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(labels[i].toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _toolbar() {
    final statuses = const ['All Status', 'Submitted', 'Under Review', 'In Progress', 'Completed'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        final search = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search customer or request...',
            prefixIcon: Icon(Icons.search, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          ),
        );
        final status = DropdownButtonFormField<String>(
          initialValue: _status,
          onChanged: (value) => setState(() => _status = value!),
          isExpanded: true,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11)),
          items: statuses.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 18)))).toList(),
        );
        final date = OutlinedButton.icon(
          onPressed: _chooseDateRange,
          icon: const Icon(Icons.calendar_today_outlined, size: 15),
          label: Text(_dateRange == null ? 'Date range' : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DailyColors.charcoal,
            side: const BorderSide(color: DailyColors.divider),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 8),
                  Expanded(child: date),
                ],
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
        return Row(children: [Expanded(flex: 5, child: search), const SizedBox(width: 8), SizedBox(width: 155, child: status), const SizedBox(width: 8), date, TextButton(onPressed: _clearFilters, child: const Text('CLEAR FILTERS', style: TextStyle(color: DailyColors.burgundy, fontSize: 15, fontWeight: FontWeight.bold)))]);
      },
    );
  }

  Widget _requestsTable(List<_RequestRecord> records) {
    return _table(
      widths: const [1.5, 2.3, 2.4, 1.8, 2.0],
      headers: const ['REQUEST ID', 'CUSTOMER', 'REQUEST TYPE', 'SUBMITTED', 'STATUS'],
      rows: records.map((item) => _row([
        _cell(item.id, bold: true),
        _cell(item.customer),
        _cell(item.type),
        _cell(_formatDate(item.submitted)),
        _statusCell(item.status),
      ], () => _details(item.id, [item.customer, item.type, _formatDate(item.submitted), item.status, item.description]))).toList(),
    );
  }

  Widget _complaintsTable(List<_ComplaintRecord> records) {
    return _table(
      widths: const [1.4, 2.0, 2.0, 1.6, 1.8, 1.5],
      headers: const ['COMPLAINT ID', 'CUSTOMER', 'NEWSPAPER', 'DELIVERY DATE', 'COMPLAINT TYPE', 'STATUS'],
      rows: records.map((item) => _row([
        _cell(item.id, bold: true),
        _cell(item.customer),
        _cell(item.newspaper),
        _cell(_formatDate(item.deliveryDate)),
        _cell(item.type),
        _statusCell(item.status),
      ], () => _details(item.id, [item.customer, item.newspaper, _formatDate(item.deliveryDate), item.type, item.status, item.description]))).toList(),
    );
  }

  Widget _table({required List<double> widths, required List<String> headers, required List<TableRow> rows}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
      child: Table(
        columnWidths: {for (var i = 0; i < widths.length; i++) i: FlexColumnWidth(widths[i])},
        border: const TableBorder(horizontalInside: BorderSide(color: DailyColors.divider)),
        children: [TableRow(children: headers.map(_headerCell).toList()), ...rows],
      ),
    );
  }

  TableRow _row(List<Widget> cells, VoidCallback onTap) => TableRow(children: cells.map((cell) => InkWell(onTap: onTap, child: cell)).toList());

  Widget _headerCell(String value) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 13, 8, 11),
        child: Text(value, style: const TextStyle(color: DailyColors.gray, fontSize: 14, fontWeight: FontWeight.bold)),
      );

  Widget _cell(String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: DailyColors.charcoal, fontSize: 16, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      );

  Widget _statusCell(String status) {
    final color = switch (status) {
      'Completed' => DailyColors.success,
      'Under Review' => DailyColors.warning,
      'In Progress' => DailyColors.burgundy,
      _ => DailyColors.gray,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          color: color.withValues(alpha: .12),
          child: Text(status, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 42),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: const Column(
          children: [
            Icon(Icons.forum_outlined, size: 30, color: DailyColors.gray),
            SizedBox(height: 9),
            Text('No requests or complaints found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Try changing your search or filters.', style: TextStyle(fontSize: 16, color: DailyColors.gray)),
          ],
        ),
      );

  Future<void> _details(String title, List<String> details) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...details.map((detail) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(detail, style: const TextStyle(fontSize: 18)))),
              const SizedBox(height: 5),
              const Text('Illustrative preview. This record is read-only.', style: TextStyle(fontSize: 15, color: DailyColors.gray)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: DailyColors.burgundy))),
          ],
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _SummaryCard(this.icon, this.title, this.value, this.detail);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: Row(
          children: [
            Container(width: 40, height: 40, color: DailyColors.tan, child: Icon(icon, color: DailyColors.burgundy, size: 20)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: DailyColors.gray)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 15, color: DailyColors.gray)),
              ],
            ),
          ],
        ),
      );
}

class _RequestRecord {
  final String id;
  final String customer;
  final String type;
  final DateTime submitted;
  final String status;
  final String description;

  const _RequestRecord(this.id, this.customer, this.type, this.submitted, this.status, this.description);
}

class _ComplaintRecord {
  final String id;
  final String customer;
  final String newspaper;
  final DateTime deliveryDate;
  final String type;
  final String status;
  final String description;

  const _ComplaintRecord(this.id, this.customer, this.newspaper, this.deliveryDate, this.type, this.status, this.description);
}


