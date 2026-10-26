import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'newspaper_detail_screen.dart';
import 'subscription_detail_screen.dart';

class SubscriptionCatalogScreen extends StatefulWidget {
  const SubscriptionCatalogScreen({super.key});
  @override
  State<SubscriptionCatalogScreen> createState() => _SubscriptionCatalogScreenState();
}

class _SubscriptionCatalogScreenState extends State<SubscriptionCatalogScreen> {
  final _api = CustomerApiService();
  bool _loading = true;
  String? _error;
  int? _customerId;
  Map<String, dynamic>? _customerProfile;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _newspapers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await SessionService.getCustomerId();
      if (id == null) throw const CustomerApiException('Please sign in again.');
      final results = await Future.wait([
        _api.subscriptions(id),
        _api.newspapers(),
        _api.profile(id),
      ]);
      if (!mounted) return;
      setState(() {
        _customerId = id;
        _subscriptions = _list(results[0], 'subscriptions');
        _newspapers = _list(results[1], 'newspapers');
        if (results[2]['user'] != null) {
          _customerProfile = Map<String, dynamic>.from(results[2]['user'] as Map);
        }
        _loading = false;
      });
    } on CustomerApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) =>
      (data[key] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

  String _formatPrice(dynamic value) {
    if (value == null) return 'Price unavailable';
    final priceNum = double.tryParse('$value');
    if (priceNum == null) return '₹$value / delivery';
    final monthly = priceNum * 30;
    return '₹${monthly.toStringAsFixed(2)} / mo (₹${priceNum.toStringAsFixed(2)}/day)';
  }

  @override
  Widget build(BuildContext context) {
    final active = _subscriptions.where((s) => '${s['status']}'.toUpperCase() == 'ACTIVE').toList();
    final paused = _subscriptions.where((s) => '${s['status']}'.toUpperCase() == 'PAUSED').toList();
    final cancelled = _subscriptions.where((s) => '${s['status']}'.toUpperCase() == 'CANCELLED').toList();

    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'My Subscriptions',
                trailing: Text(
                  '${active.length} ACTIVE',
                  style: const TextStyle(
                    fontSize: 14,
                    color: DailyColors.burgundy,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: DailyColors.burgundy))
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          color: DailyColors.burgundy,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(22, 14, 22, 90),
                            children: [
                              const Text(
                                'Your active newspapers',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap any subscription to view complete delivery details, route, supplier info, and manage your plan.',
                                style: TextStyle(fontSize: 14, color: DailyColors.gray, height: 1.45),
                              ),
                              const SizedBox(height: 20),

                              if (_subscriptions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'You do not have any subscriptions yet. Tap below to browse and add a newspaper.',
                                    style: TextStyle(color: DailyColors.gray),
                                  ),
                                )
                              else ...[
                                if (active.isNotEmpty) ...[
                                  ...active.map((s) => _SubscriptionCard(
                                        subscription: s,
                                        price: _formatPrice(s['agreed_price']),
                                        customerId: _customerId,
                                        onChanged: _load,
                                      )),
                                ],
                                if (paused.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const SectionLabel('Paused Subscriptions'),
                                  const SizedBox(height: 8),
                                  ...paused.map((s) => _SubscriptionCard(
                                        subscription: s,
                                        price: _formatPrice(s['agreed_price']),
                                        customerId: _customerId,
                                        onChanged: _load,
                                      )),
                                ],
                                if (cancelled.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const SectionLabel('Cancelled Subscriptions'),
                                  const SizedBox(height: 8),
                                  ...cancelled.map((s) => _SubscriptionCard(
                                        subscription: s,
                                        price: _formatPrice(s['agreed_price']),
                                        customerId: _customerId,
                                        onChanged: _load,
                                      )),
                                ],
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DailyColors.burgundy,
        foregroundColor: Colors.white,
        tooltip: 'Add newspaper',
        onPressed: _customerId == null
            ? null
            : () async {
                final didSubscribe = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _NewspaperCatalogScreen(
                      newspapers: _newspapers,
                      customerId: _customerId,
                      customerProfile: _customerProfile,
                    ),
                  ),
                );
                if (didSubscribe == true) {
                  _load();
                }
              },
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'ADD NEW SUBSCRIPTION',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.price,
    required this.customerId,
    required this.onChanged,
  });

  final Map<String, dynamic> subscription;
  final String price;
  final int? customerId;
  final VoidCallback onChanged;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return DailyColors.oliveDark;
      case 'PAUSED':
        return DailyColors.warning;
      case 'CANCELLED':
        return DailyColors.gray;
      default:
        return DailyColors.charcoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${subscription['newspaper_name'] ?? 'Newspaper'}';
    final status = '${subscription['status'] ?? 'ACTIVE'}'.toUpperCase();
    final language = '${subscription['language'] ?? ''}';
    final supplier = '${subscription['supplier_name'] ?? 'Assigned Supplier'}';
    final deliveryTime = subscription['scheduled_delivery_time'] != null
        ? '${subscription['scheduled_delivery_time']}'.split(':').take(2).join(':')
        : '07:00 AM';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: DailyColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: DailyColors.divider),
      ),
      child: InkWell(
        onTap: () async {
          if (customerId == null) return;
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionDetailScreen(
                subscription: subscription,
                customerId: customerId!,
              ),
            ),
          );
          if (changed == true) {
            onChanged();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NewspaperThumb(title: name, width: 80),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            border: Border.all(color: _statusColor(status), width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (language.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• $language',
                            style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Supplier: $supplier',
                      style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Delivery: $deliveryTime',
                      style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DailyColors.burgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 28, color: DailyColors.burgundy),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewspaperCatalogScreen extends StatefulWidget {
  const _NewspaperCatalogScreen({
    required this.newspapers,
    required this.customerId,
    this.customerProfile,
  });

  final List<Map<String, dynamic>> newspapers;
  final int? customerId;
  final Map<String, dynamic>? customerProfile;

  @override
  State<_NewspaperCatalogScreen> createState() => _NewspaperCatalogScreenState();
}

class _NewspaperCatalogScreenState extends State<_NewspaperCatalogScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final papers = widget.newspapers
        .where((p) => '${p['newspaper_name']}'.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Newspapers',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.search, size: 23),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                children: [
                  TextField(
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search newspapers...',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (papers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No newspapers are currently available.',
                        style: TextStyle(color: DailyColors.gray),
                      ),
                    )
                  else ...[
                    const Text(
                      'Available Editions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select a newspaper to review subscription pricing, delivery address, and confirm your order.',
                      style: TextStyle(fontSize: 12, color: DailyColors.gray),
                    ),
                    const SizedBox(height: 14),
                    ...papers.map((paper) {
                      final name = '${paper['newspaper_name']}';
                      final lang = '${paper['language'] ?? ''}';
                      final type = '${paper['publication_type'] ?? ''}';
                      final price = paper['price_per_delivery'];
                      final priceNum = double.tryParse('$price');
                      final priceStr = priceNum != null
                          ? '₹${(priceNum * 30).toStringAsFixed(2)} / mo (₹$price/delivery)'
                          : '₹$price / delivery';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: DailyColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: DailyColors.divider),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: InkWell(
                          onTap: widget.customerId == null
                              ? null
                              : () async {
                                  // Open details/review screen before subscription creation
                                  // (must NOT immediately create subscription)
                                  final navigator = Navigator.of(context);
                                  final subscribed = await navigator.push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => NewspaperDetailScreen(
                                        newspaper: paper,
                                        customerId: widget.customerId!,
                                        customerProfile: widget.customerProfile,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;
                                  if (subscribed == true) {
                                    // Pop back from catalog to My Subscriptions and trigger refresh
                                    navigator.pop(true);
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                NewspaperThumb(title: name, width: 70),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$lang • $type',
                                        style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        priceStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: DailyColors.burgundy,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 24, color: DailyColors.burgundy),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ),
      );
}
