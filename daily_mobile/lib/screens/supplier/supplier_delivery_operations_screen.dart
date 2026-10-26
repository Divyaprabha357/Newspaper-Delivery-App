import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
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
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateParam() =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
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
        throw const RoleApiException('Supplier session is unavailable.');
      }
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierDeliveries(
        userId ?? supplierId!,
        supplierId: supplierId,
        date: _dateParam(),
      );
      final values = response['deliveries'];
      if (values is! List) {
        throw const RoleApiException('The server returned no delivery list.');
      }
      if (mounted) {
        setState(
          () => _records = values
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      }
    } on RoleApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load deliveries right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _date = selected);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Row(
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
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 15),
              label: Text(_dateLabel(_date)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 17),
      _tabs(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
          child: _loading
              ? const _StateMessage(
                  icon: Icons.hourglass_empty,
                  text: 'Loading deliveries...',
                )
              : _error != null
              ? _StateMessage(
                  icon: Icons.error_outline,
                  text: _error!,
                  retry: _load,
                )
              : _records.isEmpty
              ? const _StateMessage(
                  icon: Icons.local_shipping_outlined,
                  text: 'No deliveries found for this date.',
                )
              : _table(),
        ),
      ),
    ],
  );

  Widget _tabs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: TextButton(
              onPressed: () => setState(() => _tab = i),
              style: TextButton.styleFrom(
                backgroundColor: _tab == i
                    ? DailyColors.burgundy
                    : DailyColors.white,
                foregroundColor: _tab == i
                    ? Colors.white
                    : DailyColors.charcoal,
                side: const BorderSide(color: DailyColors.divider),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                ['ROUTES', 'DELIVERY PARTNERS', 'DELIVERY PROGRESS'][i],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _table() {
    final headers = _tab == 0
        ? ['DATE', 'AREA', 'PARTNER', 'STATUS']
        : _tab == 1
        ? ['PARTNER', 'AREA', 'DELIVERIES', 'STATUS']
        : ['CUSTOMER', 'NEWSPAPER', 'PARTNER', 'STATUS'];
    return Container(
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
          TableRow(children: headers.map((h) => _Header(h)).toList()),
          ..._records.map((record) {
            final values = _tab == 0
                ? [
                    _formatDate(record['delivery_date']),
                    record['area_name'],
                    record['partner_name'],
                    record['delivery_status'],
                  ]
                : _tab == 1
                ? [
                    record['partner_name'],
                    record['area_name'],
                    record['delivery_id'],
                    record['delivery_status'],
                  ]
                : [
                    record['customer_name'],
                    record['newspaper_name'],
                    record['partner_name'],
                    record['item_status'] ?? record['delivery_status'],
                  ];
            return TableRow(
              children: values
                  .map((v) => _cell(v?.toString() ?? 'Unavailable'))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _cell(String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    child: Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16, color: DailyColors.charcoal),
    ),
  );

  String _dateLabel(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  String _formatDate(dynamic value) {
    if (value == null) return 'Unavailable';
    final str = value.toString().split('T').first;
    return str;
  }
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
        fontSize: 14,
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
    padding: const EdgeInsets.symmetric(vertical: 46),
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
