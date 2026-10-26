import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class SupplierRequestsScreen extends StatefulWidget {
  const SupplierRequestsScreen({super.key});

  @override
  State<SupplierRequestsScreen> createState() => _SupplierRequestsScreenState();
}

class _SupplierRequestsScreenState extends State<SupplierRequestsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _error;
  String _categoryFilter = 'ALL'; // ALL, REQUESTS, COMPLAINTS
  String _statusFilter = 'ALL';   // ALL, PENDING, COMPLETED
  int? _supplierId;
  int? _userId;
  String? _sessionToken;

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

      _supplierId = supplierId;
      _userId = userId;
      _sessionToken = token;

      final res = await RoleApiService(authToken: token).supplierRequests(
        userId ?? supplierId!,
        supplierId: supplierId,
      );

      final reqList = (res['requests'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final compList = (res['complaints'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _requests = reqList;
          _complaints = compList;
          _loading = false;
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
          _error = 'Unable to load requests right now. Please check your connection and retry.';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _combinedItems {
    final list = <Map<String, dynamic>>[];

    if (_categoryFilter == 'ALL' || _categoryFilter == 'REQUESTS') {
      for (final r in _requests) {
        list.add({
          ...r,
          '_isComplaint': false,
          '_itemType': 'REQUEST',
          '_id': r['request_id'],
          '_title': r['request_type']?.toString().replaceAll('_', ' ') ?? 'Customer Request',
          '_status': (r['status'] ?? 'PENDING').toString().toUpperCase(),
          '_date': r['created_at'],
          '_updatedDate': r['completed_at'],
          '_customerName': r['customer_name'] ?? 'Customer',
          '_customerPhone': r['customer_phone'] ?? '—',
          '_newspaper': r['newspaper_name'] ?? 'All Subscriptions',
          '_description': r['description'] ?? '',
          '_resolution': null,
        });
      }
    }

    if (_categoryFilter == 'ALL' || _categoryFilter == 'COMPLAINTS') {
      for (final c in _complaints) {
        list.add({
          ...c,
          '_isComplaint': true,
          '_itemType': 'COMPLAINT',
          '_id': c['complaint_id'],
          '_title': c['complaint_type']?.toString().replaceAll('_', ' ') ?? 'Delivery Complaint',
          '_status': (c['status'] ?? 'OPEN').toString().toUpperCase(),
          '_date': c['created_at'],
          '_updatedDate': c['resolved_at'],
          '_customerName': c['customer_name'] ?? 'Customer',
          '_customerPhone': c['customer_phone'] ?? '—',
          '_newspaper': c['newspaper_name'] ?? 'Delivered Edition',
          '_description': c['description'] ?? '',
          '_resolution': c['resolution'],
        });
      }
    }

    // Sort descending by created_at
    list.sort((a, b) {
      final da = DateTime.tryParse(a['_date']?.toString() ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b['_date']?.toString() ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });

    final q = _search.text.trim().toLowerCase();
    return list.where((item) {
      final status = item['_status'].toString();

      if (_statusFilter == 'PENDING') {
        if (!['PENDING', 'OPEN', 'IN_PROGRESS'].contains(status)) return false;
      } else if (_statusFilter == 'COMPLETED') {
        if (!['COMPLETED', 'APPROVED', 'RESOLVED', 'REJECTED'].contains(status)) return false;
      }

      if (q.isEmpty) return true;

      return [
        item['_id'],
        item['_title'],
        item['_customerName'],
        item['_customerPhone'],
        item['_newspaper'],
        item['_description'],
        item['_status'],
        item['_resolution'],
      ].any((v) => v != null && v.toString().toLowerCase().contains(q));
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'APPROVED':
      case 'RESOLVED':
        return DailyColors.success;
      case 'PENDING':
      case 'OPEN':
      case 'IN_PROGRESS':
        return DailyColors.warning;
      case 'REJECTED':
        return DailyColors.burgundy;
      default:
        return DailyColors.charcoal;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final str = value.toString().split('T').first;
    return str;
  }

  Future<void> _updateItemStatus(Map<String, dynamic> item) async {
    final isComplaint = item['_isComplaint'] == true;
    final itemId = int.tryParse('${item['_id']}');
    if (itemId == null || _userId == null) return;

    final currentStatus = item['_status'].toString();
    final allowedStatuses = isComplaint
        ? ['OPEN', 'IN_PROGRESS', 'RESOLVED']
        : ['PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'];

    String selectedStatus = currentStatus;
    final resolutionController = TextEditingController(text: item['_resolution']?.toString() ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DailyColors.white,
              title: Text(
                'Update ${isComplaint ? "Complaint" : "Request"} #${item["_id"]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item["_title"]} • ${item["_customerName"]}',
                      style: const TextStyle(fontSize: 13, color: DailyColors.gray),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Status'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: allowedStatuses.contains(selectedStatus) ? selectedStatus : allowedStatuses.first,
                      items: allowedStatuses.map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    if (isComplaint) ...[
                      const SizedBox(height: 14),
                      const SectionLabel('Resolution Notes'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: resolutionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter resolution note or action taken...',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('CANCEL', style: TextStyle(color: DailyColors.gray)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DailyColors.burgundy,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SAVE STATUS'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final api = RoleApiService(authToken: _sessionToken);
      if (isComplaint) {
        await api.updateSupplierComplaintStatus(
          userId: _userId!,
          supplierId: _supplierId,
          complaintId: itemId,
          status: selectedStatus,
          resolution: resolutionController.text.trim().isNotEmpty ? resolutionController.text.trim() : null,
        );
      } else {
        await api.updateSupplierRequestStatus(
          userId: _userId!,
          supplierId: _supplierId,
          requestId: itemId,
          status: selectedStatus,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $selectedStatus.')),
        );
      }
      await _load();
    } on RoleApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final isComplaint = item['_isComplaint'] == true;
    final title = item['_title'];
    final id = item['_id'];
    final customer = item['_customerName'];
    final phone = item['_customerPhone'];
    final newspaper = item['_newspaper'];
    final status = item['_status'];
    final date = _formatDate(item['_date']);
    final updatedDate = _formatDate(item['_updatedDate']);
    final description = item['_description'];
    final resolution = item['_resolution'];
    final partner = item['partner_name'];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DailyColors.white,
        title: Row(
          children: [
            Icon(
              isComplaint ? Icons.report_problem_outlined : Icons.support_agent_outlined,
              color: DailyColors.burgundy,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${isComplaint ? "Complaint" : "Request"} #$id',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Type', title),
              _detailRow('Customer', '$customer ($phone)'),
              _detailRow('Edition', newspaper),
              _detailRow('Status', status, statusColor: _statusColor(status)),
              _detailRow('Date Submitted', date),
              if (updatedDate != '—') _detailRow('Last Updated', updatedDate),
              if (partner != null && '$partner'.isNotEmpty) _detailRow('Assigned Partner', '$partner'),
              const SizedBox(height: 8),
              const SectionLabel('Description'),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DailyColors.cream,
                  border: Border.all(color: DailyColors.divider),
                ),
                child: Text(
                  description.isNotEmpty ? description : 'No description provided.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              if (resolution != null && '$resolution'.isNotEmpty) ...[
                const SizedBox(height: 10),
                const SectionLabel('Resolution'),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DailyColors.success.withValues(alpha: 0.08),
                    border: Border.all(color: DailyColors.success),
                  ),
                  child: Text(
                    resolution,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: DailyColors.oliveDark),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateItemStatus(item);
            },
            style: OutlinedButton.styleFrom(foregroundColor: DailyColors.burgundy),
            child: const Text('RESPOND / UPDATE STATUS'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: DailyColors.gray)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: DailyColors.gray, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor ?? DailyColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _combinedItems;

    return RefreshIndicator(
      color: DailyColors.burgundy,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUPPLIER SUPPORT',
              style: TextStyle(
                color: DailyColors.burgundy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Requests & Complaints',
                  style: TextStyle(
                    color: DailyColors.charcoal,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: DailyColors.burgundy),
                  tooltip: 'Refresh',
                  onPressed: _load,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by customer, edition, request type, description...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Chips: Category & Status
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('ALL', 'All (${_requests.length + _complaints.length})'),
                  const SizedBox(width: 8),
                  _categoryChip('REQUESTS', 'Requests (${_requests.length})'),
                  const SizedBox(width: 8),
                  _categoryChip('COMPLAINTS', 'Complaints (${_complaints.length})'),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 24, color: DailyColors.divider),
                  const SizedBox(width: 14),
                  _statusChip('ALL', 'All Statuses'),
                  const SizedBox(width: 8),
                  _statusChip('PENDING', 'Pending / Open'),
                  const SizedBox(width: 8),
                  _statusChip('COMPLETED', 'Resolved / Completed'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // State Handling
            if (_loading)
              const _StateMessage(
                icon: Icons.hourglass_empty,
                text: 'Loading requests and complaints...',
              )
            else if (_error != null)
              _StateMessage(
                icon: Icons.error_outline,
                text: _error!,
                retry: _load,
              )
            else if (_requests.isEmpty && _complaints.isEmpty)
              const _StateMessage(
                icon: Icons.assignment_turned_in_outlined,
                text: 'No requests available.',
              )
            else if (items.isEmpty)
              const _StateMessage(
                icon: Icons.search_off,
                text: 'No matching requests or complaints found.',
              )
            else
              ...items.map((item) => _itemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String key, String label) {
    final isSelected = _categoryFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : DailyColors.charcoal,
        ),
      ),
      selected: isSelected,
      selectedColor: DailyColors.burgundy,
      backgroundColor: DailyColors.white,
      side: const BorderSide(color: DailyColors.divider),
      onSelected: (_) => setState(() => _categoryFilter = key),
    );
  }

  Widget _statusChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? DailyColors.burgundy : DailyColors.gray,
        ),
      ),
      selected: isSelected,
      selectedColor: DailyColors.tan,
      backgroundColor: DailyColors.cream,
      side: const BorderSide(color: DailyColors.divider),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final isComplaint = item['_isComplaint'] == true;
    final title = item['_title'];
    final id = item['_id'];
    final customer = item['_customerName'];
    final newspaper = item['_newspaper'];
    final status = item['_status'];
    final date = _formatDate(item['_date']);
    final description = item['_description'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: DailyColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: DailyColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isComplaint ? DailyColors.burgundy : DailyColors.oliveDark).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isComplaint ? Icons.report_problem_outlined : Icons.support_agent_outlined,
                    size: 20,
                    color: isComplaint ? DailyColors.burgundy : DailyColors.oliveDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#${isComplaint ? "CMP" : "REQ"}-$id • Customer: $customer • Edition: $newspaper',
                        style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    border: Border.all(color: _statusColor(status), width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.4, color: DailyColors.charcoal),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted: $date',
                  style: const TextStyle(fontSize: 11, color: DailyColors.gray),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _showItemDetails(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DailyColors.charcoal,
                        side: const BorderSide(color: DailyColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('VIEW DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateItemStatus(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DailyColors.burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('RESPOND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: DailyColors.gray),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (retry != null) ...[
              const SizedBox(height: 8),
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
          ],
        ),
      );
}
