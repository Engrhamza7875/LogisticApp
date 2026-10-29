import 'package:flutter/material.dart';
import '../colors.dart';
import '../../models/shipment.dart';

class SabCargoStatusBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const SabCargoStatusBadge({
    super.key,
    String? label,
    String? statusText,
    Color? foreground,
    Color? color,
    Color? background,
    Color? backgroundColor,
    this.icon,
  })  : label = label ?? statusText ?? '',
        foreground = foreground ?? color ?? AppColors.navy,
        background = background ?? backgroundColor ?? AppColors.surfaceVariant;

  factory SabCargoStatusBadge.fromStatus(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return const SabCargoStatusBadge(
          label: 'Delivered',
          foreground: AppColors.success,
          background: AppColors.successLight,
          icon: Icons.check_circle_rounded,
        );
      case ShipmentStatus.cancelled:
        return const SabCargoStatusBadge(
          label: 'Cancelled',
          foreground: AppColors.error,
          background: AppColors.errorLight,
          icon: Icons.cancel_rounded,
        );
      case ShipmentStatus.booked:
        return const SabCargoStatusBadge(
          label: 'Pending Pickup',
          foreground: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.schedule_rounded,
        );
      case ShipmentStatus.received:
        return const SabCargoStatusBadge(
          label: 'At Branch',
          foreground: AppColors.info,
          background: AppColors.infoLight,
          icon: Icons.home_work_rounded,
        );
      case ShipmentStatus.processing:
        return const SabCargoStatusBadge(
          label: 'Processing',
          foreground: AppColors.navy,
          background: AppColors.surfaceVariant,
          icon: Icons.sync_rounded,
        );
      case ShipmentStatus.inTransit:
        return const SabCargoStatusBadge(
          label: 'In Transit',
          foreground: AppColors.info,
          background: AppColors.infoLight,
          icon: Icons.local_shipping_rounded,
        );
      case ShipmentStatus.outForDelivery:
        return const SabCargoStatusBadge(
          label: 'Out for Delivery',
          foreground: AppColors.orange,
          background: AppColors.orangeLight,
          icon: Icons.delivery_dining_rounded,
        );
    }
  }

  factory SabCargoStatusBadge.active(bool isActive) {
    if (isActive) {
      return const SabCargoStatusBadge(
        label: 'Active',
        foreground: AppColors.success,
        background: AppColors.successLight,
        icon: Icons.fiber_manual_record,
      );
    } else {
      return const SabCargoStatusBadge(
        label: 'Inactive',
        foreground: AppColors.error,
        background: AppColors.errorLight,
        icon: Icons.block_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
