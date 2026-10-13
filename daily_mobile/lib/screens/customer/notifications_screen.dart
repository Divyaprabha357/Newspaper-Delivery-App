import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  String? error;
  int? customerId;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    customerId = await SessionService.getCustomerId();
    if (customerId == null) {
      if (mounted) setState(() { loading = false; error = 'Your session has expired.'; });
      return;
    }
    try {
      final response = await CustomerApiService().notifications(customerId!);
      if (mounted) setState(() { notifications = List<dynamic>.from(response['notifications'] as List? ?? []); loading = false; });
    } on CustomerApiException catch (e) {
      if (mounted) setState(() { loading = false; error = e.message; });
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == 1 || item['is_read'] == true || customerId == null) return;
    try {
      await CustomerApiService().markNotificationRead(customerId!, item['notification_id'] as int);
      if (mounted) setState(() => item['is_read'] = 1);
    } on CustomerApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(22, 15, 22, 8), child: DailyHeader(title: 'Notifications', onBack: () => Navigator.pop(context))),
        Expanded(child: loading
            ? const Center(child: CircularProgressIndicator(color: DailyColors.burgundy))
            : error != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: () { setState(() { loading = true; error = null; }); _load(); }, child: const Text('TRY AGAIN'))]))
                : notifications.isEmpty
                    ? const Center(child: Text('No notifications yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                        itemCount: notifications.length,
                        itemBuilder: (_, index) {
                          final item = Map<String, dynamic>.from(notifications[index] as Map);
                          final unread = item['is_read'] != 1 && item['is_read'] != true;
                          return Card(
                            color: DailyColors.white,
                            child: ListTile(
                              onTap: () => _markRead(item),
                              leading: Icon(unread ? Icons.notifications_active_outlined : Icons.notifications_none, color: unread ? DailyColors.burgundy : DailyColors.gray),
                              title: Text(item['title'] as String? ?? 'Notification', style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(item['message'] as String? ?? ''),
                              trailing: Text((item['created_at'] ?? '').toString().split('T').first, style: const TextStyle(fontSize: 12, color: DailyColors.gray)),
                            ),
                          );
                        },
                      )),
      ])),
    );
  }
}


