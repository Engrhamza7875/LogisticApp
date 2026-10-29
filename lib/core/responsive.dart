import 'package:flutter/material.dart';

/// Layout breakpoints and helpers for phone / tablet / desktop widths.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 800;
  static const double wide = 1100;
  static const double maxAppWidth = 1200;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.2;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  bool get isTablet => screenWidth >= AppBreakpoints.tablet;

  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  bool get isWide => screenWidth >= AppBreakpoints.wide;

  /// Horizontal inset for page content (scales with width).
  double get horizontalPadding {
    if (isWide) return 32;
    if (isTablet) return 24;
    return (screenWidth * 0.05).clamp(12.0, 20.0);
  }

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: horizontalPadding);

  /// Stats / card grids: more columns on wider screens.
  int get statsCrossAxisCount {
    if (screenWidth >= AppBreakpoints.wide) return 4;
    if (screenWidth >= AppBreakpoints.desktop) return 3;
    return 2;
  }

  double get statsChildAspectRatio {
    if (screenWidth >= AppBreakpoints.wide) return 1.85;
    if (screenWidth >= AppBreakpoints.desktop) return 1.7;
    return 1.55;
  }

  /// Service carousel card width (clamped so tablets/desktop are not huge).
  double serviceCardWidth() {
    final inner = screenWidth - horizontalPadding * 2;
    return (inner * 0.72).clamp(240.0, 360.0);
  }

  double serviceSectionHeight() {
    if (screenWidth >= AppBreakpoints.desktop) return 190;
    return 170;
  }

  /// Truck / hero image in tracking card scales down on narrow phones.
  double trackingTruckWidth() {
    return (screenWidth * 0.28).clamp(72.0, 150.0);
  }

  double trackingTruckHeight() {
    return trackingTruckWidth() * 0.66;
  }
}
