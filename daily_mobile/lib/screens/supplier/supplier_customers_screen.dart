import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';

class SupplierCustomersScreen extends StatefulWidget {
  const SupplierCustomersScreen({super.key});

  @override
  State<SupplierCustomersScreen> createState() =>
      _SupplierCustomersScreenState();
}

class _SupplierCustomersScreenState extends State<SupplierCustomersScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final id = _number(session?['user_id'] ?? session?['id']);
      if (id == null) {
        throw const RoleApiException('Supplier session is unavailable.');
      }
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierSubscriptions(id);
      final values = response['subscriptions'];
      if (values is! List) {
        throw const RoleApiException(
          'The server returned no subscription list.',
        );
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
        setState(() => _error = 'Unable to load customers right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _number(dynamic value) => int.tryParse(value?.toString() ?? '');

  List<Map<String, dynamic>> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _records;
    return _records
        .where(
          (record) => [
            record['customer_name'],
            record['customer_phone'],
            record['customer_email'],
            record['newspaper_name'],
            record['area_name'],
            record['status'],
          ].any((value) => value.toString().toLowerCase().contains(query)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
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
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search customer, newspaper, area, or status...',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const _StateMessage(
              icon: Icons.hourglass_empty,
              text: 'Loading subscriptions...',
            )
          else if (_error != null)
            _StateMessage(
              icon: Icons.error_outline,
              text: _error!,
              retry: _load,
            )
          else if (rows.isEmpty)
            const _StateMessage(
              icon: Icons.people_outline,
              text: 'No supplier subscriptions found.',
            )
          else
            _table(rows),
        ],
      ),
    );
  }

  Widget _table(List<Map<String, dynamic>> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.6),
          1: FlexColumnWidth(2.1),
          2: FlexColumnWidth(1.8),
          3: FlexColumnWidth(1.7),
          4: FlexColumnWidth(1.5),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: DailyColors.divider),
        ),
        children: [
          const TableRow(
            children: [
              _Header('CUSTOMER'),
              _Header('NEWSPAPER'),
              _Header('AREA'),
              _Header('PRICE'),
              _Header('STATUS'),
            ],
          ),
          ...rows.map(
            (row) => TableRow(
              children: [
                _cell(
                  '${row['customer_name'] ?? 'Unavailable'}\n${row['customer_phone'] ?? ''}',
                  bold: true,
                ),
                _cell(row['newspaper_name']?.toString() ?? 'Unavailable'),
                _cell(row['area_name']?.toString() ?? 'Unavailable'),
                _cell(_money(row['agreed_price']), alignRight: true),
                _cell(row['status']?.toString() ?? 'Unavailable'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String value, {bool bold = false, bool alignRight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: DailyColors.charcoal,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  String _money(dynamic value) =>
      value == null ? 'Unavailable' : '₹${value.toString()}';
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
    padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
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
