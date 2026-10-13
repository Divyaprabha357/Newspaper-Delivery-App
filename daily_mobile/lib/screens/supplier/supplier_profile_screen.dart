import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import 'supplier_design_system.dart';

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
    return name.isEmpty || name == supplierMissingValue ? supplierMissingValue : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Text('Loading supplier profile...', style: TextStyle(color: DailyColors.gray)),
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
          const Text('ACCOUNT', style: _eyebrow),
          const SizedBox(height: 7),
          const Text('Supplier Profile', style: _heading),
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
          _section('Account Settings', _settings()),
          const SizedBox(height: 14),
          _section('Support & Information', _support()),
          const SizedBox(height: 12),
          const Text(
            'Profile editing, notification preferences, service-area management and Supplier profile retrieval are not currently supported by the verified backend.',
            style: TextStyle(fontSize: 15, color: DailyColors.gray),
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
              Text('Supplier ID: ${_value('supplier_id')}', style: const TextStyle(fontSize: 18, color: DailyColors.gray)),
              const SizedBox(height: 3),
              Text(_value('email'), style: const TextStyle(fontSize: 18, color: DailyColors.gray)),
              const SizedBox(height: 3),
              Text(_value('phone'), style: const TextStyle(fontSize: 18, color: DailyColors.gray)),
            ],
          );
          final badge = _statusBadge(_value('status'));
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
          _InfoItem('Account Registration Date', _value('created_at')),
          _InfoItem('Account Status', _value('status')),
        ];
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 2 ? 4.7 : 5.2,
          crossAxisSpacing: 22,
          mainAxisSpacing: 8,
          children: fields,
        );
      },
    );
  }

  Widget _serviceAreas() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'No service areas are currently associated with this account.',
        style: TextStyle(fontSize: 18, color: DailyColors.gray),
      ),
    );
  }

  Widget _settings() {
    return Column(
      children: [
        _unsupportedRow(Icons.person_outline, 'Personal Information', 'Registered contact information is viewable above.'),
        _unsupportedRow(Icons.notifications_none, 'Notification Preferences', 'Notification settings are not available yet.'),
        _unsupportedRow(Icons.lock_outline, 'Security', 'Password and security settings are not available yet.'),
        _unsupportedRow(Icons.map_outlined, 'Service Areas', 'Service-area management is not available yet.'),
      ],
    );
  }

  Widget _support() {
    return Column(
      children: [
        _unsupportedRow(Icons.help_outline, 'Help & Support', 'This section is not available yet.'),
        _unsupportedRow(Icons.contact_support_outlined, 'Contact Us', 'This section is not available yet.'),
        _unsupportedRow(Icons.privacy_tip_outlined, 'Privacy Policy', 'This section is not available yet.'),
        _unsupportedRow(Icons.description_outlined, 'Terms & Conditions', 'This section is not available yet.'),
        _unsupportedRow(Icons.info_outline, 'About DAILY', 'This section is not available yet.'),
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

  Widget _unsupportedRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DailyColors.burgundy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(fontSize: 16, color: DailyColors.gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status == supplierMissingValue ? DailyColors.tan : DailyColors.burgundy,
        border: Border.all(color: DailyColors.divider),
      ),
      child: Text(
        status == supplierMissingValue ? 'STATUS UNAVAILABLE' : status.toUpperCase(),
        style: TextStyle(
          color: status == supplierMissingValue ? DailyColors.charcoal : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
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
        Text(label, style: const TextStyle(fontSize: 15, color: DailyColors.gray)),
        const SizedBox(height: 4),
        Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, color: DailyColors.charcoal)),
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
  fontSize: 40,
  fontWeight: FontWeight.bold,
);

const _sectionLabel = TextStyle(
  color: DailyColors.burgundy,
  fontSize: 16,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.2,
);
