import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Navy Hero Branding Banner
                      Container(
                        height: size.height * 0.46,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: AppColors.orangeGlow,
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              child: const Text(
                                'SABCARGO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Global Cargo & Freight Network',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeInLeft(
                                    delay: const Duration(milliseconds: 200),
                                    child: const Text(
                                      'Ship Anything,\nAnywhere.',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FadeInLeft(
                                    delay: const Duration(milliseconds: 350),
                                    child: const Text(
                                      'Fast, reliable freight operations across air, ocean, and land. Real-time chronological tracking at your fingertips.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Orange Primary CTA
                              FadeInUp(
                                delay: const Duration(milliseconds: 450),
                                child: Column(
                                  children: [
                                    SabCargoButton(
                                      text: 'Get Started',
                                      icon: Icons.arrow_forward_rounded,
                                      onPressed: () => Navigator.pushReplacementNamed(
                                        context,
                                        '/pin-login',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () => Navigator.pushNamed(context, '/register'),
                                      child: const Text(
                                        'New to SabCargo? Create Account',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dev settings shortcut
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
              tooltip: 'Developer Settings',
              onPressed: () => Navigator.pushNamed(context, '/dev-settings'),
            ),
          ),
        ],
      ),
    );
  }
}
