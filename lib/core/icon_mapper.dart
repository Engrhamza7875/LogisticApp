import 'package:flutter/material.dart';

IconData iconFromCode(int? code) {
  // Return constant IconData values for known codePoints to keep icons
  // tree-shakeable in AOT builds.
  if (code == null) return Icons.local_shipping_rounded;
  if (code == Icons.local_shipping_rounded.codePoint)
    return Icons.local_shipping_rounded;
  if (code == Icons.label_important_rounded.codePoint)
    return Icons.label_important_rounded;
  if (code == Icons.analytics_rounded.codePoint) return Icons.analytics_rounded;
  if (code == Icons.add_rounded.codePoint) return Icons.add_rounded;
  if (code == Icons.more_vert_rounded.codePoint) return Icons.more_vert_rounded;
  if (code == Icons.flight_rounded.codePoint) return Icons.flight_rounded;
  if (code == Icons.directions_boat_rounded.codePoint)
    return Icons.directions_boat_rounded;
  return Icons.help_outline_rounded;
}
