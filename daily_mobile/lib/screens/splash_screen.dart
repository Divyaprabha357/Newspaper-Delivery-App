import 'package:flutter/material.dart';

import '../services/customer_api_service.dart';
import '../services/role_api_service.dart';
import '../services/role_session_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'customer/customer_dashboard_screen.dart';
import 'delivery_partner/delivery_partner_app_screen.dart';
import 'role_selection_screen.dart';
import 'supplier/supplier_app_shell.dart';

class SplashScreen extends StatefulWidget {
  final CustomerApiService? customerApiService;
  final RoleApiService? roleApiService;

  const SplashScreen({
    super.key,
    this.customerApiService,
    this.roleApiService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    Widget targetScreen = const RoleSelectionScreen();

    try {
      final isCustomer = await SessionService.isCustomerLoggedIn();
      if (isCustomer) {
        final customerId = await SessionService.getCustomerId();
        if (customerId != null) {
          try {
            final api = widget.customerApiService ?? CustomerApiService();
            await api.profile(customerId).timeout(const Duration(seconds: 4));
            targetScreen = const CustomerDashboardScreen();
          } on CustomerApiException catch (e) {
            if (e.isUnauthorized || e.statusCode == 404) {
              await SessionService.logOut();
              targetScreen = const RoleSelectionScreen();
            } else {
              targetScreen = const CustomerDashboardScreen();
            }
          } catch (_) {
            // Network error: maintain offline capability
            targetScreen = const CustomerDashboardScreen();
          }
        } else {
          await SessionService.logOut();
          targetScreen = const RoleSelectionScreen();
        }
      } else {
        final partner = await RoleSessionService.getPartner();
        final userId = int.tryParse('${partner?['user_id']}');
        final partnerId = int.tryParse('${partner?['partner_id']}');
        final sessionToken = partner?['session_token']?.toString();
        if (partner != null && (userId != null || partnerId != null)) {
          try {
            final api = widget.roleApiService ??
                RoleApiService(authToken: sessionToken);
            await api
                .partnerProfile(userId ?? partnerId!, partnerId: partnerId)
                .timeout(const Duration(seconds: 4));
            targetScreen = const DeliveryPartnerAppScreen();
          } on RoleApiException catch (e) {
            if (e.isUnauthorized || e.statusCode == 404) {
              await RoleSessionService.clearPartner();
              targetScreen = const RoleSelectionScreen();
            } else {
              targetScreen = const DeliveryPartnerAppScreen();
            }
          } catch (_) {
            targetScreen = const DeliveryPartnerAppScreen();
          }
        } else if (partner != null) {
          await RoleSessionService.clearPartner();
          targetScreen = const RoleSelectionScreen();
        } else {
          final supplier = await RoleSessionService.getSupplier();
          final supplierId = int.tryParse(
            '${supplier?['supplier_id'] ?? supplier?['id'] ?? supplier?['user_id']}',
          );
          final supplierToken = supplier?['session_token']?.toString();
          if (supplier != null && supplierId != null) {
            try {
              final api = widget.roleApiService ??
                  RoleApiService(authToken: supplierToken);
              await api
                  .supplierProfile(supplierId)
                  .timeout(const Duration(seconds: 4));
              targetScreen = const SupplierAppShell();
            } on RoleApiException catch (e) {
              if (e.isUnauthorized || e.statusCode == 404) {
                await RoleSessionService.clearSupplier();
                targetScreen = const RoleSelectionScreen();
              } else {
                targetScreen = const SupplierAppShell();
              }
            } catch (_) {
              targetScreen = const SupplierAppShell();
            }
          } else if (supplier != null) {
            await RoleSessionService.clearSupplier();
            targetScreen = const RoleSelectionScreen();
          }
        }
      }
    } catch (_) {
      targetScreen = const RoleSelectionScreen();
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final logoWidth = (media.size.width * 0.62).clamp(180.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0D0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: logoWidth,
                  maxHeight: media.size.height * 0.35,
                ),
                child: Image.asset(
                  'assets/images/daily_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/icons/images/logo_with_name.png',
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(DailyColors.burgundy),
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}

