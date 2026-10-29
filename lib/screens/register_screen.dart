import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_button.dart';
import '../core/widgets/sabcargo_card.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _phone = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phone.isEmpty) {
      _snack('Please enter a valid contact phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final n = _nameController.text.trim();
      final e = _emailController.text.trim();

      await ApiService.registerStart(name: n, email: e, phone: _phone);
      if (!mounted) return;
      _snack('Verification code sent to $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: e, name: n, phone: _phone),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
        content: Text(
          m,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('DISMISS', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create SabCargo Account',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    FadeInDown(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.orangeGlow,
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: const Text(
                        'Join SabCargo Logistics',
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
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        'Register to book, track cargo and manage shipments in real time',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Registration Card
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: SabCargoCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FULL NAME',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'e.g. John Doe',
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.navy),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'EMAIL ADDRESS',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'e.g. user@example.com',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navy),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'PHONE NUMBER',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            IntlPhoneField(
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                                ),
                              ),
                              dropdownDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              initialCountryCode: 'AE',
                              onChanged: (phone) {
                                _phone = phone.completeNumber;
                              },
                            ),
                            const SizedBox(height: 24),

                            SabCargoButton(
                              text: 'Send Verification Code',
                              icon: Icons.mark_email_read_rounded,
                              isLoading: _isLoading,
                              onPressed: _register,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Link
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/pin-login'),
                            child: const Text(
                              'Sign In',
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
      ),
    );
  }
}
