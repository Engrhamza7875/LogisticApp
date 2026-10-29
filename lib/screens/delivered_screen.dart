import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../models/shipment.dart';

class DeliveredScreen extends StatelessWidget {
  final Shipment shipment;
  const DeliveredScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Success animation
                    ZoomIn(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 28),

                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: const Text(
                        'Package Delivered!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'Your shipment has been successfully\ndelivered to the destination.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Delivery details card
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _detailRow('Item', shipment.itemName),
                            const Divider(color: AppColors.divider, height: 32),
                            _detailRow('Tracking #', shipment.trackingNumber),
                            const Divider(color: AppColors.divider, height: 32),
                            _detailRow('From', shipment.origin),
                            const Divider(color: AppColors.divider, height: 32),
                            _detailRow('To', shipment.destination),
                            const Divider(color: AppColors.divider, height: 32),
                            _detailRow('Delivery Date', shipment.expectedDate),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feedback stars
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          const Text('Rate your experience',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: index < 4 ? AppColors.warning : AppColors.border,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // CTA buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 500),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Track Another Package',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 500),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Back to Details',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
