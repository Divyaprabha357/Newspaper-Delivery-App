import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class NewspaperDetailScreen extends StatefulWidget {
  final Map<String, dynamic> newspaper;
  final int customerId;
  final Map<String, dynamic>? customerProfile;

  const NewspaperDetailScreen({
    super.key,
    required this.newspaper,
    required this.customerId,
    this.customerProfile,
  });

  @override
  State<NewspaperDetailScreen> createState() => _NewspaperDetailScreenState();
}

class _NewspaperDetailScreenState extends State<NewspaperDetailScreen> {
  final _api = CustomerApiService();
  bool _submitting = false;
  bool _loadingProfile = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.customerProfile;
    if (_profile == null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final res = await _api.profile(widget.customerId);
      if (res['user'] != null && mounted) {
        setState(() {
          _profile = Map<String, dynamic>.from(res['user'] as Map);
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _formatPrice(dynamic perDelivery) {
    if (perDelivery == null) return 'Price unavailable';
    final priceNum = double.tryParse('$perDelivery');
    if (priceNum == null) return '₹$perDelivery / delivery';
    final monthly = priceNum * 30;
    return '₹${monthly.toStringAsFixed(2)} / month (₹${priceNum.toStringAsFixed(2)} / delivery)';
  }

  Future<void> _confirmSubscription() async {
    if (_submitting) return;

    final newspaperId = int.tryParse('${widget.newspaper['newspaper_id']}');
    final supplierId = int.tryParse('${widget.newspaper['supplier_id']}');
    final paperName = '${widget.newspaper['newspaper_name'] ?? 'Newspaper'}';

    if (newspaperId == null || supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid newspaper or supplier information.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _api.createSubscription(
        customerId: widget.customerId,
        newspaperId: newspaperId,
        supplierId: supplierId,
        deliveryDays: 'MON,TUE,WED,THU,FRI,SAT,SUN',
        scheduledDeliveryTime: '07:00:00',
      );

      if (!mounted) return;

      // Show explicit confirmation dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: DailyColors.white,
          title: const Text('Subscription Confirmed'),
          content: Text(
            'You have successfully subscribed to $paperName.\n\n'
            'Your daily morning delivery will begin tomorrow at your registered delivery address.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: DailyColors.burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('VIEW MY SUBSCRIPTIONS'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on CustomerApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: DailyColors.burgundy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.newspaper['newspaper_name'] ?? 'Newspaper'}';
    final language = '${widget.newspaper['language'] ?? 'English'}';
    final category = '${widget.newspaper['publication_type'] ?? 'Daily Edition'}';
    final supplierName = '${widget.newspaper['supplier_name'] ?? 'National Daily Editions'}';
    final supplierContact = widget.newspaper['supplier_contact'] != null
        ? '${widget.newspaper['supplier_contact']}'
        : null;
    final priceStr = _formatPrice(widget.newspaper['price_per_delivery']);

    final addressParts = [
      _profile?['address_line'],
      _profile?['city'],
      _profile?['pincode'] != null ? 'Pincode: ${_profile?['pincode']}' : null,
    ].where((part) => part != null && '$part'.trim().isNotEmpty).join(', ');
    final addressText = addressParts.isNotEmpty
        ? addressParts
        : (_loadingProfile ? 'Loading delivery address...' : 'Registered customer address');
    final instructions = _profile?['delivery_instructions'];

    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Review Subscription',
                onBack: _submitting ? null : () => Navigator.pop(context, false),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Publication Header Card
                    Card(
                      elevation: 0,
                      color: DailyColors.white,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: DailyColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NewspaperThumb(title: name, width: 84),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: DailyColors.olive.withValues(alpha: 0.15),
                                      border: Border.all(color: DailyColors.oliveDark),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'AVAILABLE NOW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: DailyColors.oliveDark,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$language • $category',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: DailyColors.gray,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    priceStr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: DailyColors.burgundy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Section 1: Publication Information
                    const SectionLabel('Publication Details'),
                    const SizedBox(height: 8),
                    _sectionBox([
                      _itemRow(Icons.translate, 'Language', language),
                      _itemRow(Icons.category_outlined, 'Category', category),
                      _itemRow(Icons.repeat, 'Frequency', 'Monday – Sunday (Daily)'),
                      _itemRow(
                        Icons.description_outlined,
                        'Description',
                        'Delivers comprehensive morning coverage including regional and national news, business updates, and editorial commentary.',
                      ),
                    ]),

                    const SizedBox(height: 18),

                    // Section 2: Delivery & Supplier Review
                    const SectionLabel('Delivery & Supplier Information'),
                    const SizedBox(height: 8),
                    _sectionBox([
                      _itemRow(
                        Icons.home_outlined,
                        'Delivery Address',
                        addressText,
                        extra: instructions != null && '$instructions'.isNotEmpty
                            ? 'Instructions: $instructions'
                            : null,
                      ),
                      _itemRow(Icons.alarm, 'Delivery Time', '07:00 AM (Early Morning)'),
                      _itemRow(
                        Icons.business_outlined,
                        'Supplier',
                        supplierName,
                        extra: supplierContact != null ? 'Contact: $supplierContact' : null,
                      ),
                      _itemRow(
                        Icons.motorcycle_outlined,
                        'Delivery Partner',
                        'Assigned after confirmation',
                        extra: 'A verified partner from your local morning route will deliver this edition.',
                      ),
                      _itemRow(Icons.receipt_long_outlined, 'Billing Frequency', 'Monthly (Charged per delivery)'),
                    ]),

                    const SizedBox(height: 24),

                    // Pricing Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DailyColors.tan.withValues(alpha: 0.4),
                        border: Border.all(color: DailyColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: DailyColors.burgundy),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SUBSCRIPTION SUMMARY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: DailyColors.burgundy,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$name • $priceStr',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons: Confirm and Cancel
                    if (_submitting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: DailyColors.burgundy),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _confirmSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DailyColors.burgundy,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text(
                            'CONFIRM SUBSCRIPTION',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DailyColors.charcoal,
                            side: const BorderSide(color: DailyColors.divider),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: const Text(
                            'GO BACK / CANCEL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _itemRow(IconData icon, String label, String value, {String? extra}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DailyColors.burgundy),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DailyColors.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: DailyColors.charcoal,
                  ),
                ),
                if (extra != null && extra.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    extra,
                    style: const TextStyle(
                      fontSize: 11,
                      color: DailyColors.gray,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
