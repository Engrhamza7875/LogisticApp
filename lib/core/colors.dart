import 'package:flutter/material.dart';

/// SabCargo Enterprise Design System Color Palette
/// Strict Brand Rules:
/// - Orange: Primary buttons, booking actions, active indicators, selected controls & key CTAs.
/// - Navy Blue: Sidebars, navigation headers, titles & professional branding.
/// - White & Light Grey: Clean screens, forms, tables and cards.
/// - Green, Red & Amber: Reserved strictly for meaningful statuses (delivered, failed, pending).
class AppColors {
  // Brand Navy Blue (Navigation, Sidebars, App Bars, Headings)
  static const Color navy = Color(0xFF0F172A);         // Deep Slate Navy
  static const Color navyLight = Color(0xFF1E293B);    // Card / Section Navy
  static const Color navyDark = Color(0xFF0A0F1D);     // Darkest branding
  static const Color primary = navy;                   // Primary Brand Color
  static const Color primaryLight = navyLight;         // Navy section fill

  // Cargo Orange (Primary CTAs, Buttons, Booking, Active Indicators)
  static const Color orange = Color(0xFFFF6B00);       // Pure Cargo Orange
  static const Color orangeDark = Color(0xFFEA580C);   // Hover / Pressed state
  static const Color orangeLight = Color(0xFFFFF7ED);  // 50-tint for badges & pill selection
  static const Color orangeBorder = Color(0xFFFFEDD5); // Pill borders
  static const Color accent = orange;                  // Canonical Accent

  // Clean Neutral Backgrounds & Surfaces (White & Light Grey)
  static const Color background = Color(0xFFF8FAFC);   // Light neutral canvas
  static const Color surface = Color(0xFFFFFFFF);      // Clean white card / form fill
  static const Color surfaceVariant = Color(0xFFF1F5F9);// Subtle grey secondary fill
  static const Color border = Color(0xFFE2E8F0);       // Clean hairline borders
  static const Color divider = Color(0xFFE2E8F0);

  // Status Indicators (Strictly Reserved for Business Meaning)
  static const Color success = Color(0xFF10B981);      // Delivered / Completed (Emerald)
  static const Color successLight = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);        // Failed / Cancelled / Error (Red)
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);      // Pending / Booked / On Hold (Amber)
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF2563EB);         // In Transit / Dispatched (Blue)
  static const Color infoLight = Color(0xFFEFF6FF);

  // Typography Tokens
  static const Color textPrimary = Color(0xFF0F172A);  // Primary Headings & Body
  static const Color textSecondary = Color(0xFF475569);// Secondary descriptions
  static const Color textMuted = Color(0xFF94A3B8);    // Placeholders & hints
  static const Color textOnDark = Color(0xFFFFFFFF);   // White on Navy / Dark
  static const Color textOnOrange = Color(0xFFFFFFFF); // White on Orange CTAs

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get orangeGlow => [
        BoxShadow(
          color: orange.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];
}
