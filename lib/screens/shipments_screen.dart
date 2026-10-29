import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../models/shipment.dart';
import 'tracking_screen.dart';

import '../services/shipment_service.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Active', 'Delivered', 'Pending'];
  List<Shipment> _allShipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() => _isLoading = true);
    final data = await ShipmentService.getShipments();
    if (mounted) {
      setState(() {
        _allShipments = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Shipment> get _filtered {
    switch (_tabController.index) {
      case 1:
        return _allShipments
            .where(
              (s) =>
                  s.status == ShipmentStatus.inTransit ||
                  s.status == ShipmentStatus.outForDelivery ||
                  s.status == ShipmentStatus.booked,
            )
            .toList();
      case 2:
        return _allShipments
            .where((s) => s.status == ShipmentStatus.delivered)
            .toList();
      case 3:
        return _allShipments
            .where((s) => s.status == ShipmentStatus.booked)
            .toList();
      default:
        return _allShipments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Shipment>>(
        stream: ShipmentService.shipmentStream,
        initialData: _allShipments,
        builder: (context, snapshot) {
          final shipments = snapshot.data ?? [];
          _allShipments = shipments;
          
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 20,
                    24,
                    0,
                  ),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        child: const Text(
                          'My Shipments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          '${shipments.length} total shipments',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: AppColors.accent,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.5),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: _tabs.map((t) => Tab(text: t)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: _loadShipments,
              color: AppColors.primary,
              child: (_isLoading || snapshot.connectionState == ConnectionState.waiting) && shipments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => FadeInUp(
                            delay: Duration(milliseconds: i * 50),
                            child: _buildCard(_filtered[i]),
                          ),
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No shipments found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your shipments will appear here',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Shipment s) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrackingScreen(shipment: s)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: s.statusBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _typeIcon(s.type),
                      color: s.statusColor,
                      size: 26,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.trackingNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: s.statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: s.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  _infoChip(Icons.location_on_rounded, s.origin.split(',')[0]),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  _infoChip(Icons.flag_rounded, s.destination.split(',')[0]),
                  const Spacer(),
                  _infoChip(Icons.scale_rounded, '${s.weight} kg'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(String type) {
    if (type.contains('Air')) return Icons.flight_rounded;
    if (type.contains('Sea')) return Icons.directions_boat_rounded;
    return Icons.local_shipping_rounded;
  }
}
