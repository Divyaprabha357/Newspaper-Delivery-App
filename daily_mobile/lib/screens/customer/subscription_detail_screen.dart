import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'delivery_history_screen.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;
  final int customerId;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscription,
    required this.customerId,
  });

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  final _api = CustomerApiService();
  late Map<String, dynamic> _sub;
  bool _loading = false;
  bool _actionLoading = false;
  bool _hasChanges = false;
  List<Map<String, dynamic>> _availableNewspapers = [];

  @override
  void initState() {
    super.initState();
    _sub = Map<String, dynamic>.from(widget.subscription);
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    final subId = int.tryParse('${_sub['subscription_id']}');
    if (subId == null) return;
    setState(() => _loading = true);
    try {
      final res = await _api.subscriptionDetail(widget.customerId, subId);
      if (res['subscription'] != null && mounted) {
        setState(() {
          _sub = Map<String, dynamic>.from(res['subscription'] as Map);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatStatus(dynamic s) {
    return (s ?? 'ACTIVE').toString().toUpperCase();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return DailyColors.success;
      case 'PAUSED':
        return DailyColors.warning;
      case 'CANCELLED':
        return DailyColors.gray;
      default:
        return DailyColors.charcoal;
    }
  }

  String _formatPrice(dynamic perDelivery) {
    if (perDelivery == null) return 'Price unavailable';
    final priceNum = double.tryParse('$perDelivery');
    if (priceNum == null) return '₹$perDelivery / delivery';
    final monthly = priceNum * 30;
    return '₹${monthly.toStringAsFixed(2)} / month (₹${priceNum.toStringAsFixed(2)} / delivery)';
  }

  String _formatDeliveryTime(dynamic time) {
    if (time == null || time.toString().isEmpty) return 'Delivery time not specified';
    final raw = time.toString();
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final min = parts[1];
      if (hour != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:$min $period';
      }
    }
    return raw;
  }

  String _formatDays(dynamic days) {
    if (days == null || days.toString().isEmpty) return 'Daily';
    final d = days.toString().toUpperCase();
    if (d.contains('MON') && d.contains('SUN')) {
      return 'Monday – Sunday (Daily)';
    }
    return d.replaceAll(',', ', ');
  }

  String _getNextRenewalDate(dynamic startDate) {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final y = nextMonth.year.toString();
    final m = nextMonth.month.toString().padLeft(2, '0');
    final day = nextMonth.day.toString().padLeft(2, '0');
    return '$y-$m-$day (1st of next month)';
  }

  Future<void> _updateStatus(String newStatus) async {
    final subId = int.tryParse('${_sub['subscription_id']}');
    if (subId == null) return;

    final actionName = newStatus == 'PAUSED'
        ? 'Pause'
        : newStatus == 'ACTIVE'
            ? 'Resume'
            : 'Cancel';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DailyColors.white,
        title: Text('$actionName Subscription?'),
        content: Text(
          newStatus == 'CANCELLED'
              ? 'Are you sure you want to cancel this subscription? Deliveries will be stopped.'
              : newStatus == 'PAUSED'
                  ? 'Are you sure you want to pause this subscription? You can resume deliveries at any time.'
                  : 'Resume delivery for this subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: DailyColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'CANCELLED' ? DailyColors.burgundy : DailyColors.oliveDark,
              foregroundColor: Colors.white,
            ),
            child: Text('CONFIRM $actionName'.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _api.updateSubscription(widget.customerId, subId, newStatus);
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription has been $newStatus.')),
        );
      }
      await _refreshDetails();
    } on CustomerApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openChangeNewspaperDialog() async {
    final subId = int.tryParse('${_sub['subscription_id']}');
    if (subId == null) return;

    setState(() => _actionLoading = true);
    try {
      if (_availableNewspapers.isEmpty) {
        final res = await _api.newspapers();
        final list = (res['newspapers'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _availableNewspapers = list;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load available newspapers.')),
        );
      }
      if (mounted) setState(() => _actionLoading = false);
      return;
    }
    if (mounted) setState(() => _actionLoading = false);

    final currentNewspaperId = '${_sub['newspaper_id']}';
    final choices = _availableNewspapers.where((p) => '${p['newspaper_id']}' != currentNewspaperId).toList();

    if (!mounted) return;

    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other newspapers are currently available to switch to.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: DailyColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Newspaper',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: DailyColors.divider),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: choices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, idx) {
                      final item = choices[idx];
                      final name = '${item['newspaper_name']}';
                      final price = item['price_per_delivery'];
                      final lang = '${item['language'] ?? ''}';
                      final supplier = '${item['supplier_name'] ?? ''}';
                      return Card(
                        color: DailyColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: DailyColors.divider),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          leading: NewspaperThumb(title: name, width: 44),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$lang • $supplier\n₹$price / delivery'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: DailyColors.burgundy),
                          onTap: () => Navigator.pop(ctx, item),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;

    final newNewspaperId = int.tryParse('${selected['newspaper_id']}');
    final newSupplierId = int.tryParse('${selected['supplier_id']}');
    final newName = '${selected['newspaper_name']}';

    if (newNewspaperId == null || newSupplierId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DailyColors.white,
        title: const Text('Confirm Newspaper Change'),
        content: Text(
          'Switch your subscription from "${_sub['newspaper_name']}" to "$newName"?\n\n'
          'Price: ₹${selected['price_per_delivery']} / delivery.\nSupplier: ${selected['supplier_name'] ?? 'Assigned Supplier'}',
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
            child: const Text('CONFIRM SWITCH'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _api.changeSubscriptionNewspaper(
        customerId: widget.customerId,
        subscriptionId: subId,
        newNewspaperId: newNewspaperId,
        newSupplierId: newSupplierId,
      );
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription successfully switched to $newName.')),
        );
      }
      await _refreshDetails();
    } on CustomerApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _formatStatus(_sub['status']);
    final newspaperName = '${_sub['newspaper_name'] ?? 'Newspaper'}';
    final language = _sub['language'] != null && '${_sub['language']}'.isNotEmpty
        ? '${_sub['language']}'
        : 'Not available';
    final publicationType = _sub['publication_type'] != null && '${_sub['publication_type']}'.isNotEmpty
        ? '${_sub['publication_type']}'
        : 'Daily Edition';
    final frequency = _formatDays(_sub['delivery_days']);
    final monthlyPrice = _formatPrice(_sub['agreed_price']);

    final startDate = _sub['start_date'] != null
        ? '${_sub['start_date']}'.split('T').first
        : 'Not available';
    final endDate = _sub['end_date'] != null && '${_sub['end_date']}'.isNotEmpty
        ? '${_sub['end_date']}'.split('T').first
        : 'Ongoing';
    final renewalDate = _getNextRenewalDate(_sub['start_date']);
    final deliveryTime = _formatDeliveryTime(_sub['scheduled_delivery_time']);

    final addressParts = [
      _sub['address_line'],
      _sub['city'],
      _sub['pincode'] != null ? 'Pincode: ${_sub['pincode']}' : null,
    ].where((part) => part != null && '$part'.trim().isNotEmpty).join(', ');
    final addressText = addressParts.isNotEmpty ? addressParts : 'Delivery address not registered';
    final instructions = _sub['delivery_instructions'];

    final supplierName = _sub['supplier_name'] ?? 'Not available';
    final supplierContact = _sub['supplier_contact'] ?? 'Not available';
    final supplierAddress = _sub['supplier_address'] ?? 'Not available';

    final partnerName = _sub['partner_name'] ?? 'Not assigned yet';
    final partnerPhone = _sub['partner_phone'] ?? 'Not available';
    final partnerCode = _sub['partner_code'] != null ? '(${_sub['partner_code']})' : '';
    final routeName = _sub['route_name'] ?? 'Not assigned yet';

    final isCancelled = status == 'CANCELLED';
    final isPaused = status == 'PAUSED';
    final isActive = status == 'ACTIVE';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: DailyColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
                child: DailyHeader(
                  title: 'Subscription Details',
                  onBack: () => Navigator.pop(context, _hasChanges),
                  trailing: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: DailyColors.burgundy),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.refresh, size: 22, color: DailyColors.burgundy),
                          tooltip: 'Refresh details',
                          onPressed: _refreshDetails,
                        ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
                  children: [
                    // Header Card: Newspaper Thumbnail & Basic Info
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
                            NewspaperThumb(title: newspaperName, width: 84),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.12),
                                      border: Border.all(color: _statusColor(status)),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _statusColor(status),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    newspaperName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$language • $publicationType',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: DailyColors.gray,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    monthlyPrice,
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

                    // Section 1: Subscription Information
                    const SectionLabel('Subscription Information'),
                    const SizedBox(height: 8),
                    _sectionBox([
                      _itemRow(Icons.calendar_today_outlined, 'Start Date', startDate),
                      _itemRow(Icons.event_outlined, 'End Date', endDate),
                      _itemRow(Icons.update_outlined, 'Next Renewal', renewalDate),
                      _itemRow(Icons.receipt_long_outlined, 'Billing Period', 'Monthly'),
                      _itemRow(Icons.alarm, 'Delivery Time', deliveryTime),
                      _itemRow(Icons.repeat, 'Frequency', frequency),
                      _itemRow(
                        Icons.home_outlined,
                        'Delivery Address',
                        addressText,
                        extra: instructions != null && '$instructions'.isNotEmpty
                            ? 'Instructions: $instructions'
                            : null,
                      ),
                    ]),

                    const SizedBox(height: 18),

                    // Section 2: Supplier & Delivery Information
                    const SectionLabel('Supplier & Delivery Partner'),
                    const SizedBox(height: 8),
                    _sectionBox([
                      _itemRow(
                        Icons.business_outlined,
                        'Supplier Name',
                        '$supplierName',
                        extra: 'Contact: $supplierContact\nAddress: $supplierAddress',
                      ),
                      _itemRow(
                        Icons.motorcycle_outlined,
                        'Delivery Partner',
                        '$partnerName $partnerCode'.trim(),
                        extra: partnerName != 'Not assigned yet'
                            ? 'Phone: $partnerPhone'
                            : 'Assigned on delivery route',
                      ),
                      _itemRow(
                        Icons.alt_route_outlined,
                        'Delivery Route',
                        '$routeName',
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Section 3: Subscription Actions
                    const SectionLabel('Subscription Actions'),
                    const SizedBox(height: 12),

                    if (_actionLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: DailyColors.burgundy),
                        ),
                      )
                    else ...[
                      // Pause or Resume
                      if (isActive)
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus('PAUSED'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DailyColors.warning,
                            side: const BorderSide(color: DailyColors.warning, width: 1.2),
                            minimumSize: const Size(double.infinity, 44),
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.pause_circle_outline, size: 20),
                          label: const Text('PAUSE SUBSCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                        ),

                      if (isPaused)
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus('ACTIVE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DailyColors.oliveDark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.play_circle_outline, size: 20),
                          label: const Text('RESUME SUBSCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                        ),

                      if (!isCancelled) const SizedBox(height: 10),

                      // Change Newspaper
                      if (!isCancelled)
                        OutlinedButton.icon(
                          onPressed: _openChangeNewspaperDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DailyColors.charcoal,
                            side: const BorderSide(color: DailyColors.divider, width: 1.2),
                            minimumSize: const Size(double.infinity, 44),
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 20, color: DailyColors.burgundy),
                          label: const Text('CHANGE NEWSPAPER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                        ),

                      const SizedBox(height: 10),

                      // View Delivery History
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DailyColors.burgundy,
                          side: const BorderSide(color: DailyColors.burgundy, width: 1.2),
                          minimumSize: const Size(double.infinity, 44),
                          shape: const RoundedRectangleBorder(),
                        ),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('VIEW DELIVERY HISTORY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                      ),

                      if (!isCancelled) const SizedBox(height: 10),

                      // Cancel Subscription
                      if (!isCancelled)
                        TextButton.icon(
                          onPressed: () => _updateStatus('CANCELLED'),
                          style: TextButton.styleFrom(
                            foregroundColor: DailyColors.burgundy,
                            minimumSize: const Size(double.infinity, 42),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 19),
                          label: const Text('CANCEL SUBSCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
            width: 100,
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
