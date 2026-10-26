import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';

class SupplierCommunicationScreen extends StatefulWidget {
  const SupplierCommunicationScreen({super.key});

  @override
  State<SupplierCommunicationScreen> createState() => _SupplierCommunicationScreenState();
}

class _SupplierCommunicationScreenState extends State<SupplierCommunicationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final rawUserId = session?['user_id'];
      final userId = rawUserId is int ? rawUserId : int.tryParse('$rawUserId');

      if (userId == null) {
        throw const RoleApiException('No authenticated Supplier session found.');
      }

      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierNotifications(userId);

      if (!mounted) return;
      setState(() {
        _notifications = (response['notifications'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on RoleApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load notifications. Please check your connection.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final session = await RoleSessionService.getSupplier();
      final rawUserId = session?['user_id'];
      final userId = rawUserId is int ? rawUserId : int.tryParse('$rawUserId');
      final rawSupplierId = session?['supplier_id'];
      final supplierId = rawSupplierId is int ? rawSupplierId : int.tryParse('$rawSupplierId');

      if (userId == null) return;

      await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).markSupplierNotificationRead(
        userId: userId,
        supplierId: supplierId,
        notificationId: notificationId,
      );

      setState(() {
        final idx = _notifications.indexWhere((n) => n['notification_id'] == notificationId);
        if (idx != -1) {
          _notifications[idx]['is_read'] = 1;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update notification status.')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_filter == 'UNREAD') {
      return _notifications.where((n) => (n['is_read'] == 0 || n['is_read'] == false)).toList();
    } else if (_filter == 'READ') {
      return _notifications.where((n) => (n['is_read'] == 1 || n['is_read'] == true)).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: DailyColors.cream,
      appBar: AppBar(
        backgroundColor: DailyColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DailyColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Communications & Alerts',
          style: TextStyle(
            color: DailyColors.charcoal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DailyColors.burgundy))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: DailyColors.burgundy, size: 36),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        OutlinedButton(onPressed: _loadNotifications, child: const Text('RETRY')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: DailyColors.burgundy,
                  onRefresh: _loadNotifications,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                    children: [
                      const Text(
                        'SUPPLIER DESK',
                        style: TextStyle(
                          color: DailyColors.burgundy,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Notifications & Broadcasts',
                        style: TextStyle(
                          color: DailyColors.charcoal,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      Row(
                        children: ['ALL', 'UNREAD', 'READ'].map((f) {
                          final isSelected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _filter = f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? DailyColors.burgundy : DailyColors.white,
                                  border: Border.all(
                                    color: isSelected ? DailyColors.burgundy : DailyColors.divider,
                                  ),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : DailyColors.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: DailyColors.white,
                            border: Border.all(color: DailyColors.divider),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.notifications_none, size: 36, color: DailyColors.gray),
                                SizedBox(height: 10),
                                Text(
                                  'No notifications found in this category.',
                                  style: TextStyle(color: DailyColors.gray, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(filtered.length, (i) {
                          final item = filtered[i];
                          final isRead = item['is_read'] == 1 || item['is_read'] == true;
                          final type = '${item['notification_type'] ?? 'GENERAL'}'.toUpperCase();
                          final dateStr = (item['created_at'] ?? '—').toString().split('T').first;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DailyColors.white,
                              border: Border.all(
                                color: isRead ? DailyColors.divider : DailyColors.burgundy.withValues(alpha: 0.5),
                                width: isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _badgeForType(type),
                                        const SizedBox(width: 8),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: DailyColors.burgundy,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 12, color: DailyColors.gray),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${item['title'] ?? 'Notification'}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: DailyColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['message'] ?? ''}',
                                  style: const TextStyle(fontSize: 13, height: 1.4, color: DailyColors.charcoal),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _markAsRead(item['notification_id'] as int),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('MARK AS READ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: DailyColors.burgundy,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _badgeForType(String type) {
    Color bg = DailyColors.tan;
    Color fg = DailyColors.burgundy;
    if (type.contains('PAYMENT')) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (type.contains('COMPLAINT') || type.contains('ISSUE')) {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(
        type,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.6),
      ),
    );
  }
}
