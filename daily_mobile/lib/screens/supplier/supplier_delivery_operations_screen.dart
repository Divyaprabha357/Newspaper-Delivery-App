import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SupplierDeliveryOperationsScreen extends StatefulWidget {
  const SupplierDeliveryOperationsScreen({super.key});

  @override
  State<SupplierDeliveryOperationsScreen> createState() =>
      _SupplierDeliveryOperationsScreenState();
}

class _SupplierDeliveryOperationsScreenState
    extends State<SupplierDeliveryOperationsScreen> {
  int _tab = 0;
  DateTime _selectedDate = DateTime.now();

  final _routes = const [
    _RouteRecord('Route 1', 'Andheri', 'R. Kumar', 'On Time', .80),
    _RouteRecord('Route 2', 'Bandra', 'A. Singh', 'Delayed', .40),
    _RouteRecord('Route 3', 'Powai', 'S. Patil', 'Completed', 1),
    _RouteRecord('Route 4', 'Thane', 'V. Rao', 'On Time', .70),
    _RouteRecord('Route 5', 'Dadar', 'R. Khan', 'On Time', .90),
  ];

  final _partners = const [
    _PartnerRecord('R. Kumar', 'Route 1', 'Andheri', 120, 96, 24, 'On Duty'),
    _PartnerRecord('A. Singh', 'Route 2', 'Bandra', 100, 40, 60, 'On Duty'),
    _PartnerRecord('S. Patil', 'Route 3', 'Powai', 85, 85, 0, 'Completed'),
    _PartnerRecord('V. Rao', 'Route 4', 'Thane', 110, 77, 33, 'On Duty'),
    _PartnerRecord('R. Khan', 'Route 5', 'Dadar', 90, 81, 9, 'On Duty'),
  ];

  final _progress = const [
    _ProgressRecord('R. Sharma', 'Andheri', 'The Times of India', 'R. Kumar', '6:30 AM', '6:42 AM', 'Delivered'),
    _ProgressRecord('S. Mehta', 'Bandra', 'Hindustan Times', 'A. Singh', '6:45 AM', '\u2014', 'Pending'),
    _ProgressRecord('A. Verma', 'Powai', 'Dainik Jagran', 'S. Patil', '6:30 AM', '6:35 AM', 'Delivered'),
    _ProgressRecord('P. Singh', 'Dadar', 'The Hindu', 'R. Khan', '7:00 AM', '\u2014', 'Delayed'),
    _ProgressRecord('K. Iyer', 'Thane', 'Loksatta', 'V. Rao', '6:45 AM', '6:48 AM', 'Delivered'),
  ];

  String _date(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: DailyColors.burgundy,
              ),
        ),
        child: child!,
      ),
    );
    if (chosen != null) setState(() => _selectedDate = chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY DISTRIBUTION',
                      style: TextStyle(
                        color: DailyColors.burgundy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.7,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Delivery Operations',
                      style: TextStyle(
                        color: DailyColors.charcoal,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: Text(_date(_selectedDate)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DailyColors.charcoal,
                  side: const BorderSide(color: DailyColors.divider),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        _tabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
            child: _tabContent(),
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['Routes', 'Delivery Partners', 'Delivery Progress'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: TextButton(
                onPressed: () => setState(() => _tab = i),
                style: TextButton.styleFrom(
                  backgroundColor: _tab == i ? DailyColors.burgundy : DailyColors.white,
                  foregroundColor: _tab == i ? Colors.white : DailyColors.charcoal,
                  side: const BorderSide(color: DailyColors.divider),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: Text(
                  labels[i].toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    if (_tab == 0) return _routesTable();
    if (_tab == 1) return _partnersTable();
    return _progressTable();
  }

  Widget _routesTable() {
    return _table(
      widths: const [1.2, 1.7, 2.2, 1.7, 3.2],
      headers: const ['ROUTE', 'AREA', 'DELIVERY PARTNER', 'STATUS', 'PROGRESS'],
      rows: _routes.map((route) {
        return _row([
          _textCell(route.route, bold: true),
          _textCell(route.area),
          _textCell(route.partner),
          _statusCell(route.status),
          _progressCell(route.progress, route.status),
        ], () => _showDetails(
          'Route ${route.route}',
          [
            'Area: ${route.area}',
            'Assigned partner: ${route.partner}',
            'Status: ${route.status}',
            'Progress: ${(route.progress * 100).round()}%',
            'Date: ${_date(_selectedDate)}',
          ],
        ));
      }).toList(),
    );
  }

  Widget _partnersTable() {
    return _table(
      widths: const [2.1, 1.5, 1.5, 1.1, 1.1, 1.1, 1.4],
      headers: const ['DELIVERY PARTNER', 'ASSIGNED ROUTE', 'AREA', 'DELIVERIES', 'DELIVERED', 'PENDING', 'STATUS'],
      rows: _partners.map((partner) {
        return _row([
          _textCell(partner.name, bold: true),
          _textCell(partner.route),
          _textCell(partner.area),
          _textCell('${partner.deliveries}'),
          _textCell('${partner.delivered}'),
          _textCell('${partner.pending}'),
          _statusCell(partner.status),
        ], () => _showDetails(
          partner.name,
          [
            'Assigned route: ${partner.route}',
            'Area: ${partner.area}',
            'Deliveries: ${partner.deliveries}',
            'Delivered: ${partner.delivered}',
            'Pending: ${partner.pending}',
            'Status: ${partner.status}',
          ],
        ));
      }).toList(),
    );
  }

  Widget _progressTable() {
    return _table(
      widths: const [1.5, 1.2, 2.1, 1.6, 1.2, 1.1, 1.3],
      headers: const ['CUSTOMER', 'AREA', 'NEWSPAPER', 'DELIVERY PARTNER', 'EXPECTED', 'ACTUAL', 'STATUS'],
      rows: _progress.map((item) {
        return _row([
          _textCell(item.customer, bold: true),
          _textCell(item.area),
          _textCell(item.newspaper),
          _textCell(item.partner),
          _textCell(item.expected),
          _textCell(item.actual),
          _statusCell(item.status),
        ], () => _showDetails(
          item.customer,
          [
            'Area: ${item.area}',
            'Newspaper: ${item.newspaper}',
            'Delivery partner: ${item.partner}',
            'Expected time: ${item.expected}',
            'Actual time: ${item.actual}',
            'Status: ${item.status}',
          ],
        ));
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
            children: headers.map((header) => _headerCell(header)).toList(),
          ),
          ...rows,
        ],
      ),
    );
  }

  TableRow _row(List<Widget> cells, VoidCallback onTap) {
    return TableRow(
      children: cells
          .map(
            (cell) => InkWell(
              onTap: onTap,
              child: cell,
            ),
          )
          .toList(),
    );
  }

  Widget _headerCell(String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 13, 8, 11),
      child: Text(
        value,
        style: const TextStyle(
          color: DailyColors.gray,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textCell(String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: DailyColors.charcoal,
          fontSize: 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _statusCell(String status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

  Widget _progressCell(double progress, String status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: DailyColors.tan,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(fontSize: 15, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Delivered':
      case 'On Time':
        return DailyColors.success;
      case 'Delayed':
        return DailyColors.warning;
      case 'Pending':
        return DailyColors.gray;
      default:
        return DailyColors.burgundy;
    }
  }

  Future<void> _showDetails(String title, List<String> details) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Text(detail, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Demonstration data only. This monitoring view is read-only.',
              style: TextStyle(fontSize: 15, color: DailyColors.gray),
            ),
          ],
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

class _RouteRecord {
  final String route;
  final String area;
  final String partner;
  final String status;
  final double progress;

  const _RouteRecord(
    this.route,
    this.area,
    this.partner,
    this.status,
    this.progress,
  );
}

class _PartnerRecord {
  final String name;
  final String route;
  final String area;
  final int deliveries;
  final int delivered;
  final int pending;
  final String status;

  const _PartnerRecord(
    this.name,
    this.route,
    this.area,
    this.deliveries,
    this.delivered,
    this.pending,
    this.status,
  );
}

class _ProgressRecord {
  final String customer;
  final String area;
  final String newspaper;
  final String partner;
  final String expected;
  final String actual;
  final String status;

  const _ProgressRecord(
    this.customer,
    this.area,
    this.newspaper,
    this.partner,
    this.expected,
    this.actual,
    this.status,
  );
}


