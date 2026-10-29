import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../models/shipment.dart';
import 'delivered_screen.dart';

class TrackingScreen extends StatelessWidget {
  final Shipment shipment;
  const TrackingScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      shipment.trackingNumber,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shipment.itemName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Status Card
                _buildStatusCard(context),
                // Route Card
                _buildRouteCard(),
                // Tracking Timeline
                _buildTimelineCard(),
                // Shipment Info
                _buildInfoCard(),
                if (shipment.status == ShipmentStatus.delivered)
                  _buildViewDeliveredButton(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'home_truck_image_${shipment.trackingNumber}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: shipment.statusBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shipment.status == ShipmentStatus.delivered
                      ? Icons.check_circle_rounded
                      : Icons.local_shipping_rounded,
                  color: shipment.statusColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Status',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(shipment.statusLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: shipment.statusColor)),
                  const SizedBox(height: 2),
                  Text('Expected: ${shipment.expectedDate}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                // Origin
                Expanded(
                  child: _locationBox(
                      shipment.origin, 'Origin', Icons.circle_outlined,
                      AppColors.primary),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          color: AppColors.accent, size: 22),
                      Text(shipment.type,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                // Destination
                Expanded(
                  child: _locationBox(
                      shipment.destination, 'Destination',
                      Icons.location_on_rounded, AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationBox(
      String location, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(location,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tracking Timeline',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            ...shipment.steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isLast = i == shipment.steps.length - 1;
              return _timelineStep(step, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(TrackingStep step, bool isLast) {
    Color dotColor;
    Color lineColor;
    if (step.isCompleted) {
      dotColor = AppColors.success;
      lineColor = AppColors.success;
    } else if (step.isCurrent) {
      dotColor = AppColors.accent;
      lineColor = AppColors.border;
    } else {
      dotColor = AppColors.border;
      lineColor = AppColors.border;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: step.isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: step.isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 12)
                    : step.isCurrent
                        ? const Icon(Icons.circle, color: Colors.white, size: 8)
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: step.isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: step.isCompleted || step.isCurrent
                              ? AppColors.textPrimary
                              : AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(step.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(step.time,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shipment Details',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _infoRow('Type', shipment.type),
            _infoRow('Weight', '${shipment.weight} kg'),
            _infoRow('Item', shipment.itemName),
            _infoRow('Expected Delivery', shipment.expectedDate),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildViewDeliveredButton(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DeliveredScreen(shipment: shipment)),
          ),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: const Text('View Delivery Confirmation',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
