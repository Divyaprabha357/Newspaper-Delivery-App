import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SupplierCustomersScreen extends StatefulWidget {
  const SupplierCustomersScreen({super.key});

  @override
  State<SupplierCustomersScreen> createState() =>
      _SupplierCustomersScreenState();
}

class _SupplierCustomersScreenState extends State<SupplierCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _area = 'All Areas';
  String _status = 'All Status';
  int _page = 1;
  static const _pageSize = 5;

  final List<_CustomerRecord> _customers = const [
    _CustomerRecord(
      name: 'R. Sharma',
      code: 'CUS-1042',
      phone: '98765 43210',
      email: 'r.sharma@example.com',
      area: 'Andheri',
      newspapers: 3,
      status: 'ACTIVE',
      address: 'Andheri West, Mumbai',
      subscriptions: [
        _Subscription('The Times of India', 'ACTIVE', '07:00 AM', '\u20B95.00'),
        _Subscription('Hindustan Times', 'ACTIVE', '07:00 AM', '\u20B94.50'),
        _Subscription('Loksatta', 'ACTIVE', '07:00 AM', '\u20B94.00'),
      ],
    ),
    _CustomerRecord(
      name: 'S. Mehta',
      code: 'CUS-1088',
      phone: '91234 56789',
      email: 's.mehta@example.com',
      area: 'Bandra',
      newspapers: 2,
      status: 'ACTIVE',
      address: 'Bandra East, Mumbai',
      subscriptions: [
        _Subscription('The Hindu', 'ACTIVE', '07:30 AM', '\u20B95.50'),
        _Subscription('Dainik Jagran', 'ACTIVE', '07:30 AM', '\u20B94.00'),
      ],
    ),
    _CustomerRecord(
      name: 'A. Verma',
      code: 'CUS-1124',
      phone: '87654 32109',
      email: 'a.verma@example.com',
      area: 'Powai',
      newspapers: 4,
      status: 'ACTIVE',
      address: 'Hiranandani Gardens, Powai',
      subscriptions: [
        _Subscription('The Times of India', 'ACTIVE', '06:45 AM', '\u20B95.00'),
        _Subscription('The Hindu', 'ACTIVE', '06:45 AM', '\u20B95.50'),
        _Subscription('Dainik Jagran', 'ACTIVE', '06:45 AM', '\u20B94.00'),
        _Subscription('Loksatta', 'ACTIVE', '06:45 AM', '\u20B94.00'),
      ],
    ),
    _CustomerRecord(
      name: 'P. Singh',
      code: 'CUS-1167',
      phone: '99867 66554',
      email: 'p.singh@example.com',
      area: 'Dadar',
      newspapers: 2,
      status: 'PAUSED',
      address: 'Shivaji Park, Dadar',
      subscriptions: [
        _Subscription('The Times of India', 'PAUSED', '07:15 AM', '\u20B95.00'),
        _Subscription('Hindustan Times', 'PAUSED', '07:15 AM', '\u20B94.50'),
      ],
    ),
    _CustomerRecord(
      name: 'K. Iyer',
      code: 'CUS-1201',
      phone: '90123 45678',
      email: 'k.iyer@example.com',
      area: 'Thane',
      newspapers: 1,
      status: 'ACTIVE',
      address: 'Gokhale Road, Thane',
      subscriptions: [
        _Subscription('The Hindu', 'ACTIVE', '06:30 AM', '\u20B95.50'),
      ],
    ),
  ];

  List<_CustomerRecord> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    return _customers.where((customer) {
      final matchesSearch = query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.code.toLowerCase().contains(query);
      final matchesArea =
          _area == 'All Areas' || customer.area == _area;
      final matchesStatus =
          _status == 'All Status' || _statusFor(customer.status) == _status;
      return matchesSearch && matchesArea && matchesStatus;
    }).toList();
  }

  List<_CustomerRecord> get _visibleCustomers {
    final records = _filteredCustomers;
    final start = (_page - 1) * _pageSize;
    if (start >= records.length) return const [];
    final end = (start + _pageSize).clamp(0, records.length);
    return records.sublist(start, end);
  }

  int get _pageCount {
    final length = _filteredCustomers.length;
    return length == 0 ? 1 : (length / _pageSize).ceil();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshFilters(VoidCallback change) {
    setState(() {
      change();
      _page = 1;
    });
  }

  void _clearFilters() {
    _refreshFilters(() {
      _searchController.clear();
      _area = 'All Areas';
      _status = 'All Status';
    });
  }

  String _statusFor(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'PAUSED':
        return 'Paused';
      default:
        return 'Cancelled';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return DailyColors.success;
      case 'PAUSED':
        return DailyColors.warning;
      default:
        return DailyColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Customers & Subscriptions',
            style: TextStyle(
              color: DailyColors.charcoal,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _toolbar(),
          const SizedBox(height: 14),
          _customerTable(),
          if (_filteredCustomers.isNotEmpty && _pageCount > 1) _pagination(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() => _page = 1),
          decoration: const InputDecoration(
            hintText: 'Search customer...',
            prefixIcon: Icon(Icons.search, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
        final area = _dropdown(
          value: _area,
          items: const [
            'All Areas',
            'Andheri',
            'Bandra',
            'Powai',
            'Dadar',
            'Thane',
          ],
          onChanged: (value) =>
              _refreshFilters(() => _area = value ?? 'All Areas'),
        );
        final status = _dropdown(
          value: _status,
          items: const ['All Status', 'Active', 'Paused', 'Cancelled'],
          onChanged: (value) =>
              _refreshFilters(() => _status = value ?? 'All Status'),
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: area),
                  const SizedBox(width: 8),
                  Expanded(child: status),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 8),
            SizedBox(width: 165, child: area),
            const SizedBox(width: 8),
            SizedBox(width: 150, child: status),
          ],
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _customerTable() {
    final records = _visibleCustomers;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: records.isEmpty ? _emptyState() : _recordsTable(records),
    );
  }

  Widget _recordsTable(List<_CustomerRecord> records) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.8),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(1.8),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(2.0),
      },
      border: const TableBorder(
        horizontalInside: BorderSide(color: DailyColors.divider),
      ),
      children: [
        _headerRow(),
        ...records.map(_dataRow),
      ],
    );
  }

  TableRow _headerRow() {
    return const TableRow(
      children: [
        _HeaderCell('CUSTOMER'),
        _HeaderCell('PHONE'),
        _HeaderCell('AREA'),
        _HeaderCell('NEWSPAPERS'),
        _HeaderCell('STATUS'),
      ],
    );
  }

  TableRow _dataRow(_CustomerRecord customer) {
    final color = _statusColor(customer.status);
    return TableRow(
      children: [
        _customerCell(customer),
        _cell(Text(customer.phone)),
        _cell(Text(customer.area)),
        _cell(Text('${customer.newspapers}')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              color: color.withValues(alpha: .12),
              child: Text(
                _statusFor(customer.status),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerCell(_CustomerRecord customer) {
    return InkWell(
      onTap: () => _showCustomerDetails(customer),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: const TextStyle(
                color: DailyColors.charcoal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              customer.code,
              style: const TextStyle(
                color: DailyColors.gray,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(Widget child) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 30, color: DailyColors.gray),
          const SizedBox(height: 10),
          const Text(
            'No customers found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try changing your search or filters.',
            style: TextStyle(fontSize: 16, color: DailyColors.gray),
          ),
          const SizedBox(height: 9),
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
      ),
    );
  }

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _page > 1 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left, size: 18),
          ),
          for (var page = 1; page <= _pageCount; page++)
            TextButton(
              onPressed: () => setState(() => _page = page),
              style: TextButton.styleFrom(
                backgroundColor:
                    page == _page ? DailyColors.burgundy : Colors.transparent,
                foregroundColor:
                    page == _page ? Colors.white : DailyColors.charcoal,
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
              child: Text('$page'),
            ),
          IconButton(
            onPressed: _page < _pageCount ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomerDetails(_CustomerRecord customer) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SizedBox(
          width: 470,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Customer code', customer.code),
                _detail('Phone', customer.phone),
                _detail('Email', customer.email),
                _detail('Active address', customer.address),
                _detail('Area', customer.area),
                const SizedBox(height: 12),
                const Text(
                  'SUBSCRIPTIONS',
                  style: TextStyle(
                    color: DailyColors.burgundy,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 7),
                ...customer.subscriptions.map(
                  (subscription) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscription.newspaper,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Text(
                          '${_statusFor(subscription.status)} \u00B7 '
                          '${subscription.time} \u00B7 ${subscription.price}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: DailyColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Read-only preview. No customer or subscription changes are available here.',
                  style: TextStyle(fontSize: 15, color: DailyColors.gray),
                ),
              ],
            ),
          ),
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: DailyColors.gray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRecord {
  final String name;
  final String code;
  final String phone;
  final String email;
  final String area;
  final int newspapers;
  final String status;
  final String address;
  final List<_Subscription> subscriptions;

  const _CustomerRecord({
    required this.name,
    required this.code,
    required this.phone,
    required this.email,
    required this.area,
    required this.newspapers,
    required this.status,
    required this.address,
    required this.subscriptions,
  });
}

class _Subscription {
  final String newspaper;
  final String status;
  final String time;
  final String price;

  const _Subscription(this.newspaper, this.status, this.time, this.price);
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 8, 11),
      child: Text(
        label,
        style: const TextStyle(
          color: DailyColors.gray,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


