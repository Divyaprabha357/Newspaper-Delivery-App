import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import 'supplier_login_screen.dart';
import 'supplier_distribution_screen.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});
  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  bool _loading = true;
  String? _error;
  String _supplierName = 'Supplier';
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _newspapers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? _number(dynamic value) => int.tryParse(value?.toString() ?? '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final supplierId = _number(
        session?['supplier_id'] ?? session?['id'] ?? session?['user_id'],
      );
      if (supplierId == null) {
        await RoleSessionService.clearSupplier();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SupplierLoginScreen()),
          (route) => false,
        );
        return;
      }
      final api = RoleApiService(
        authToken: session?['session_token']?.toString(),
      );
      final results = await Future.wait([
        api.supplierProfile(supplierId).catchError((_) => <String, dynamic>{}),
        api.supplierSubscriptions(supplierId).catchError((_) => <String, dynamic>{}),
        api.supplierDeliveries(supplierId).catchError((_) => <String, dynamic>{}),
        api.supplierNewspapers(supplierId).catchError((_) => <String, dynamic>{}),
      ]);

      final profile = results[0]['profile'] is Map
          ? Map<String, dynamic>.from(results[0]['profile'] as Map)
          : null;
      final subscriptions = results[1]['subscriptions'];
      final deliveries = results[2]['deliveries'];
      final newspapers = results[3]['newspapers'];

      if (mounted) {
        setState(() {
          _profile = profile;
          _supplierName = profile?['supplier_name']?.toString() ??
              session?['supplier_name']?.toString() ??
              'Supplier';
          _subscriptions = (subscriptions is List)
              ? subscriptions
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : [];
          _deliveries = (deliveries is List)
              ? deliveries
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : [];
          _newspapers = (newspapers is List)
              ? newspapers
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : [];
        });
      }
    } on RoleApiException catch (e) {
      if (e.isUnauthorized) {
        await RoleSessionService.clearSupplier();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SupplierLoginScreen()),
          (route) => false,
        );
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load dashboard data right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _activeSubscriptions => _subscriptions
      .where((r) => r['status']?.toString().toUpperCase() == 'ACTIVE')
      .length;
  int get _delivered => _deliveries
      .where(
        (r) => ['DELIVERED', 'COMPLETED'].contains(
          (r['delivery_status'] ?? r['item_status']).toString().toUpperCase(),
        ),
      )
      .length;
  int get _pending => _deliveries.length - _delivered;
  int get _customers => _subscriptions
      .map((r) => r['customer_id'])
      .where((v) => v != null)
      .toSet()
      .length;
  int get _newspapersCount => _newspapers.length;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DASHBOARD',
          style: TextStyle(
            color: DailyColors.burgundy,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _supplierName,
          style: const TextStyle(
            color: DailyColors.charcoal,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_profile?['address'] != null &&
            _profile!['address'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _profile!['address'].toString(),
            style: const TextStyle(color: DailyColors.gray, fontSize: 15),
          ),
        ],
        const SizedBox(height: 9),
        Text(
          _today(),
          style: const TextStyle(color: DailyColors.gray, fontSize: 16),
        ),
        const SizedBox(height: 17),
        if (_loading)
          const _StateMessage(
            icon: Icons.hourglass_empty,
            text: 'Loading supplier data...',
          )
        else if (_error != null)
          _StateMessage(icon: Icons.error_outline, text: _error!, retry: _load)
        else if (_subscriptions.isEmpty &&
            _deliveries.isEmpty &&
            _newspapers.isEmpty)
          _StateMessage(
            icon: Icons.inbox_outlined,
            text: 'No supplier records available yet.',
            retry: _load,
          )
        else
          _content(context),
      ],
    ),
  );

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _card('Active subscriptions', '$_activeSubscriptions'),
          ),
          const SizedBox(width: 10),
          Expanded(child: _card('Customers served', '$_customers')),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _card('Newspapers offered', '$_newspapersCount'),
          ),
          const SizedBox(width: 10),
          Expanded(child: _card('Total deliveries', '${_deliveries.length}')),
        ],
      ),
      const SizedBox(height: 17),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DailyColors.charcoal,
          border: Border.all(color: DailyColors.charcoal),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _deliveries.isEmpty
                  ? 'No delivery records recorded'
                  : '$_delivered delivered · $_pending remaining',
              style: const TextStyle(color: Color(0xFFC8BBA8), fontSize: 16),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _deliveries.isEmpty ? 0 : _delivered / _deliveries.length,
              color: const Color(0xFFE5C9A8),
              backgroundColor: const Color(0xFF5D5A56),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupplierDistributionScreen(),
                  ),
                ),
                child: const Text(
                  'VIEW DISTRIBUTION →',
                  style: TextStyle(
                    color: Color(0xFFE5C9A8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'SUPPLIED NEWSPAPERS',
            style: TextStyle(
              color: DailyColors.burgundy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '$_newspapersCount total',
            style: const TextStyle(color: DailyColors.gray, fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (_newspapers.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DailyColors.white,
            border: Border.all(color: DailyColors.divider),
          ),
          child: const Text(
            'No newspapers available for this supplier.',
            style: TextStyle(color: DailyColors.gray, fontSize: 15),
          ),
        )
      else
        ..._newspapers.take(4).map((n) {
          final price = n['price_per_delivery'] != null
              ? '₹${n['price_per_delivery']}'
              : '—';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.newspaper,
                  color: DailyColors.burgundy,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['newspaper_name']?.toString() ?? 'Newspaper',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DailyColors.charcoal,
                        ),
                      ),
                      Text(
                        n['language']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: DailyColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DailyColors.burgundy,
                  ),
                ),
              ],
            ),
          );
        }),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CUSTOMER ORDERS & SUBSCRIPTIONS',
            style: TextStyle(
              color: DailyColors.burgundy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '${_subscriptions.length} records',
            style: const TextStyle(color: DailyColors.gray, fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (_subscriptions.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DailyColors.white,
            border: Border.all(color: DailyColors.divider),
          ),
          child: const Text(
            'No customer subscriptions found.',
            style: TextStyle(color: DailyColors.gray, fontSize: 15),
          ),
        )
      else
        ..._subscriptions.take(3).map((sub) {
          final customerName = sub['customer_name']?.toString() ?? 'Customer';
          final newspaperName = sub['newspaper_name']?.toString() ?? 'Newspaper';
          final status = sub['status']?.toString().toUpperCase() ?? 'UNKNOWN';
          final price = sub['agreed_price'] != null ? '₹${sub['agreed_price']}' : '—';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DailyColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        newspaperName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: DailyColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status == 'ACTIVE'
                            ? Colors.green.shade800
                            : DailyColors.gray,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DailyColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
    ],
  );

  Widget _card(String title, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DailyColors.white,
      border: Border.all(color: DailyColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: DailyColors.gray),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: DailyColors.charcoal,
          ),
        ),
      ],
    ),
  );

  String _today() {
    final d = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
