import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../core/widgets/sabcargo_status_badge.dart';
import '../services/driver_service.dart';
import '../services/auth_service.dart';
import '../models/shipment.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final driverService = context.watch<DriverService>();
    final activeMissions = driverService.missions
        .where((m) => m.status != ShipmentStatus.delivered)
        .toList();
    final completedMissions = driverService.missions
        .where((m) => m.status == ShipmentStatus.delivered)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Active Shift • GPS Synchronized',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/pin-login', (route) => false);
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatBanner(driverService.missions.length, completedMissions.length),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACTIVE MISSIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.orangeBorder),
                  ),
                  child: Text(
                    '${activeMissions.length} Pending',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (activeMissions.isEmpty)
              _buildEmptyMissions()
            else
              ...activeMissions
                  .map((m) => _buildMissionCard(context, m, driverService)),
            const SizedBox(height: 28),
            const Text(
              'COMPLETED TODAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            if (completedMissions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No completed deliveries yet today.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ...completedMissions.map((m) => _buildCompletedCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBanner(int total, int done) {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('ASSIGNED', total.toString(), Icons.assignment_rounded),
            Container(width: 1, height: 36, color: Colors.white12),
            _statItem('COMPLETED', done.toString(), Icons.check_circle_rounded),
            Container(width: 1, height: 36, color: Colors.white12),
            _statItem('RATING', '4.95 ★', Icons.star_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.orange, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(
      BuildContext context, Shipment mission, DriverService service) {
    final isOut = mission.status == ShipmentStatus.outForDelivery;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FadeInLeft(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mission.trackingNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SabCargoStatusBadge(
                    statusText: mission.statusLabel,
                    color: mission.statusColor,
                    backgroundColor: mission.statusBgColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mission.itemName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _locationRow(Icons.radio_button_checked, mission.origin, AppColors.navy),
              Padding(
                padding: const EdgeInsets.only(left: 7, top: 3, bottom: 3),
                child: Container(
                  width: 2,
                  height: 14,
                  color: AppColors.border,
                ),
              ),
              _locationRow(
                  Icons.location_on_rounded, mission.destination, AppColors.orange),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isOut) {
                      service.completeMission(mission.id);
                    } else {
                      service.startMission(mission.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOut ? AppColors.success : AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isOut ? 'Complete Delivery' : 'Pickup Shipment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(Shipment mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.itemName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Delivered to ${mission.destination.split(',')[0]}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SabCargoStatusBadge(
            statusText: 'Delivered',
            color: AppColors.success,
            backgroundColor: AppColors.successLight,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMissions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.done_all_rounded, color: AppColors.success, size: 44),
          SizedBox(height: 12),
          Text(
            'All Missions Completed!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Stand by for dispatch assignments.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
