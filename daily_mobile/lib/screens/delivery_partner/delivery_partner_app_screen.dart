import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/mobile_role_design.dart';
import 'partner_auth_screen.dart';
import 'partner_dashboard_screen.dart';
import 'partner_delivery_screen.dart';
import 'partner_history_earnings_screen.dart';
import 'partner_models.dart';
import 'partner_profile_screen.dart';

class DeliveryPartnerAppScreen extends StatefulWidget {
  final RoleApiService? apiService;
  const DeliveryPartnerAppScreen({super.key, this.apiService});

  @override
  State<DeliveryPartnerAppScreen> createState() => _DeliveryPartnerAppScreenState();
}

enum _PartnerTab { dashboard, routes, history, earnings, profile }

class _DeliveryPartnerAppScreenState extends State<DeliveryPartnerAppScreen> {
  bool authenticated = false;
  bool loading = true;
  _PartnerTab tab = _PartnerTab.dashboard;
  RouteCustomer? selectedCustomer;
  ProfileSubScreen? profileSubScreen;
  List<RouteCustomer> customers = const [];

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await RoleSessionService.getPartner();
    if (session != null) {
      final userId = int.tryParse('${session['user_id']}');
      final partnerId = int.tryParse('${session['partner_id']}');
      if (userId == null && partnerId == null) {
        await RoleSessionService.clearPartner();
        if (mounted) setState(() { authenticated = false; loading = false; });
        return;
      }
      try {
        final api = widget.apiService ??
            RoleApiService(authToken: session['session_token']?.toString());
        await api.partnerProfile(userId ?? partnerId!, partnerId: partnerId);
        authenticated = true;
        await _loadDeliveries(session, showLoading: false);
      } on RoleApiException catch (e) {
        if (e.isUnauthorized || e.statusCode == 404) {
          await RoleSessionService.clearPartner();
          authenticated = false;
        } else {
          authenticated = true;
          await _loadDeliveries(session, showLoading: false);
        }
      } catch (_) {
        authenticated = true;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadDeliveries(
    Map<String, dynamic> session, {
    bool showLoading = true,
  }) async {
    final userId = int.tryParse('${session['user_id']}');
    final partnerId = int.tryParse('${session['partner_id']}');
    if (userId == null && partnerId == null) return;
    if (showLoading && mounted) setState(() => loading = true);
    try {
      final api = widget.apiService ??
          RoleApiService(
            authToken: session['session_token']?.toString(),
          );
      final response = await api.partnerDeliveries(userId ?? partnerId!, partnerId: partnerId);
      final rows = (response['deliveries'] as List? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final key = row['delivery_id'] != null
            ? 'd_${row['delivery_id']}'
            : 'a_${row['assignment_id']}_${row['delivery_date']}';
        grouped.putIfAbsent(key, () => []).add(row);
      }
      final loaded = grouped.entries.map((entry) {
        final first = entry.value.first;
        final deliveryId = int.tryParse('${first['delivery_id']}');
        final assignmentId = int.tryParse('${first['assignment_id']}');
        final seq = first['sequence_number']?.toString();
        final numStr = (seq != null && seq.isNotEmpty)
            ? seq
            : (deliveryId != null ? '$deliveryId' : (assignmentId != null ? '$assignmentId' : '—'));

        final newspapers = entry.value
            .map((row) => '${row['newspaper_name'] ?? ''}'.trim())
            .where((name) => name.isNotEmpty && name != '—')
            .toSet()
            .toList();

        return RouteCustomer(
          number: numStr,
          name: '${first['customer_name'] ?? 'Customer'}',
          address: '${first['address_line'] ?? '—'}',
          area: '${first['city'] ?? ''} ${first['pincode'] ?? ''}'.trim(),
          time: '${first['scheduled_time'] ?? '—'}',
          newspapers: newspapers.isEmpty ? const ['—'] : newspapers,
          instructions: '${first['delivery_instructions'] ?? '—'}',
          deliveryId: deliveryId,
          assignmentId: assignmentId,
          customerId: int.tryParse('${first['customer_id']}'),
          itemIds: entry.value
              .map((row) => int.tryParse('${row['delivery_item_id']}'))
              .whereType<int>()
              .toList(),
          deliveryStatus: first['delivery_status']?.toString(),
        );
      }).toList();
      if (mounted) setState(() => customers = loaded);
    } on RoleApiException catch (e) {
      if (e.isUnauthorized) {
        await RoleSessionService.clearPartner();
        if (mounted) {
          setState(() {
            authenticated = false;
            customers = const [];
          });
        }
      } else {
        if (mounted && showLoading) setState(() => customers = const []);
      }
    } finally {
      if (mounted && showLoading) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MobileRoleDesign.theme(context),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!authenticated) {
      return PartnerAuthScreen(
        apiService: widget.apiService,
        onSignedIn: () async {
          final session = await RoleSessionService.getPartner();
          if (!mounted) return;
          setState(() => authenticated = true);
          if (session != null) await _loadDeliveries(session);
        },
      );
    }
    if (selectedCustomer != null) {
      return PartnerCustomerScreen(
        customer: selectedCustomer!,
        onBack: () => setState(() => selectedCustomer = null),
        onStatusUpdated: () async {
          final session = await RoleSessionService.getPartner();
          if (session != null) await _loadDeliveries(session, showLoading: false);
          if (mounted) setState(() => selectedCustomer = null);
        },
      );
    }
    if (profileSubScreen != null) {
      return PartnerProfileSubScreen(screen: profileSubScreen!, onBack: () => setState(() => profileSubScreen = null));
    }
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(child: _content()),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: DailyColors.cream,
        indicatorColor: Colors.transparent,
        selectedIndex: _PartnerTab.values.indexOf(tab),
        onDestinationSelected: (index) => setState(() => tab = _PartnerTab.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Routes'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _content() {
    switch (tab) {
      case _PartnerTab.dashboard:
        return PartnerDashboardScreen(
          onStartRoute: () => setState(() => tab = _PartnerTab.routes),
          onReportIssue: () => setState(() => selectedCustomer = customers.isEmpty ? null : customers.first),
        );
      case _PartnerTab.routes:
        return PartnerRouteScreen(
          customers: customers,
          onCustomerSelected: (index) => setState(() => selectedCustomer = customers[index]),
        );
      case _PartnerTab.history:
        return const PartnerHistoryScreen();
      case _PartnerTab.earnings:
        return const PartnerEarningsScreen();
      case _PartnerTab.profile:
        return PartnerProfileScreen(
          onOpen: (screen) => setState(() => profileSubScreen = screen),
          onLogout: () async {
            await RoleSessionService.clearPartner();
            if (!mounted) return;
            setState(() {
              authenticated = false;
              selectedCustomer = null;
              profileSubScreen = null;
              customers = const [];
            });
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryPartnerAppScreen()),
              (route) => false,
            );
          },
        );
    }
  }
}
