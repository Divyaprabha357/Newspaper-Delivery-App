import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SupplierDistributionScreen extends StatefulWidget {
  const SupplierDistributionScreen({super.key});

  @override
  State<SupplierDistributionScreen> createState() =>
      _SupplierDistributionScreenState();
}

class _SupplierDistributionScreenState
    extends State<SupplierDistributionScreen> {
  final List<_DistributionRow> _rows = [
    _DistributionRow('toi', 'The Times of India', 1200, 1180),
    _DistributionRow('ht', 'Hindustan Times', 800, 800),
    _DistributionRow('dj', 'Dainik Jagran', 350, 320),
    _DistributionRow('mm', 'Malayala Manorama', 300, 300),
  ];

  DateTime _selectedDate = DateTime.now();
  bool _confirmed = false;

  int get _expected => _rows.fold(0, (sum, row) => sum + row.required);
  int get _available => _rows.fold(0, (sum, row) => sum + row.available);
  int get _shortage => _rows.fold(0, (sum, row) => sum + row.shortage);
  int get _dispatch => _rows.fold(0, (sum, row) => sum + row.dispatch);

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
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
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _confirmed = false;
      });
    }
  }

  Future<void> _confirmDistribution() async {
    final invalid = _rows.where((row) => row.error != null).toList();
    if (invalid.isNotEmpty) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check the dispatch quantity for ${invalid.first.name}.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm distribution preview'),
        content: Text(
          '${_formatDate(_selectedDate)}\n\n'
          'Dispatch quantity: $_dispatch copies\n'
          'Shortage: $_shortage copies\n\n'
          'This confirms the quantities for this frontend preview only. '
          'Nothing will be saved to the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DailyColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM PREVIEW'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _confirmed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distribution quantities confirmed for this preview.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          'Daily Distribution',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: DailyColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(_formatDate(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DailyColors.charcoal,
                      side: const BorderSide(color: DailyColors.divider),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (compact)
                Column(
                  children: _metricCards(),
                )
              else
                Row(
                  children: _metricCards()
                      .map((card) => Expanded(child: card))
                      .expand((card) => [card, const SizedBox(width: 10)])
                      .toList()
                    ..removeLast(),
                ),
              const SizedBox(height: 22),
              const Text(
                'Newspaper Quantities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.charcoal,
                ),
              ),
              const SizedBox(height: 9),
              _table(compact),
              const SizedBox(height: 14),
              if (_confirmed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  color: DailyColors.tan,
                  child: const Text(
                    'Distribution quantities confirmed for this preview. '
                    'No database changes were made.',
                    style: TextStyle(
                      color: DailyColors.charcoal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _confirmDistribution,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('CONFIRM & PROCEED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DailyColors.burgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _metricCards() {
    return [
      _MetricCard('Expected', _expected, 'total copies'),
      _MetricCard('Available', _available, 'total copies'),
      _MetricCard('Shortage', _shortage, 'total copies', accent: true),
      _MetricCard('Dispatch', _dispatch, 'total copies'),
    ];
  }

  Widget _table(bool compact) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          return Table(
            columnWidths: {
              0: FlexColumnWidth(compact ? 2.6 : 3.2),
              1: const FlexColumnWidth(1.35),
              2: const FlexColumnWidth(1.35),
              3: const FlexColumnWidth(1.25),
              4: const FlexColumnWidth(1.55),
            },
            border: const TableBorder(
              horizontalInside: BorderSide(color: DailyColors.divider),
            ),
            children: [
              _tableHeader(),
              ..._rows.map((row) => _tableRow(row, tableWidth)),
            ],
          );
        },
      ),
    );
  }

  TableRow _tableHeader() {
    const style = TextStyle(
      color: DailyColors.gray,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return const TableRow(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 13, 8, 11),
          child: Text('NEWSPAPER', style: style),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 13, 8, 11),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('REQUIRED', style: style),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 13, 8, 11),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('AVAILABLE', style: style),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 13, 8, 11),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('SHORTAGE', style: style),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 13, 14, 11),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('DISPATCH', style: style),
          ),
        ),
      ],
    );
  }

  TableRow _tableRow(_DistributionRow row, double tableWidth) {
    final error = row.error;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Text(
            row.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _numericCell(_number(row.required)),
        _numericCell(_number(row.available)),
        _numericCell(
          _number(row.shortage),
          color: row.shortage > 0 ? DailyColors.burgundy : DailyColors.gray,
          bold: row.shortage > 0,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 72,
                maxWidth: tableWidth * .17,
              ),
              child: TextFormField(
                controller: row.controller,
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateDispatch(row, value),
                decoration: InputDecoration(
                  isDense: true,
                  errorText: error,
                  filled: true,
                  fillColor: DailyColors.cream,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: DailyColors.divider),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: DailyColors.divider),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numericCell(
    String value, {
    Color color = DailyColors.charcoal,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _updateDispatch(_DistributionRow row, String value) {
    final parsed = int.tryParse(value);
    setState(() {
      row.dispatch = parsed ?? 0;
      row.error = value.trim().isEmpty
          ? 'Required'
          : parsed == null
              ? 'Whole number'
              : parsed < 0
                  ? 'Cannot be negative'
                  : parsed > row.maximumDispatch
                      ? 'Max ${row.maximumDispatch}'
                      : null;
      _confirmed = false;
    });
  }

  String _number(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
}

class _DistributionRow {
  final String id;
  final String name;
  final int required;
  final int available;
  late final TextEditingController controller;
  int dispatch;
  String? error;

  _DistributionRow(this.id, this.name, this.required, this.available)
      : dispatch = available {
    controller = TextEditingController(text: '$available');
  }

  int get shortage => (required - available).clamp(0, required).toInt();
  int get maximumDispatch => required < available ? required : available;
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final String detail;
  final bool accent;

  const _MetricCard(
    this.label,
    this.value,
    this.detail, {
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: accent ? DailyColors.burgundy : DailyColors.gray,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString().replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                  (match) => '${match.group(1)},',
                ),
            style: TextStyle(
              color: accent ? DailyColors.burgundy : DailyColors.charcoal,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(fontSize: 15, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }
}



