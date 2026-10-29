import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_button.dart';
import '../core/widgets/sabcargo_card.dart';
import '../services/auth_service.dart';
import '../services/local_registration_store.dart';
import 'register_screen.dart';
import 'reset_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/screens/super_admin_dashboard.dart';
import '../admin/screens/office_admin_dashboard.dart';
import 'driver_dashboard.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;
  bool _isLoading = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showLoginError('Security PIN must be at least 4-6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      // Mock Bypasses for Development Testing
      if (pin == '888888') {
        if (!kIsWeb) {
          _showLoginError('Super Admin web portal is restricted to Desktop & Web browsers.');
          return;
        }
        await _mockSession('SuperAdmin', 'superadmin@sabcargo.dev');
        _navigateToAdmin(isSuper: true);
        return;
      } else if (pin == '999999') {
        await _mockSession('Admin', 'officeadmin@sabcargo.dev');
        _navigateToAdmin(isSuper: false);
        return;
      } else if (pin == '777777') {
        await _mockSession('Driver', 'driver@sabcargo.dev');
        _navigateToDriver();
        return;
      }

      // Check local registration records to attach email if cached
      final regs = await LocalRegistrationStore.getAllRegistrations();
      for (var r in regs) {
        if (r['pin'] == pin && r['email'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('sabcargo_user_email', r['email']!);
          if (r['name'] != null) await prefs.setString('sabcargo_user_name', r['name']!);
          break;
        }
      }

      final isValid = await AuthService.verifyPin(pin);
      if (!mounted) return;

      if (isValid) {
        final role = await AuthService.getUserRole();
        if (role == 'SuperAdmin' && !kIsWeb) {
          await AuthService.logout();
          _showLoginError('Super Admin portal is optimized for Web and Desktop.');
          return;
        }

        if (role == 'SuperAdmin') {
          _navigateToAdmin(isSuper: true);
        } else if (role == 'Admin') {
          _navigateToAdmin(isSuper: false);
        } else if (role == 'Driver') {
          _navigateToDriver();
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showLoginError('Invalid Security PIN. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showLoginError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _mockSession(String role, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sabcargo_logged_in', true);
    await prefs.setString('sabcargo_user_role', role);
    await prefs.setString('sabcargo_user_email', email);
    await prefs.setString('sabcargo_auth_token', 'mock_${role.toLowerCase()}_token');
  }

  void _navigateToAdmin({required bool isSuper}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isSuper ? const SuperAdminDashboard() : const OfficeAdminDashboard(),
      ),
    );
  }

  void _navigateToDriver() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DriverDashboard()),
    );
  }

  void _showLoginError(String message) {
    setState(() {
      _isLoading = false;
      _isError = true;
    });
    _shakeController.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Navy Header Card
                  FadeInDown(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.orangeGlow,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 150),
                    child: const Text(
                      'Welcome to SabCargo',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeInDown(
                    delay: const Duration(milliseconds: 250),
                    child: const Text(
                      'Enter your 6-digit permanent PIN to access your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 350),
                    child: AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: SabCargoCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SECURITY ACCESS PIN',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              obscuringCharacter: '●',
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 16,
                                color: AppColors.navy,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '••••••',
                                hintStyle: const TextStyle(letterSpacing: 16, color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.dialpad_rounded, color: AppColors.navy),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _isError ? AppColors.error : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 20),
                            SabCargoButton(
                              text: 'Unlock & Sign In',
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ResetPinScreen()),
                                ),
                                child: const Text(
                                  'Forgot PIN? Reset via Email',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fast Mock Bypasses for Dev / Reviewers
                  FadeInUp(
                    delay: const Duration(milliseconds: 450),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: AppColors.orange),
                              SizedBox(width: 6),
                              Text(
                                'QUICK ROLE ACCESS (DEV)',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _devChip('SuperAdmin (888888)', () {
                                _pinController.text = '888888';
                                _handleLogin();
                              }),
                              _devChip('Office Admin (999999)', () {
                                _pinController.text = '999999';
                                _handleLogin();
                              }),
                              _devChip('Driver (777777)', () {
                                _pinController.text = '777777';
                                _handleLogin();
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Registration Link
                  FadeInUp(
                    delay: const Duration(milliseconds: 550),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
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
    );
  }

  Widget _devChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
