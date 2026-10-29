import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_button.dart';
import '../core/widgets/sabcargo_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int _secondsLeft = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.verifyOtp(email: widget.email, otp: otp);

      // Save user session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sabcargo_user_email', widget.email);
      await prefs.setString('sabcargo_user_name', widget.name);
      await prefs.setString('sabcargo_user_phone', widget.phone);
      await prefs.setString('sabcargo_pin', otp); // Permanent access PIN
      await prefs.setBool('sabcargo_logged_in', true);

      // Also persist to backend
      try {
        await ApiService.setPin(email: widget.email, pin: otp);
      } catch (_) {}

      if (!mounted) return;

      // Show success modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registration Complete!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navy),
              ),
              const SizedBox(height: 10),
              Text(
                'Your permanent security access PIN is: $otp\n\nPlease keep it safe for all future sign-ins.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            Center(
              child: SabCargoButton(
                text: 'Proceed to Dashboard',
                isFullWidth: false,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.registerStart(name: widget.name, email: widget.email, phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fresh verification code has been dispatched'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                      child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: const Text(
                      'Check Your Inbox',
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
                    child: Text(
                      'We sent a 6-digit verification code to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
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
                            'ENTER 6-DIGIT CODE',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 14,
                              color: AppColors.navy,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              hintStyle: const TextStyle(letterSpacing: 14, color: AppColors.textMuted),
                              errorText: _error,
                            ),
                            onSubmitted: (_) => _verify(),
                          ),
                          const SizedBox(height: 20),

                          SabCargoButton(
                            text: 'Verify & Establish PIN',
                            icon: Icons.verified_user_rounded,
                            isLoading: _isLoading,
                            onPressed: _verify,
                          ),
                          const SizedBox(height: 16),

                          Center(
                            child: _secondsLeft > 0
                                ? Text(
                                    'Code expires in ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _isLoading ? null : _resendOtp,
                                    child: const Text(
                                      'Resend Verification Code',
                                      style: TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w800,
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
