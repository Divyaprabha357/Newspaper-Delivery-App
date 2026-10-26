import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';

class SupplierDistributionScreen extends StatefulWidget {
  const SupplierDistributionScreen({super.key});

  @override
  State<SupplierDistributionScreen> createState() =>
      _SupplierDistributionScreenState();
}

class _SupplierDistributionScreenState
    extends State<SupplierDistributionScreen> {
  DateTime _selectedDate = DateTime.now();
  List<_DistributionRow> _rows = [];
  bool _loading = true;
  String? _error;
  bool _confirmed = false;

  int get _expected => _rows.fold(0, (sum, row) => sum + row.required);
  int get _available => _rows.fold(0, (sum, row) => sum + row.available);
  int get _shortage => _rows.fold(0, (sum, row) => sum + row.shortage);
  int get _dispatch => _rows.fold(0, (sum, row) => sum + row.dispatch);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  String _dateParam() =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

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
      final token = session?['session_token']?.toString();

      if (userId == null && supplierId == null) {
        throw const RoleApiException('Supplier session is unavailable. Please sign in again.');
      }

      final res = await RoleApiService(authToken: token).supplierDistribution(
        userId ?? supplierId!,
        supplierId: supplierId,
        date: _dateParam(),
      );

      final rawList = res['distribution'] as List? ?? [];
      final rows = <_DistributionRow>[];

      for (final item in rawList) {
        if (item is Map) {
          final id = item['id']?.toString() ?? item['newspaper_id']?.toString() ?? '';
          final name = item['name']?.toString() ?? item['newspaper_name']?.toString() ?? 'Newspaper';
          final req = _number(item['required']) ?? 0;
          final avail = _number(item['available']) ?? req;
          final row = _DistributionRow(id, name, req, avail);
          if (item['dispatch'] != null) {
            final disp = _number(item['dispatch']) ?? avail;
            row.dispatch = disp;
            row.controller.text = '$disp';
          }
          rows.add(row);
        }
      }

      if (mounted) {
        setState(() {
          for (final oldRow in _rows) {
            oldRow.controller.dispose();
          }
          _rows = rows;
          _loading = false;
          _confirmed = false;
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
          _error = 'Unable to load distribution data. Please check your connection and retry.';
          _loading = false;
        });
      }
    }
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
    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
      });
      await _load();
    }
  }

  Future<void> _confirmDistribution() async {
    final invalid = _rows.where((row) => row.error != null).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please check the dispatch quantity for ${invalid.first.name}.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DailyColors.white,
        title: const Text('Confirm Distribution Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Date: ${_formatDate(_selectedDate)}\n\n'
          'Planned Dispatch: $_dispatch copies\n'
          'Expected Demand: $_expected copies\n'
          'Shortage: $_shortage copies\n\n'
          'Confirm distribution allocation for delivery partners?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: DailyColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DailyColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM ALLOCATION'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _confirmed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distribution quantities confirmed successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return RefreshIndicator(
          color: DailyColors.burgundy,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                            'Distribution',
                            style: TextStyle(
                              color: DailyColors.charcoal,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Distribution planning and inventory dispatch for ${_formatDate(_selectedDate)}',
                            style: const TextStyle(
                              color: DailyColors.gray,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(_formatDate(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DailyColors.charcoal,
                        side: const BorderSide(color: DailyColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_loading)
                  const _StateMessage(
                    icon: Icons.hourglass_empty,
                    text: 'Loading distribution planning...',
                  )
                else if (_error != null)
                  _StateMessage(
                    icon: Icons.error_outline,
                    text: _error!,
                    retry: _load,
                  )
                else if (_rows.isEmpty)
                  const _StateMessage(
                    icon: Icons.route_outlined,
                    text: 'No distribution records available for this date.',
                  )
                else ...[
                  // Summary Metric Cards
                  if (compact) ...[
                    _MetricCard('Expected Demand', _expected, 'Active customer copies needed'),
                    _MetricCard('Available Stock', _available, 'Stock supplied by publisher'),
                    _MetricCard('Shortage', _shortage, 'Copies unable to fulfill', accent: _shortage > 0),
                    _MetricCard('Dispatch Planned', _dispatch, 'Allocated for delivery', accent: true),
                  ] else
                    Row(
                      children: [
                        Expanded(child: _MetricCard('Expected Demand', _expected, 'Active customer copies')),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard('Available Stock', _available, 'Stock from publisher')),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard('Shortage', _shortage, 'Unfulfilled copies', accent: _shortage > 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard('Dispatch Planned', _dispatch, 'Allocated for delivery', accent: true)),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Distribution Table
                  _buildTable(constraints.maxWidth),

                  const SizedBox(height: 24),

                  // Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_confirmed)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: DailyColors.success, size: 20),
                              SizedBox(width: 6),
                              Text('Allocation Confirmed', style: TextStyle(color: DailyColors.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _confirmDistribution,
                        icon: const Icon(Icons.assignment_turned_in, size: 18),
                        label: const Text('CONFIRM DISTRIBUTION'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DailyColors.burgundy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(double maxWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(2),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: DailyColors.divider),
        ),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: DailyColors.cream),
            children: [
              _HeaderCell('NEWSPAPER EDITION'),
              _HeaderCell('REQUIRED', alignRight: true),
              _HeaderCell('AVAILABLE', alignRight: true),
              _HeaderCell('SHORTAGE', alignRight: true),
              _HeaderCell('DISPATCH', alignRight: true),
            ],
          ),
          ..._rows.map((row) => _buildRow(row, maxWidth)),
        ],
      ),
    );
  }

  TableRow _buildRow(_DistributionRow row, double tableWidth) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Text(
            row.name,
            style: const TextStyle(
              fontSize: 16,
              color: DailyColors.charcoal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _numericCell('${row.required}'),
        _numericCell('${row.available}'),
        _numericCell(
          '${row.shortage}',
          color: row.shortage > 0 ? DailyColors.burgundy : DailyColors.gray,
          bold: row.shortage > 0,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 90,
              child: TextFormField(
                controller: row.controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                onChanged: (value) => _updateDispatch(row, value),
                decoration: InputDecoration(
                  isDense: true,
                  errorText: row.error,
                  filled: true,
                  fillColor: DailyColors.cream,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
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
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _updateDispatch(_DistributionRow row, String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      row.dispatch = parsed ?? 0;
      row.error = value.trim().isEmpty
          ? 'Required'
          : parsed == null
              ? 'Invalid'
              : parsed < 0
                  ? '>= 0'
                  : null;
      _confirmed = false;
    });
  }
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
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _HeaderCell(this.text, {this.alignRight = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: DailyColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
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
      padding: const EdgeInsets.all(16),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: accent ? DailyColors.burgundy : DailyColors.charcoal,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(fontSize: 13, color: DailyColors.gray),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? retry;
  const _StateMessage({required this.icon, required this.text, this.retry});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 46),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: DailyColors.gray),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (retry != null)
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
        ),
      );
}
