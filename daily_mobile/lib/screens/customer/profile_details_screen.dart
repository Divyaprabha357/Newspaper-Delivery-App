import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  bool _isEditing = false;

  final _nameController = TextEditingController(
    text: 'Divyaprabha Seenivasagam',
  );
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _emailController = TextEditingController(text: 'divyaprabha@gmail.com');
  final _addressController = TextEditingController(
    text: '12 MG Road, Mumbai, 400001',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
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
                      label: 'SAVE PROFILE',
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _showSaved(context);
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
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          suffixIcon: _isEditing
              ? const Icon(Icons.edit_outlined, size: 18)
              : null,
        ),
      ),
    );
  }

  void _showSaved(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile changes saved.')));
  }
}
