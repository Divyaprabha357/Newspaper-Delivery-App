import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import 'supplier_communication_screen.dart';
import 'supplier_design_system.dart';
import 'supplier_login_screen.dart';

class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final rawUserId = session?['user_id'];
      final userId = rawUserId is int ? rawUserId : int.tryParse('$rawUserId');
      if (userId == null) {
        throw const RoleApiException('No authenticated Supplier session is available.');
      }
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierProfile(userId);
      final profile = Map<String, dynamic>.from(response['profile'] as Map? ?? {});
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load your profile. Please try again.';
      });
    }
  }

  String _value(String key) {
    final value = _profile?[key];
    if (value == null || value.toString().trim().isEmpty) return supplierMissingValue;
    return value.toString();
  }

  String get _displayName {
    final business = _profile?['supplier_name'] ?? _profile?['business_name'];
    if (business != null && business.toString().trim().isNotEmpty) {
      return business.toString();
    }
    return _value('name');
  }

  String get _initial {
    final name = _displayName.trim();
    return name.isEmpty || name == supplierMissingValue ? 'S' : name[0].toUpperCase();
  }

  void _showEditDialog() {
    final supplierNameCtrl = TextEditingController(text: _profile?['supplier_name']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: _profile?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: _profile?['email']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address']?.toString() ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: DailyColors.white,
          shape: const RoundedRectangleBorder(),
          title: const Text('Edit Supplier Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: supplierNameCtrl,
                  decoration: const InputDecoration(labelText: 'Distributor / Supplier Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Person Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Business Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Business Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: DailyColors.gray)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final suppName = supplierNameCtrl.text.trim();
                      final contactName = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final address = addressCtrl.text.trim();

                      if (suppName.isEmpty || contactName.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Supplier name, contact name, and phone are required.')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final session = await RoleSessionService.getSupplier();
                        final rawUserId = session?['user_id'];
                        final userId = rawUserId is int ? rawUserId : int.tryParse('$rawUserId');
                        final rawSupplierId = session?['supplier_id'];
                        final supplierId = rawSupplierId is int ? rawSupplierId : int.tryParse('$rawSupplierId');

                        if (userId == null) throw const RoleApiException('Session expired.');

                        final res = await RoleApiService(
                          authToken: session?['session_token']?.toString(),
                        ).updateSupplierProfile(
                          userId: userId,
                          supplierId: supplierId,
                          name: contactName,
                          email: email.isNotEmpty ? email : null,
                          phone: phone,
                          supplierName: suppName,
                          contactNumber: phone,
                          address: address.isNotEmpty ? address : null,
                        );

                        // Update local session
                        final current = Map<String, dynamic>.from(session ?? {});
                        current['name'] = contactName;
                        current['email'] = email;
                        current['phone'] = phone;
                        await RoleSessionService.saveSupplier(current);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] as String? ?? 'Profile updated successfully.')),
                        );
                        _loadProfile();
                      } on RoleApiException catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (_) {
                        setDialogState(() => isSaving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update profile. Please try again.')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: DailyColors.burgundy,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
              ),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DailyColors.white,
        shape: const RoundedRectangleBorder(),
        title: const Text('DAILY Supplier Desk Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operational Hours: 05:00 AM — 08:00 PM Daily', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 10),
            Text('Supplier Escalations Hotline:', style: TextStyle(color: DailyColors.gray, fontSize: 13)),
            Text('+91 1800-202-3344 (Toll-Free)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: DailyColors.burgundy)),
            SizedBox(height: 10),
            Text('Distribution Desk Email:', style: TextStyle(color: DailyColors.gray, fontSize: 13)),
            Text('distribution@daily.press', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 14),
            Text('For route reassignments, inventory reconciliation, and billing disputes, report via the Requests & Complaints workspace.', style: TextStyle(fontSize: 12, color: DailyColors.gray, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DailyColors.burgundy),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, color: DailyColors.gray, size: 34),
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: DailyColors.gray)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadProfile, child: const Text('TRY AGAIN')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACCOUNT', style: _eyebrow),
                    const SizedBox(height: 7),
                    const Text('Supplier Profile', style: _heading),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('EDIT PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DailyColors.burgundy,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _identity(),
          const SizedBox(height: 18),
          _section(
            'Business Information',
            _businessInformation(),
          ),
          const SizedBox(height: 14),
          _section('Service Areas', _serviceAreas()),
          const SizedBox(height: 14),
          _section('Account & Communications', _settings()),
          const SizedBox(height: 14),
          _section('Support & Information', _support()),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await RoleSessionService.clearSupplier();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SupplierLoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('LOG OUT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DailyColors.burgundy,
              side: const BorderSide(color: DailyColors.burgundy),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Supplier ID: ${_value('supplier_id')}', style: const TextStyle(fontSize: 16, color: DailyColors.gray)),
              const SizedBox(height: 3),
              Text(_value('email'), style: const TextStyle(fontSize: 16, color: DailyColors.gray)),
              const SizedBox(height: 3),
              Text(_value('phone'), style: const TextStyle(fontSize: 16, color: DailyColors.gray)),
            ],
          );
          final badge = _statusBadge(_value('supplier_status'));
          final content = constraints.maxWidth < 560
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [details, const SizedBox(height: 12), badge])
              : Row(children: [Expanded(child: details), badge]);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: DailyColors.tan,
                child: Text(_initial, style: const TextStyle(fontSize: 30, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 18),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _businessInformation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fields = [
          _InfoItem('Business / Distributor Name', _value('supplier_name')),
          _InfoItem('Supplier ID', _value('supplier_id')),
          _InfoItem('Registered Contact Person', _value('name')),
          _InfoItem('Business Email', _value('email')),
          _InfoItem('Business Phone', _value('phone')),
          _InfoItem('Business Address', _value('address')),
          _InfoItem('Account Registration Date', _value('created_at').split('T').first),
          _InfoItem('Account Status', _value('supplier_status')),
        ];
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 2 ? 3.4 : 4.2,
          crossAxisSpacing: 22,
          mainAxisSpacing: 8,
          children: fields,
        );
      },
    );
  }

  Widget _serviceAreas() {
    final areas = (_profile?['service_areas'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (areas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No service areas are currently associated with this account.',
          style: TextStyle(fontSize: 15, color: DailyColors.gray),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: areas.map((a) {
        final areaName = a['area_name'] ?? 'Area';
        final city = a['city'] ?? 'Mumbai';
        final pin = a['pincode'] ?? '';
        final status = (a['status'] ?? 'ACTIVE').toString().toUpperCase();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: DailyColors.cream,
            border: Border.all(color: DailyColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: DailyColors.burgundy),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$areaName, $city', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('PIN: $pin • $status', style: const TextStyle(fontSize: 11, color: DailyColors.gray)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _settings() {
    return Column(
      children: [
        _clickableRow(
          Icons.person_outline,
          'Edit Contact & Business Details',
          'Modify supplier business name, contact phone, or address.',
          _showEditDialog,
        ),
        _clickableRow(
          Icons.notifications_none,
          'Notifications & Communications Desk',
          'Review dispatches, system alerts, and customer request notices.',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierCommunicationScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _support() {
    return Column(
      children: [
        _clickableRow(
          Icons.help_outline,
          'Help & Escalations Support',
          'Contact DAILY central distribution operations desk.',
          _showHelpDialog,
        ),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: _sectionLabel),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _clickableRow(IconData icon, String title, String description, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: DailyColors.burgundy),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(description, style: const TextStyle(fontSize: 13, color: DailyColors.gray)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: DailyColors.gray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    final isActive = s == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : DailyColors.tan,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: isActive ? const Color(0xFF2E7D32) : DailyColors.charcoal,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: DailyColors.gray)),
        const SizedBox(height: 4),
        Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DailyColors.charcoal)),
        const Divider(height: 12, color: DailyColors.divider),
      ],
    );
  }
}

const _eyebrow = TextStyle(
  color: DailyColors.burgundy,
  fontSize: 15,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.7,
);

const _heading = TextStyle(
  color: DailyColors.charcoal,
  fontSize: 34,
  fontWeight: FontWeight.bold,
);

const _sectionLabel = TextStyle(
  color: DailyColors.burgundy,
  fontSize: 14,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.2,
);
