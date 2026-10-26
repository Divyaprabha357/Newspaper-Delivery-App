import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'about_screen.dart';
import 'delivery_history_screen.dart';
import 'notifications_screen.dart';
import 'profile_details_screen.dart';
import 'service_request_screen.dart';
import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _query = '';
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _customer = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await SessionService.getCustomerId();
    if (id == null) {
      await SessionService.logOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen(role: 'CUSTOMER')),
        (route) => false,
      );
      return;
    }
    try {
      final response = await CustomerApiService().profile(id);
      if (mounted) setState(() { _customer = Map<String, dynamic>.from(response['user'] as Map? ?? {}); _loading = false; });
    } on CustomerApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    }
  }

  bool _matches(String text) {
    return _query.isEmpty || text.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: DailyColors.burgundy)));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!), TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadProfile(); }, child: const Text('TRY AGAIN')),
      ])));
    }
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Profile',
                trailing: SizedBox(width: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() => _query = value.trim().toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search settings...',
                      prefixIcon: Icon(Icons.search, size: 22),
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: 'Clear search',
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: DailyColors.tan,
                      child: Icon(
                        Icons.person,
                        color: DailyColors.burgundy,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _customer['name'] as String? ?? 'Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text(
                      _customer['email'] as String? ?? '—',
                      style: TextStyle(fontSize: 12, color: DailyColors.gray),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_matches('Profile') ||
                      _matches('Delivery History') ||
                      _matches('Notifications')) ...[
                    const SectionLabel('Account Details'),
                    if (_matches('Profile'))
                      _row(
                        context,
                        'Profile',
                        Icons.person_outline,
                        ProfileDetailsScreen(customer: _customer),
                      ),
                    if (_matches('Delivery History'))
                      _row(
                        context,
                        'Delivery History',
                        Icons.history,
                        const DeliveryHistoryScreen(),
                      ),
                    if (_matches('Notifications'))
                      _row(
                        context,
                        'Notifications',
                        Icons.notifications_none,
                        const NotificationsScreen(),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (_matches('Help & Support') ||
                      _matches('About Us')) ...[
                    const SectionLabel('Help & Support'),
                    if (_matches('Help & Support'))
                      _row(
                        context,
                        'Help & Support',
                        Icons.support_agent,
                        const ServiceRequestScreen(),
                      ),
                    if (_matches('About Us'))
                      _row(
                        context,
                        'About Us',
                        Icons.info_outline,
                        const AboutScreen(),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (_matches('Settings')) ...[
                    const SectionLabel('Settings'),
                    _row(
                      context,
                      'Settings',
                      Icons.settings_outlined,
                      ProfileDetailsScreen(customer: _customer),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_query.isNotEmpty &&
                      !_matches('Profile') &&
                      !_matches('Delivery History') &&
                      !_matches('Notifications') &&
                      !_matches('Help & Support') &&
                      !_matches('About Us') &&
                      !_matches('Settings'))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No settings found.',
                          style: TextStyle(color: DailyColors.gray),
                        ),
                      ),
                    ),
                  if (_query.isEmpty)
                    TextButton(
                      onPressed: () => _confirmLogout(context),
                      child: const Text(
                        'LOG OUT',
                        style: TextStyle(
                          fontSize: 12,
                          color: DailyColors.burgundy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String text, IconData icon, Widget screen) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: DailyColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: DailyColors.burgundy),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.chevron_right, size: 20, color: DailyColors.gray),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of DAILY?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SessionService.logOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen(role: 'CUSTOMER')),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DailyColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}


