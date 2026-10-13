import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'supplier_design_system.dart';

class SupplierReportsScreen extends StatefulWidget {
  const SupplierReportsScreen({super.key});

  @override
  State<SupplierReportsScreen> createState() => _SupplierReportsScreenState();
}

class _SupplierReportsScreenState extends State<SupplierReportsScreen> {
  final _searchController = TextEditingController();
  int _report = 0;
  String _period = 'Last 7 Days';
  String _newspaper = 'All Newspapers';
  String _area = 'All Areas';
  String _status = 'All Status';
  DateTimeRange? _customRange;

  final _subscriptions = const [
    _SubscriptionRow('R. Sharma', 'The Times of India', '01 Oct 2026', supplierMissingValue, 850, 'Active', 'North Sector'),
    _SubscriptionRow('S. Mehta', 'Hindustan Times', '02 Oct 2026', supplierMissingValue, 450, 'Paused', 'Central Area'),
    _SubscriptionRow('A. Verma', 'Dainik Jagran', '03 Oct 2026', supplierMissingValue, 600, 'Cancelled', 'South Zone'),
    _SubscriptionRow('P. Singh', 'The Hindu', '05 Oct 2026', supplierMissingValue, 750, 'Active', 'North Sector'),
  ];

  final _distribution = const [
    _DistributionRow('The Times of India', 'English', supplierMissingValue, supplierMissingValue, supplierMissingValue),
    _DistributionRow('Hindustan Times', 'English', supplierMissingValue, supplierMissingValue, supplierMissingValue),
    _DistributionRow('Dainik Jagran', 'Hindi', supplierMissingValue, supplierMissingValue, supplierMissingValue),
  ];

  final _delivery = const [
    _DeliveryRow('10 Oct 2026', 'The Times of India', supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue),
    _DeliveryRow('11 Oct 2026', 'Hindustan Times', supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue),
    _DeliveryRow('12 Oct 2026', 'Dainik Jagran', supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue, supplierMissingValue),
  ];

  final _customers = const [
    _CustomerRow('R. Sharma', 'North Sector', supplierMissingValue, 'Active', '01 Oct 2026'),
    _CustomerRow('S. Mehta', 'Central Area', supplierMissingValue, 'Paused', '02 Oct 2026'),
    _CustomerRow('A. Verma', 'South Zone', supplierMissingValue, 'Cancelled', '03 Oct 2026'),
    _CustomerRow('P. Singh', 'North Sector', supplierMissingValue, 'Active', '05 Oct 2026'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SubscriptionRow> get _filteredSubscriptions => _subscriptions.where((item) {
        return _matches(item.customer, item.newspaper, item.area) &&
            (_status == 'All Status' || item.status == _status) &&
            (_newspaper == 'All Newspapers' || item.newspaper == _newspaper);
      }).toList();

  List<_DistributionRow> get _filteredDistribution => _distribution
      .where((item) => _matches(item.newspaper, item.language))
      .toList();

  List<_DeliveryRow> get _filteredDelivery => _delivery
      .where((item) => _matches(item.newspaper, item.date, item.status))
      .toList();

  List<_CustomerRow> get _filteredCustomers => _customers.where((item) {
        return _matches(item.customer, item.area) &&
            (_area == 'All Areas' || item.area == _area) &&
            (_status == 'All Status' || item.status == _status);
      }).toList();

  bool _matches(String first, [String? second, String? third]) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [first, second, third]
        .whereType<String>()
        .any((value) => value.toLowerCase().contains(query));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _period = 'Last 7 Days';
      _customRange = null;
      _newspaper = 'All Newspapers';
      _area = 'All Areas';
      _status = 'All Status';
    });
  }

  Future<void> _chooseCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      currentDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: DailyColors.burgundy,
              ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _period = 'Custom Range';
      });
    }
  }

  void _selectPeriod(String value) {
    if (value == 'Custom Range') {
      _chooseCustomRange();
    } else {
      setState(() {
        _period = value;
        _customRange = null;
      });
    }
  }

  void _showExportOptions() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text(
          'CSV export is not available because Supplier report records are not connected to a verified backend source yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REPORTS', style: _eyebrow),
          const SizedBox(height: 7),
          const Text('Business Reports', style: _heading),
          const SizedBox(height: 16),
          _headerActions(),
          const SizedBox(height: 16),
          _summary(),
          const SizedBox(height: 18),
          _reportTabs(),
          const SizedBox(height: 10),
          _filters(),
          const SizedBox(height: 12),
          _reportBody(),
          const SizedBox(height: 12),
          const Text(
            'Illustrative preview rows only. Live Supplier reporting data is not currently available from the verified backend.',
            style: TextStyle(fontSize: 15, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _headerActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controls = [
          DropdownButtonFormField<String>(
            initialValue: _period,
            decoration: const InputDecoration(labelText: 'Period', isDense: true),
            items: const [
              'Today',
              'Last 7 Days',
              'Last 30 Days',
              'This Month',
              'Custom Range',
            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) {
              if (value != null) _selectPeriod(value);
            },
          ),
          OutlinedButton.icon(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('EXPORT REPORT'),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('CLEAR FILTERS'),
          ),
        ];
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              controls[0],
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: controls.skip(1).toList()),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 210, child: controls[0]),
            const Spacer(),
            controls[1],
            const SizedBox(width: 8),
            controls[2],
          ],
        );
      },
    );
  }

  Widget _summary() {
    const cards = [
      _Metric(Icons.subscriptions_outlined, 'Active Subscriptions', 'Unavailable', 'Supplier-scoped source unavailable'),
      _Metric(Icons.newspaper_outlined, 'Newspapers Distributed', 'Unavailable', 'Distribution quantities not stored'),
      _Metric(Icons.local_shipping_outlined, 'Delivery Completion', 'Unavailable', 'Verified delivery source unavailable'),
      _Metric(Icons.people_outline, 'Customer Base', 'Unavailable', 'Supplier-scoped source unavailable'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 920 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: count == 4 ? 2.1 : 2.5,
          children: cards,
        );
      },
    );
  }

  Widget _reportTabs() {
    const labels = ['Distribution Report', 'Subscription Report', 'Delivery Performance', 'Customer Report'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: TextButton(
                onPressed: () => setState(() {
                  _report = i;
                  _searchController.clear();
                  _status = 'All Status';
                  _newspaper = 'All Newspapers';
                  _area = 'All Areas';
                }),
                style: TextButton.styleFrom(
                  backgroundColor: _report == i ? DailyColors.burgundy : DailyColors.white,
                  foregroundColor: _report == i ? Colors.white : DailyColors.charcoal,
                  side: const BorderSide(color: DailyColors.divider),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                ),
                child: Text(labels[i].toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    final showNewspaper = _report != 3;
    final showArea = _report == 0 || _report == 2 || _report == 3;
    final showStatus = _report == 1 || _report == 2 || _report == 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search customer or newspaper',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            );
        final dropdowns = <Widget>[
          if (showNewspaper)
            _select('Newspaper', _newspaper,
                ['All Newspapers', ..._distribution.map((item) => item.newspaper).toSet()],
                (value) => setState(() => _newspaper = value)),
          if (showArea)
            _select('Area', _area,
                ['All Areas', ..._subscriptions.map((item) => item.area).toSet()],
                (value) => setState(() => _area = value)),
          if (showStatus)
            _select('Status', _status,
                const ['All Status', 'Active', 'Paused', 'Cancelled', 'Delivered', 'Delayed'],
                (value) => setState(() => _status = value)),
        ];
        final dateLabel = _customRange == null
            ? null
            : Text('${_formatDate(_customRange!.start)} - ${_formatDate(_customRange!.end)}',
                style: const TextStyle(fontSize: 16, color: DailyColors.gray));
        final wideChildren = <Widget>[
          Expanded(flex: 2, child: search),
          const SizedBox(width: 10),
        ];
        for (var i = 0; i < dropdowns.length; i++) {
          wideChildren.add(Expanded(child: dropdowns[i]));
          if (i < dropdowns.length - 1 || dateLabel != null) {
            wideChildren.add(const SizedBox(width: 10));
          }
        }
        if (dateLabel != null) wideChildren.add(Flexible(child: dateLabel));
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DailyColors.white,
            border: Border.all(color: DailyColors.divider),
          ),
          child: constraints.maxWidth >= 900
              ? Row(children: wideChildren)
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(width: constraints.maxWidth >= 360 ? 300 : constraints.maxWidth, child: search),
                    ...dropdowns,
                    if (dateLabel != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: dateLabel,
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _select(String label, String value, List<String> values, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: values.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Widget _reportBody() {
    switch (_report) {
      case 1:
        return _section(
          'Subscription Activity',
          'Track active, paused and cancelled newspaper subscriptions.',
          _filteredSubscriptions.isEmpty
              ? _empty('No results match your selected filters.')
              : _subscriptionTable(_filteredSubscriptions),
        );
      case 2:
        return _section(
          'Delivery Performance',
          'Review delivery outcomes and completion trends.',
          Column(
            children: [
              _unavailableChart(),
              const SizedBox(height: 12),
              _filteredDelivery.isEmpty ? _empty('No records found for this period.') : _deliveryTable(_filteredDelivery),
            ],
          ),
        );
      case 3:
        return _section(
          'Customer Activity',
          'Understand customer distribution and subscription activity.',
          _filteredCustomers.isEmpty ? _empty('No results match your selected filters.') : _customerTable(_filteredCustomers),
        );
      default:
        return _section(
          'Distribution Activity',
          'Review newspaper distribution activity for the selected period.',
          _filteredDistribution.isEmpty
              ? _empty('Distribution quantity data is not currently available.')
              : _distributionTable(_filteredDistribution),
        );
    }
  }

  Widget _section(String title, String subtitle, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: DailyColors.charcoal)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(fontSize: 18, color: DailyColors.gray)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _unavailableChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
      child: const Row(
        children: [
          Icon(Icons.bar_chart_outlined, color: DailyColors.burgundy, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Delivery trend unavailable. The verified backend does not currently expose Supplier delivery records for aggregation.',
              style: TextStyle(fontSize: 18, color: DailyColors.gray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: DailyColors.gray, size: 28),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: DailyColors.gray, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _distributionTable(List<_DistributionRow> rows) => _table(
        const ['Newspaper', 'Language', 'Copies Distributed', 'Delivery Date', 'Area'],
        rows.map((row) => [row.newspaper, row.language, row.copies, row.date, row.area]).toList(),
        const [2.0, 1.0, 1.1, 1.1, 1.2],
      );

  Widget _subscriptionTable(List<_SubscriptionRow> rows) => _table(
        const ['Customer', 'Newspaper', 'Subscription Start', 'Renewal / End Date', 'Monthly Price', 'Status'],
        rows.map((row) => [row.customer, row.newspaper, row.start, row.end, supplierCurrency(row.price), row.status]).toList(),
        const [1.3, 1.5, 1.15, 1.3, .9, 1.0],
        onTap: (index) => _details('Subscription Details', rows[index].details),
      );

  Widget _deliveryTable(List<_DeliveryRow> rows) => _table(
        const ['Date', 'Newspaper', 'Total Items', 'Delivered', 'Not Delivered', 'Delayed', 'Completion'],
        rows.map((row) => [row.date, row.newspaper, row.total, row.delivered, row.notDelivered, row.delayed, row.completion]).toList(),
        const [1.0, 1.6, 1.0, 1.0, 1.1, .9, 1.0],
      );

  Widget _customerTable(List<_CustomerRow> rows) => _table(
        const ['Customer', 'Area', 'Active Newspapers', 'Subscription Status', 'First Subscription Date'],
        rows.map((row) => [row.customer, row.area, row.newspapers, row.status, row.date]).toList(),
        const [1.3, 1.2, 1.2, 1.3, 1.3],
        onTap: (index) => _details('Customer Summary', rows[index].details),
      );

  Widget _table(
    List<String> headers,
    List<List<String>> rows,
    List<double> widths, {
    void Function(int index)? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
      child: Table(
        columnWidths: {for (var i = 0; i < widths.length; i++) i: FlexColumnWidth(widths[i])},
        border: const TableBorder(
          horizontalInside: BorderSide(color: DailyColors.divider),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: DailyColors.tan),
            children: headers.map(_headerCell).toList(),
          ),
          ...rows.asMap().entries.map(
                (entry) => TableRow(
                  children: entry.value
                      .asMap()
                      .entries
                      .map((cell) => _dataCell(cell.value, onTap == null ? null : () => onTap(entry.key)))
                      .toList(),
                ),
              ),
        ],
      ),
    );
  }

  Widget _headerCell(String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Text(value.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DailyColors.charcoal)),
      );

  Widget _dataCell(String value, VoidCallback? onTap) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: DailyColors.charcoal)),
    );
    return onTap == null ? child : InkWell(onTap: onTap, child: child);
  }

  void _details(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }
}

const _eyebrow = TextStyle(
  color: DailyColors.burgundy,
  fontSize: 15,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.7,
);

const _heading = TextStyle(
  color: DailyColors.charcoal,
  fontSize: 40,
  fontWeight: FontWeight.bold,
);

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _Metric(this.icon, this.label, this.value, this.caption);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: Row(
          children: [
            Icon(icon, color: DailyColors.burgundy, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: const TextStyle(fontSize: 15, color: DailyColors.gray, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 17, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(caption, style: const TextStyle(fontSize: 15, color: DailyColors.gray), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SubscriptionRow {
  final String customer, newspaper, start, end, status, area;
  final num? price;
  const _SubscriptionRow(this.customer, this.newspaper, this.start, this.end, this.price, this.status, this.area);
  String get details => '$customer\n$newspaper\nStatus: $status\nSubscription start: $start\nRenewal / end date: $end\nMonthly price: ${supplierCurrency(price)}';
}

class _DistributionRow {
  final String newspaper, language, copies, date, area;
  const _DistributionRow(this.newspaper, this.language, this.copies, this.date, this.area);
}

class _DeliveryRow {
  final String date, newspaper, total, delivered, notDelivered, delayed, completion, status;
  const _DeliveryRow(this.date, this.newspaper, this.total, this.delivered, this.notDelivered, this.delayed, this.completion)
      : status = 'Unavailable';
}

class _CustomerRow {
  final String customer, area, newspapers, status, date;
  const _CustomerRow(this.customer, this.area, this.newspapers, this.status, this.date);
  String get details => '$customer\nArea: $area\nActive newspapers: $newspapers\nSubscription status: $status\nFirst subscription date: $date';
}
