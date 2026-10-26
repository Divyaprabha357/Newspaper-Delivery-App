import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_widgets.dart';

enum ProfileSubScreen { personal, vehicle, emergency, availability, notifications, help }

class PartnerProfileScreen extends StatefulWidget {
  final ValueChanged<ProfileSubScreen> onOpen;
  final VoidCallback onLogout;
  const PartnerProfileScreen({super.key, required this.onOpen, required this.onLogout});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  bool loading = true;
  Object? error;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await RoleSessionService.getPartner();
      final id = int.tryParse('${session?['user_id']}');
      if (id == null) throw const RoleApiException('Your delivery partner session has expired.');
      final response = await RoleApiService(authToken: session?['session_token']?.toString()).partnerProfile(id);
      if (mounted) {
        setState(() {
          profile = Map<String, dynamic>.from(response['profile'] as Map);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return partnerError(error!, _load);
    final p = profile!;
    final links = [
      ('Personal Information', ProfileSubScreen.personal),
      ('Vehicle', ProfileSubScreen.vehicle),
      ('Emergency Contact', ProfileSubScreen.emergency),
      ('Leave & Availability', ProfileSubScreen.availability),
      ('Notifications', ProfileSubScreen.notifications),
      ('Help & Support', ProfileSubScreen.help),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartnerTop('${p['name'] ?? 'Profile'}', subtitle: 'Your delivery partner account'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: DailyColors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DailyColors.burgundy,
                    child: Text(
                      '${p['name'] ?? '?'}'.isEmpty ? '?' : '${p['name']}'.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p['name'] ?? '—'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('${p['partner_code'] ?? '—'}  •  ${p['partner_status'] ?? '—'}', style: const TextStyle(color: DailyColors.burgundy, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const PartnerSection('WORK'),
          _info('Shift', '${p['shift_start'] ?? '—'} — ${p['shift_end'] ?? '—'}'),
          _info('Status', '${p['partner_status'] ?? '—'}'),
          const PartnerSection('VEHICLE'),
          _info('Vehicle', '${p['vehicle_type'] ?? '—'}'),
          _info('Registration', '${p['registration_number'] ?? '—'}'),
          const PartnerSection('ACCOUNT'),
          ...links.map((item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(item.$1, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpen(item.$2),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('LOG OUT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DailyColors.burgundy,
                side: const BorderSide(color: DailyColors.burgundy),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: DailyColors.gray, fontSize: 12))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );
}

class PartnerProfileSubScreen extends StatefulWidget {
  final ProfileSubScreen screen;
  final VoidCallback onBack;
  const PartnerProfileSubScreen({super.key, required this.screen, required this.onBack});

  @override
  State<PartnerProfileSubScreen> createState() => _PartnerProfileSubScreenState();
}

class _PartnerProfileSubScreenState extends State<PartnerProfileSubScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final emergency = TextEditingController();
  final registration = TextEditingController();
  String vehicleType = '—';
  bool available = false;
  bool loading = true;
  bool saving = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await RoleSessionService.getPartner();
      final id = int.tryParse('${session?['user_id']}');
      if (id == null) throw const RoleApiException('Your delivery partner session has expired.');
      final response = await RoleApiService(authToken: session?['session_token']?.toString()).partnerProfile(id);
      final p = Map<String, dynamic>.from(response['profile'] as Map);
      name.text = '${p['name'] ?? ''}';
      email.text = '${p['email'] ?? ''}';
      phone.text = '${p['phone'] ?? ''}';
      emergency.text = '${p['emergency_contact'] ?? ''}';
      registration.text = '${p['registration_number'] ?? ''}';
      vehicleType = '${p['vehicle_type'] ?? '—'}';
      available = '${p['partner_status']}'.toUpperCase() == 'AVAILABLE';
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e; loading = false; });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => saving = true);
    try {
      final session = await RoleSessionService.getPartner();
      final userId = int.tryParse('${session?['user_id']}');
      final partnerId = int.tryParse('${session?['partner_id']}');
      if (userId == null) throw const RoleApiException('Your session has expired. Please sign in again.');

      final api = RoleApiService(authToken: session?['session_token']?.toString());
      Map<String, dynamic> res;

      switch (widget.screen) {
        case ProfileSubScreen.personal:
          final n = name.text.trim();
          final e = email.text.trim();
          final p = phone.text.trim();
          if (n.isEmpty || e.isEmpty || p.isEmpty) {
            throw const RoleApiException('Name, email, and phone number are required.');
          }
          res = await api.updatePartnerProfile(
            userId: userId,
            partnerId: partnerId,
            name: n,
            email: e,
            phone: p,
          );
          final updated = Map<String, dynamic>.from(session ?? {});
          updated['name'] = n;
          updated['email'] = e;
          updated['phone'] = p;
          await RoleSessionService.savePartner(updated);
          break;

        case ProfileSubScreen.vehicle:
          final reg = registration.text.trim();
          res = await api.updatePartnerProfile(
            userId: userId,
            partnerId: partnerId,
            registrationNumber: reg.isNotEmpty ? reg : null,
          );
          break;

        case ProfileSubScreen.emergency:
          final emg = emergency.text.trim();
          res = await api.updatePartnerProfile(
            userId: userId,
            partnerId: partnerId,
            emergencyContact: emg.isNotEmpty ? emg : null,
          );
          break;

        case ProfileSubScreen.availability:
          res = await api.updatePartnerProfile(
            userId: userId,
            partnerId: partnerId,
            status: available ? 'AVAILABLE' : 'OFF_DUTY',
          );
          break;

        default:
          res = {'message': 'Settings updated successfully.'};
      }

      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Changes saved successfully.')),
      );
      widget.onBack();
    } on RoleApiException catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update changes. Please check your connection.')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in [name, email, phone, emergency, registration]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = {
      ProfileSubScreen.personal: 'Personal Information',
      ProfileSubScreen.vehicle: 'Vehicle',
      ProfileSubScreen.emergency: 'Emergency Contact',
      ProfileSubScreen.availability: 'Leave & Availability',
      ProfileSubScreen.notifications: 'Notifications',
      ProfileSubScreen.help: 'Help & Support',
    };
    return PartnerPage(
      title: titles[widget.screen]!,
      onBack: widget.onBack,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? partnerError(error!, _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                  child: _content(),
                ),
    );
  }

  Widget _content() {
    switch (widget.screen) {
      case ProfileSubScreen.personal:
        return _form([
          PartnerField(label: 'Full Name', hint: '', controller: name, icon: Icons.person_outline),
          const SizedBox(height: 15),
          PartnerField(label: 'Email', hint: '', controller: email, icon: Icons.email_outlined),
          const SizedBox(height: 15),
          PartnerField(label: 'Phone Number', hint: '', controller: phone, icon: Icons.phone_outlined),
        ]);
      case ProfileSubScreen.vehicle:
        return _form([
          InputDecorator(decoration: const InputDecoration(labelText: 'Vehicle Type'), child: Text(vehicleType)),
          const SizedBox(height: 15),
          PartnerField(label: 'Registration Number', hint: '', controller: registration, icon: Icons.directions_bike_outlined),
        ]);
      case ProfileSubScreen.emergency:
        return _form([
          PartnerField(label: 'Contact Name', hint: '', controller: emergency, icon: Icons.person_outline),
          const SizedBox(height: 15),
          PartnerField(label: 'Phone Number', hint: '', controller: phone, icon: Icons.phone_outlined),
        ]);
      case ProfileSubScreen.availability:
        return _form([
          const Text('CURRENT STATUS'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: available,
            activeThumbColor: DailyColors.burgundy,
            onChanged: (v) => setState(() => available = v),
            title: Text(available ? 'Available' : 'Unavailable'),
          ),
          const InputDecorator(decoration: InputDecoration(labelText: 'Shift Start'), child: Text('06:00 AM')),
          const SizedBox(height: 15),
          const InputDecorator(decoration: InputDecoration(labelText: 'Shift End'), child: Text('11:00 AM')),
        ]);
      case ProfileSubScreen.notifications:
        return Column(
          children: ['Delivery updates', 'Route updates', 'Payment updates', 'Issue updates', 'System notifications']
              .map((item) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: true,
                    activeThumbColor: DailyColors.burgundy,
                    onChanged: (_) {},
                    title: Text(item),
                  ))
              .toList(),
        );
      case ProfileSubScreen.help:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 18),
            Text('How do I start my route?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Open Today's Route from your dashboard and select START ROUTE.", style: TextStyle(color: DailyColors.gray, height: 1.5)),
            SizedBox(height: 20),
            Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Support is available for route, delivery and account issues.', style: TextStyle(color: DailyColors.gray)),
          ],
        );
    }
  }

  Widget _form(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          const SizedBox(height: 26),
          PrimaryButton(
            label: saving ? 'SAVING...' : 'SAVE CHANGES',
            onPressed: () {
              if (!saving) _saveChanges();
            },
          ),
        ],
      );
}
