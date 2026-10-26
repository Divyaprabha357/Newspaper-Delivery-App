import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String? initialRequestType;

  const ServiceRequestScreen({super.key, this.initialRequestType});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _api = CustomerApiService();
  final _descriptionController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int? _customerId;
  List<Map<String, dynamic>> _requests = [];
  String _statusFilter = 'All';

  final _requestTypes = const [
    ('Change Newspaper', 'Switch to another daily edition.', Icons.sync_alt),
    ('Change Address', 'Update your delivery address.', Icons.location_on_outlined),
    ('Change Delivery Time', 'Modify delivery time slot.', Icons.schedule),
    ('Missed Delivery', 'Report a missed newspaper.', Icons.report_problem_outlined),
    ('Other Request', 'Create a custom request.', Icons.chat_bubble_outline),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.initialRequestType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dialog(context, widget.initialRequestType!);
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final id = await SessionService.getCustomerId();
      if (id == null) throw const CustomerApiException('Please sign in again.');
      final data = await _api.requests(id);
      if (!mounted) return;
      setState(() {
        _customerId = id;
        _requests = (data['requests'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } on CustomerApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  Future<void> _submit(String title) async {
    final description = _descriptionController.text.trim();
    if (_customerId == null || description.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _api.createRequest(
        customerId: _customerId!,
        requestType: title,
        description: description,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _descriptionController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully.')),
        );
      }
    } on CustomerApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatType(dynamic type) {
    if (type == null) return 'Service Request';
    final str = '$type'.replaceAll('_', ' ').trim();
    if (str.isEmpty) return 'Service Request';
    return str.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final str = '$value';
    return str.contains('T') ? str.split('T').first : str;
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;
    if (s == 'COMPLETED' || s == 'RESOLVED' || s == 'CLOSED') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (s == 'IN_PROGRESS' || s == 'PROCESSING') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
    } else if (s == 'REJECTED' || s == 'CANCELLED') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    } else {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(
        s,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.5),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_statusFilter == 'All') return _requests;
    if (_statusFilter == 'Resolved') {
      return _requests.where((r) {
        final s = '${r['status']}'.toUpperCase();
        return s == 'COMPLETED' || s == 'RESOLVED' || s == 'CLOSED';
      }).toList();
    }
    return _requests.where((r) {
      final s = '${r['status']}'.toUpperCase();
      return s != 'COMPLETED' && s != 'RESOLVED' && s != 'CLOSED';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Service Requests',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.info_outline, size: 18),
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
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 35),
                            children: [
                              const Text('How can we help?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: DailyColors.white,
                                  border: Border.all(color: DailyColors.divider),
                                ),
                                child: Column(
                                  children: _requestTypes.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final r = entry.value;
                                    final isLast = index == _requestTypes.length - 1;
                                    return InkWell(
                                      onTap: () => _dialog(context, r.$1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        decoration: BoxDecoration(
                                          border: isLast ? null : const Border(bottom: BorderSide(color: DailyColors.divider)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: const BoxDecoration(color: Color(0xFFF7EDEA), shape: BoxShape.circle),
                                              child: Icon(r.$3, size: 17, color: DailyColors.burgundy),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(r.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 2),
                                                  Text(r.$2, style: const TextStyle(fontSize: 12, color: DailyColors.gray)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right, size: 18, color: DailyColors.gray),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildYourRequestsSection(),
                              const SizedBox(height: 24),
                              _buildSupportBanner(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourRequestsSection() {
    final filtered = _filteredRequests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('Your Requests'),
            if (_requests.isNotEmpty)
              Text(
                '${_requests.length} ${_requests.length == 1 ? 'request' : 'requests'}',
                style: const TextStyle(fontSize: 12, color: DailyColors.gray, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_requests.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Resolved'].map((tab) {
                final isSelected = _statusFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tab),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = tab),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : DailyColors.charcoal,
                    ),
                    selectedColor: DailyColors.burgundy,
                    backgroundColor: DailyColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: BorderSide(color: isSelected ? DailyColors.burgundy : DailyColors.divider),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: const Text(
              'You have not submitted any service requests yet.',
              style: TextStyle(color: DailyColors.gray, fontSize: 13),
            ),
          )
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DailyColors.white,
              border: Border.all(color: DailyColors.divider),
            ),
            child: Text(
              'No $_statusFilter requests found.',
              style: const TextStyle(color: DailyColors.gray, fontSize: 13),
            ),
          )
        else
          ...filtered.map((request) => _requestCard(request)),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final type = _formatType(request['request_type']);
    final id = request['request_id'] != null ? '#${request['request_id']}' : '';
    final date = _formatDate(request['created_at']);
    final status = '${request['status'] ?? 'SUBMITTED'}';
    final description = '${request['description'] ?? 'No details provided.'}';
    final completedDate = request['completed_at'] != null ? _formatDate(request['completed_at']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (id.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            id,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DailyColors.gray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Submitted on $date',
                      style: const TextStyle(fontSize: 11, color: DailyColors.gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: DailyColors.divider, height: 1),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 13, height: 1.45, color: DailyColors.charcoal),
          ),
          if (completedDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF2E7D32)),
                const SizedBox(width: 5),
                Text(
                  'Resolved on $completedDate',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDEA),
        border: Border.all(color: const Color(0xFFE2B4B4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.headset_mic_outlined, color: DailyColors.burgundy, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need urgent assistance?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DailyColors.burgundy),
                ),
                SizedBox(height: 3),
                Text(
                  'Our support team is available daily from 6:00 AM to 6:00 PM for critical delivery escalations.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: DailyColors.charcoal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _dialog(BuildContext context, String title) {
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DailyColors.white,
        shape: const RoundedRectangleBorder(),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: _descriptionController,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Describe your request details...',
            hintStyle: TextStyle(fontSize: 13, color: DailyColors.gray),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: DailyColors.gray)),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : () => _submit(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: DailyColors.burgundy,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
            ),
            child: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: DailyColors.burgundy, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    ),
  );
}
