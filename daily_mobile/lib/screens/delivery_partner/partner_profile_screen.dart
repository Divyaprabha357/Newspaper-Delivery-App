import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_widgets.dart';

enum ProfileSubScreen { personal, vehicle, emergency, availability, notifications, help }

class PartnerProfileScreen extends StatelessWidget {
  final ValueChanged<ProfileSubScreen> onOpen;
  final VoidCallback onLogout;
  const PartnerProfileScreen({super.key, required this.onOpen, required this.onLogout});

  @override
  Widget build(BuildContext context) {
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
          const PartnerTop('Profile', subtitle: 'Your delivery partner account'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: DailyColors.white,
              child: const Row(children: [
                CircleAvatar(radius: 28, backgroundColor: DailyColors.burgundy, child: Text('R', style: TextStyle(color: Colors.white, fontSize: 24))),
                SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Rahul Patil', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('DP001  •  Available', style: TextStyle(color: DailyColors.burgundy, fontSize: 11)),
                ]),
              ]),
            ),
          ),
          const PartnerSection('WORK'),
          _info('Shift', '06:00 AM — 11:00 AM'),
          _info('Status', 'Available'),
          const PartnerSection('VEHICLE'),
          _info('Vehicle', 'Motorcycle'),
          _info('Registration', 'MH 01 AB 1234'),
          const PartnerSection('ACCOUNT'),
          ...links.map((item) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), title: Text(item.$1, style: const TextStyle(fontSize: 14)), trailing: const Icon(Icons.chevron_right), onTap: () => onOpen(item.$2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
            child: OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout), label: const Text('LOG OUT'), style: OutlinedButton.styleFrom(foregroundColor: DailyColors.burgundy, side: const BorderSide(color: DailyColors.burgundy), minimumSize: const Size.fromHeight(48))),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: DailyColors.gray, fontSize: 12))), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]));
}

class PartnerProfileSubScreen extends StatefulWidget {
  final ProfileSubScreen screen;
  final VoidCallback onBack;
  const PartnerProfileSubScreen({super.key, required this.screen, required this.onBack});

  @override
  State<PartnerProfileSubScreen> createState() => _PartnerProfileSubScreenState();
}

class _PartnerProfileSubScreenState extends State<PartnerProfileSubScreen> {
  final name = TextEditingController(text: 'Rahul Patil');
  final email = TextEditingController(text: 'rahul@daily.com');
  final phone = TextEditingController(text: '9876543212');
  final emergency = TextEditingController(text: 'Meera Patil');
  final registration = TextEditingController(text: 'MH 01 AB 1234');
  bool available = true;

  @override
  void dispose() {
    for (final c in [name, email, phone, emergency, registration]) c.dispose();
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
    return PartnerPage(title: titles[widget.screen]!, onBack: widget.onBack, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 30), child: _content()));
  }

  Widget _content() {
    switch (widget.screen) {
      case ProfileSubScreen.personal:
        return _form([PartnerField(label: 'Full Name', hint: '', controller: name, icon: Icons.person_outline), const SizedBox(height: 15), PartnerField(label: 'Email', hint: '', controller: email, icon: Icons.email_outlined), const SizedBox(height: 15), PartnerField(label: 'Phone Number', hint: '', controller: phone, icon: Icons.phone_outlined)]);
      case ProfileSubScreen.vehicle:
        return _form([DropdownButtonFormField(initialValue: 'Motorcycle', decoration: const InputDecoration(labelText: 'Vehicle Type'), items: ['Motorcycle', 'Scooter', 'Bicycle', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (_) {}), const SizedBox(height: 15), PartnerField(label: 'Registration Number', hint: '', controller: registration, icon: Icons.directions_bike_outlined)]);
      case ProfileSubScreen.emergency:
        return _form([PartnerField(label: 'Contact Name', hint: '', controller: emergency, icon: Icons.person_outline), const SizedBox(height: 15), PartnerField(label: 'Relationship', hint: 'e.g. Parent', controller: TextEditingController(text: 'Spouse'), icon: Icons.people_outline), const SizedBox(height: 15), PartnerField(label: 'Phone Number', hint: '', controller: phone, icon: Icons.phone_outlined)]);
      case ProfileSubScreen.availability:
        return _form([const Text('CURRENT STATUS'), SwitchListTile(contentPadding: EdgeInsets.zero, value: available, activeColor: DailyColors.burgundy, onChanged: (v) => setState(() => available = v), title: Text(available ? 'Available' : 'On Leave')), const InputDecorator(decoration: InputDecoration(labelText: 'Shift Start'), child: Text('06:00 AM')), const SizedBox(height: 15), const InputDecorator(decoration: InputDecoration(labelText: 'Shift End'), child: Text('11:00 AM'))]);
      case ProfileSubScreen.notifications:
        return Column(children: ['Delivery updates', 'Route updates', 'Payment updates', 'Issue updates', 'System notifications'].map((item) => SwitchListTile(contentPadding: EdgeInsets.zero, value: true, activeColor: DailyColors.burgundy, onChanged: (_) {}, title: Text(item))).toList());
      case ProfileSubScreen.help:
        return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 18), Text('How do I start my route?', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Open Today’s Route from your dashboard and select START ROUTE.', style: TextStyle(color: DailyColors.gray, height: 1.5)), SizedBox(height: 20), Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 8), Text('Support is available for route, delivery and account issues.', style: TextStyle(color: DailyColors.gray))]);
    }
  }

  Widget _form(List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...children, const SizedBox(height: 26), PrimaryButton(label: 'SAVE CHANGES', onPressed: widget.onBack)]);
}
