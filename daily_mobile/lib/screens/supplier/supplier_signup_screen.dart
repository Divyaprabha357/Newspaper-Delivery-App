import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import '../role_selection_screen.dart';
import 'supplier_login_screen.dart';

class SupplierSignUpScreen extends StatefulWidget {
  const SupplierSignUpScreen({super.key});

  @override
  State<SupplierSignUpScreen> createState() => _SupplierSignUpScreenState();
}

class _SupplierSignUpScreenState extends State<SupplierSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _customAreaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _loading = false;
  List<Map<String, dynamic>> _availableAreas = [];
  final Set<String> _selectedAreas = {};

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final res = await RoleApiService().getAreas().catchError((_) => <String, dynamic>{});
      final areas = res['areas'];
      if (mounted && areas is List && areas.isNotEmpty) {
        setState(() {
          _availableAreas = areas
              .whereType<Map>()
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
        });
      } else if (mounted) {
        // Fallback default areas if API not reachable
        setState(() {
          _availableAreas = [
            {'area_name': 'Dadar West'},
            {'area_name': 'Dadar East'},
            {'area_name': 'Matunga'},
            {'area_name': 'Mahim'},
            {'area_name': 'Prabhadevi'},
            {'area_name': 'Bandra West'},
            {'area_name': 'Andheri West'},
          ];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableAreas = [
            {'area_name': 'Dadar West'},
            {'area_name': 'Dadar East'},
            {'area_name': 'Matunga'},
            {'area_name': 'Bandra West'},
            {'area_name': 'Andheri West'},
          ];
        });
      }
    }
  }

  Future<void> _signUp() async {
    final supplierName = _supplierNameController.text.trim();
    final contactName = _contactNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (supplierName.isEmpty) {
      _showMessage('Supplier / business name is required.');
      return;
    }
    if (contactName.isEmpty) {
      _showMessage("Contact person's full name is required.");
      return;
    }
    if (email.isEmpty) {
      _showMessage('Business email address is required.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.length < 10) {
      _showMessage('Phone number must be at least 10 digits.');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Business address is required.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('Password is required.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }
    if (!_termsAccepted) {
      _showMessage('Please accept the Terms and Conditions to proceed.');
      return;
    }

    // Collect service areas
    final selectedAreaList = _selectedAreas.toList();
    final customArea = _customAreaController.text.trim();
    if (customArea.isNotEmpty && !selectedAreaList.contains(customArea)) {
      selectedAreaList.add(customArea);
    }

    setState(() => _loading = true);

    try {
      final response = await RoleApiService().registerSupplier(
        supplierName: supplierName,
        name: contactName,
        email: email,
        phone: cleanPhone,
        address: address,
        password: password,
        areaNames: selectedAreaList.isNotEmpty ? selectedAreaList : null,
      );

      if (!mounted) return;

      final message = response['message']?.toString() ??
          'Supplier account created successfully! Please sign in.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DailyColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      // Direct supplier to existing Login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SupplierLoginScreen()),
      );
    } on RoleApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create supplier account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(
                title: 'DAILY',
                onBack: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SUPPLIER NETWORK',
                            style: TextStyle(
                              color: DailyColors.burgundy,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your supplier account',
                            style: TextStyle(
                              color: DailyColors.charcoal,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Partner with DAILY to manage newspapers, dispatch lines, customer subscriptions, and delivery operations.',
                            style: TextStyle(
                              color: DailyColors.charcoal,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 26),

                          // 1. Supplier / Business Name
                          const SectionLabel('Supplier / Business Name'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _supplierNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Mumbai Daily Distributors',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2. Contact Person's Full Name
                          const SectionLabel("Contact Person's Full Name"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _contactNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3. Business Email
                          const SectionLabel('Business Email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'business@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 4. Phone Number
                          const SectionLabel('Phone Number'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '10-digit mobile or contact number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 5. Business Address
                          const SectionLabel('Business Address'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Business premises, street, locality, city',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 6. Service Areas
                          const SectionLabel('Service Area or Areas'),
                          const SizedBox(height: 8),
                          const Text(
                            'Select primary distribution zones you serve:',
                            style: TextStyle(
                              fontSize: 13,
                              color: DailyColors.gray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_availableAreas.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableAreas.map((area) {
                                final name = area['area_name']?.toString() ?? '';
                                final isSelected = _selectedAreas.contains(name);
                                return FilterChip(
                                  label: Text(name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedAreas.add(name);
                                      } else {
                                        _selectedAreas.remove(name);
                                      }
                                    });
                                  },
                                  selectedColor: DailyColors.burgundy.withValues(alpha: 0.18),
                                  checkmarkColor: DailyColors.burgundy,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? DailyColors.burgundy
                                        : DailyColors.charcoal,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: DailyColors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: isSelected
                                          ? DailyColors.burgundy
                                          : DailyColors.divider,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _customAreaController,
                            decoration: const InputDecoration(
                              hintText: 'Other service locality (optional)',
                              prefixIcon: Icon(Icons.add_location_alt_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 7. Password
                          const SectionLabel('Password'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Minimum 6 characters',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 8. Confirm Password
                          const SectionLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_clock_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 9. Terms and Conditions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  activeColor: DailyColors.burgundy,
                                  onChanged: (val) =>
                                      setState(() => _termsAccepted = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _termsAccepted = !_termsAccepted,
                                  ),
                                  child: const Text(
                                    'I agree to the DAILY Terms and Conditions, Supplier Distribution Agreement, and Privacy Policy.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: DailyColors.charcoal,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 10. Submit Button
                          PrimaryButton(
                            label: _loading
                                ? 'CREATING ACCOUNT...'
                                : 'CREATE ACCOUNT',
                            onPressed: _loading ? () {} : _signUp,
                          ),
                          const SizedBox(height: 22),

                          // 11. Footer Link: "Already have an account? Sign In"
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: DailyColors.charcoal,
                                    fontSize: 15,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SupplierLoginScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: DailyColors.burgundy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
