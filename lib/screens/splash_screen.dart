import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      if (role == 'SuperAdmin') {
        Navigator.pushReplacementNamed(context, '/superadmin');
      } else if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    final hasPin = await AuthService.hasPin();
    if (!mounted) return;
    if (hasPin) {
      Navigator.pushReplacementNamed(context, '/pin-login');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 700),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.orangeGlow,
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_shipping_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 700),
              child: const Text(
                'SABCARGO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 700),
              child: const Text(
                'ENTERPRISE LOGISTICS ECOSYSTEM',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
