import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_button.dart';
import '../core/widgets/sabcargo_card.dart';
import '../services/api_service.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _statusMessage = 'Please enter a valid account email';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await ApiService.requestPinReset(email: email);
      if (!mounted) return;
      setState(() {
        _isSuccess = true;
        _statusMessage = 'A recovery access PIN has been dispatched to your email address.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _statusMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reset Security PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                      child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: const Text(
                      'Account Recovery',
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
                      'Enter your verified registered email to receive your security PIN reset',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 28),

                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: SabCargoCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACCOUNT EMAIL',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'e.g. user@example.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.navy),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_statusMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSuccess ? AppColors.successLight : AppColors.errorLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isSuccess ? AppColors.success : AppColors.error,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                    color: _isSuccess ? AppColors.success : AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusMessage!,
                                      style: TextStyle(
                                        color: _isSuccess ? AppColors.success : AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          SabCargoButton(
                            text: 'Transmit Recovery Instructions',
                            icon: Icons.send_rounded,
                            isLoading: _isLoading,
                            onPressed: _handleReset,
                          ),
                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Return to Sign In',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
