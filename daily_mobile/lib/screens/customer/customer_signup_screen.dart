import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../widgets/daily_widgets.dart';
import 'customer_dashboard_screen.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final PageController pageController = PageController();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  int currentPage = 0;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool terms = false;
  bool loading = false;

  @override
  void dispose() {
    pageController.dispose();

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  void nextPage() {
    if (currentPage == 0) {
      if (nameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty) {
        showMessage('Please complete all required information.');

        return;
      }

      setState(() {
        currentPage = 1;
      });

      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      createAccount();
    }
  }

  Future<void> createAccount() async {
    if (passwordController.text.isEmpty) {
      showMessage('Please create a password.');
      return;
    }
    if (passwordController.text.length < 6) {
      showMessage('Password must be at least 6 characters long.');
      return;
    }
    if (confirmPasswordController.text.isEmpty) {
      showMessage('Please confirm your password.');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Passwords do not match.');
      return;
    }
    if (!terms) {
      showMessage('Please accept the Terms & Conditions.');
      return;
    }

    setState(() => loading = true);
    try {
      final data = await CustomerApiService().register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        password: passwordController.text,
      );
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
      if (user['customer_id'] == null) {
        throw const CustomerApiException('Customer account could not be initialized.');
      }
      await SessionService.saveCustomer(user);
      if (!mounted) return;
      showMessage('Account created successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
      );
    } on CustomerApiException catch (error) {
      if (mounted) showMessage(error.message);
    } catch (_) {
      if (mounted) showMessage('Unable to connect to the DAILY server.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECE0),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(
                title: 'Create Account',
                onBack: () {
                  if (currentPage == 1) {
                    setState(() => currentPage = 0);
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              ),
            ),
            // PROGRESS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),

              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 4, color: const Color(0xFF7A1F1F)),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Container(
                      height: 4,
                      color: currentPage == 1
                          ? const Color(0xFF7A1F1F)
                          : const Color(0xFFC1B6A8),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),

                children: [buildPersonalInformation(), buildPasswordPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPersonalInformation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'YOUR INFORMATION',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2A28),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Tell us a little about yourself.',
            style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
          ),

          const SizedBox(height: 35),

          buildField(
            controller: nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 18),

          buildField(
            controller: phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 18),

          buildField(
            controller: emailController,
            label: 'Email',
            hint: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 18),

          buildField(
            controller: addressController,
            label: 'Delivery Address',
            hint: 'Enter your delivery address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 30),

          buildNextButton(text: 'CONTINUE', onPressed: nextPage),
        ],
      ),
    );
  }

  Widget buildPasswordPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'SET YOUR PASSWORD',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2A28),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Create a password you will use to sign in later.',
            style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
          ),

          const SizedBox(height: 40),

          buildPasswordField(
            controller: passwordController,
            label: 'Password',
            hint: 'Create your password',
            obscure: obscurePassword,

            onToggle: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          ),

          const SizedBox(height: 18),

          buildPasswordField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            obscure: obscureConfirmPassword,

            onToggle: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
          ),

          const SizedBox(height: 18),

          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: terms,
            activeColor: const Color(0xFF7A1F1F),
            onChanged: (v) => setState(() => terms = v ?? false),
            title: const Text(
              'I agree to the Terms & Conditions',
              style: TextStyle(fontSize: 12),
            ),
          ),

          const SizedBox(height: 25),

          buildNextButton(
            text: loading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
            onPressed: loading ? () {} : createAccount,
          ),
        ],
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,

      keyboardType: keyboardType,

      maxLines: maxLines,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon),

        filled: true,
        fillColor: const Color(0xFFE6D6C8),

        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
        ),

        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
        ),

        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF7A1F1F), width: 1.5),
        ),
      ),
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,

      obscureText: obscure,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: const Icon(Icons.lock_outline),

        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),

          onPressed: onToggle,
        ),

        filled: true,
        fillColor: const Color(0xFFE6D6C8),

        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
        ),

        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
        ),

        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF7A1F1F), width: 1.5),
        ),
      ),
    );
  }

  Widget buildNextButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A1F1F),
          foregroundColor: Colors.white,

          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),

        onPressed: onPressed,

        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}


