import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';

import '../core/colors.dart';
import '../models/shipment.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import '../admin/services/admin_service.dart';
import '../core/widgets/sabcargo_status_badge.dart';
import 'tracking_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'notification_screen.dart';
import 'help_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _userName = 'Customer';
  String _userPhoto = '';
  List<Shipment> _recentShipments = [];
  bool _isLoading = true;
  bool _isSearching = false;
  int _notificationCount = 3;

  int _totalCount = 0;
  int _activeCount = 0;
  int _deliveredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    AuthService.profileUpdateNotifier.addListener(_onProfileUpdate);
  }

  void _onProfileUpdate() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    AuthService.profileUpdateNotifier.removeListener(_onProfileUpdate);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTracking(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final shipment = await ShipmentService.trackShipment(clean);
      if (!mounted) return;
      setState(() => _isSearching = false);

      if (shipment != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(shipment: shipment)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipment "$clean" not found. Check tracking number.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final details = await AuthService.getUserDetails();
      if (mounted) {
        setState(() {
          _userName = details['name'] ?? 'Customer';
          _userPhoto = details['photo'] ?? '';
        });
      }

      final shipments = await ShipmentService.getShipments();
      if (mounted) {
        setState(() {
          _recentShipments = shipments;
          _totalCount = shipments.length;
          _activeCount = shipments
              .where((s) =>
                  s.status == ShipmentStatus.inTransit ||
                  s.status == ShipmentStatus.outForDelivery)
              .length;
          _deliveredCount = shipments
              .where((s) => s.status == ShipmentStatus.delivered)
              .length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final toggles = adminService.featureToggles;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: toggles['ai_chat'] == false
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatBotScreen()),
              ),
              backgroundColor: AppColors.orange,
              elevation: 4,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.orange,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildHeroHeader(),
            _buildSystemIntegrityChart(),
            _buildServicesSection(),
            _buildShipmentList(),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      expandedHeight: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: ClipOval(
                child: _userPhoto.isNotEmpty
                    ? Image.memory(base64Decode(_userPhoto), fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.person,
                            color: AppColors.navy, size: 20),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SABCARGO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.navy,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Text(
                'Enterprise Logistics',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.navy, size: 24),
            ),
            if (_notificationCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeroHeader() {
    final double progressPct =
        _totalCount == 0 ? 0.0 : (_deliveredCount / _totalCount).clamp(0.0, 1.0);

    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Clean Slate Navy Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeInDown(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME BACK,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Metrics Grid inside Navy Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                    child: _innerStat(
                                        'TOTAL', _totalCount, Colors.white)),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white12),
                                Expanded(
                                    child: _innerStat(
                                        'IN TRANSIT', _activeCount, AppColors.orange)),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white12),
                                Expanded(
                                    child: _innerStat(
                                        'DELIVERED', _deliveredCount, AppColors.success)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progressPct,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.orange),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(progressPct * 100).toInt()}% Done',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Box with Cargo Orange Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _searchTracking,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Tracking ID (e.g. SAB-2024-001)...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSearching
                        ? null
                        : () => _searchTracking(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Track',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _innerStat(String label, int val, Color valColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val.toString(),
          style: TextStyle(
            color: valColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
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
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSystemIntegrityChart() {
    final adminService = context.watch<AdminService>();
    if (adminService.featureToggles['metrics_view'] == false) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeInUp(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SHIPMENT VELOCITY TRENDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.orangeBorder),
                    ),
                    child: const Text(
                      'Live Metrics',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3),
                          FlSpot(2, 4.2),
                          FlSpot(4, 3.8),
                          FlSpot(6, 5.5),
                          FlSpot(8, 4.8),
                          FlSpot(10, 6.2),
                        ],
                        isCurved: true,
                        color: AppColors.orange,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.orange.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 13),
                  SizedBox(width: 5),
                  Text(
                    '99.8% On-Time Global Fulfillment Network',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final adminService = context.watch<AdminService>();
    final services = adminService.cargoServices;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'CARGO SERVICES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return FadeInRight(
                  delay: Duration(milliseconds: 60 * i),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: s['image'] != null && s['image'].isNotEmpty
                              ? Image.network(
                                  s['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: AppColors.navy,
                                    child: const Center(
                                      child: Icon(Icons.inventory_2_rounded,
                                          color: Colors.white38, size: 36),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.navy,
                                  child: const Center(
                                    child: Icon(Icons.inventory_2_rounded,
                                        color: Colors.white38, size: 36),
                                  ),
                                ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.navy.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s['title'] ?? 'Freight',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SabCargo Verified',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentList() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT SHIPMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Showing ${_recentShipments.take(4).length} items',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            )
          else if (_recentShipments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: AppColors.textMuted, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No shipments yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Book a shipment to track it live here.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentShipments.take(4).map((s) => _buildShipmentItem(s)),

          const SizedBox(height: 16),
          // Enterprise Support Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.headset_mic_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Logistics Assistance?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Support desk and FAQs available 24/7',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white60, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentItem(Shipment s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(shipment: s)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  s.status == ShipmentStatus.delivered
                      ? Icons.check_circle_rounded
                      : Icons.local_shipping_rounded,
                  color: s.statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          s.trackingNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${s.origin.split(',')[0]} → ${s.destination.split(',')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SabCargoStatusBadge(
                statusText: s.statusLabel,
                color: s.statusColor,
                backgroundColor: s.statusBgColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
