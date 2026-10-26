import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;

  const ProfileDetailsScreen({super.key, this.customer});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final c = widget.customer ?? {};
    final addressParts = [
      c['address_line'],
      c['city'],
      c['pincode'],
    ].where((part) => part != null && '$part'.trim().isNotEmpty).map((part) => '$part'.trim());

    _nameController = TextEditingController(
      text: (c['name'] as String?) ?? '',
    );
    _phoneController = TextEditingController(
      text: (c['phone'] as String?) ?? '',
    );
    _emailController = TextEditingController(
      text: (c['email'] as String?) ?? '',
    );
    _addressController = TextEditingController(
      text: addressParts.isNotEmpty
          ? addressParts.join(', ')
          : (c['address'] as String? ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, email, and phone number cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      int? customerId = widget.customer?['customer_id'] is int
          ? widget.customer!['customer_id'] as int
          : int.tryParse('${widget.customer?['customer_id']}');

      customerId ??= await SessionService.getCustomerId();

      if (customerId == null) {
        throw const CustomerApiException('Customer session not found. Please sign in again.');
      }

      final response = await CustomerApiService().updateProfile(
        customerId,
        name: name,
        email: email,
        phone: phone,
      );

      final current = await SessionService.getCustomer() ?? {};
      final updated = Map<String, dynamic>.from(current);
      if (updated['user'] is Map) {
        final u = Map<String, dynamic>.from(updated['user'] as Map);
        u['name'] = name;
        u['email'] = email;
        u['phone'] = phone;
        updated['user'] = u;
      }
      updated['name'] = name;
      updated['email'] = email;
      updated['phone'] = phone;
      updated['customer_id'] = customerId;

      await SessionService.saveCustomer(updated);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] as String? ?? 'Profile changes saved.')),
      );
    } on CustomerApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Please check your connection.')),
      );
    }
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
                title: 'Profile',
                onBack: () => Navigator.pop(context),
                trailing: IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit profile',
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _field('Name', _nameController),
                  _field('Phone Number', _phoneController),
                  _field('Email', _emailController),
                  _field('Delivery Address', _addressController),
                  const SizedBox(height: 10),
                  if (_isEditing)
                    PrimaryButton(
                      label: _isSaving ? 'SAVING...' : 'SAVE PROFILE',
                      onPressed: () {
                        if (!_isSaving) _saveProfile();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: !_isEditing,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          suffixIcon: _isEditing
              ? const Icon(Icons.edit_outlined, size: 18)
              : null,
        ),
      ),
    );
  }
}
