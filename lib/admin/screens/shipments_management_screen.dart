import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/colors.dart';
import '../../models/shipment.dart';
import '../../services/api_service.dart';
import '../../services/shipment_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/shipment_repository.dart';
import '../../core/role_middleware.dart';
import '../widgets/role_guard.dart';

class ShipmentsManagementScreen extends StatefulWidget {
  const ShipmentsManagementScreen({super.key});

  @override
  State<ShipmentsManagementScreen> createState() =>
      _ShipmentsManagementScreenState();
}

class _ShipmentsManagementScreenState extends State<ShipmentsManagementScreen> {
  final AuthRepository _authRepository = AuthRepository();

  AppUser? _currentUser;
  List<Shipment> _allShipments = [];
  List<Shipment> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _officeFilter = 'All';
  DateTimeRange? _dateRange;

  final List<String> _statusFilters = [
    'All',
    'Booked',
    'Received',
    'Processing',
    'In Transit',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['Admin', 'SuperAdmin']);
    });
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _currentUser = await _authRepository.getCurrentUser();
      // Start listening to the stream
      ShipmentService.shipmentStream.listen((shipments) {
        if (mounted) {
          setState(() {
            _allShipments = shipments;
            _applyFilter();
            _loading = false;
          });
        }
      });
      // Initial load
      await ShipmentService.refresh();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack('Initialization Failed: $e', isError: true);
    }
  }

  void _applyFilter() {
    if (_currentUser == null) return;

    // The repository already handles basic Role/Branch isolation,
    // but we apply additional UI filters (search, status, date) here.
    var list = _allShipments
        .where((s) => RoleMiddleware.canAccessShipment(_currentUser!, s))
        .toList();

    // Super Admin additional branch filter
    if (_currentUser!.isSuperAdmin && _officeFilter != 'All') {
      final city = _officeFilter.toLowerCase();
      list = list
          .where(
            (s) =>
                s.origin.toLowerCase().contains(city) ||
                s.destination.toLowerCase().contains(city),
          )
          .toList();
    }

    if (_dateRange != null) {
      list = list.where((s) {
        try {
          // Expected date format assumed to be DD/MM/YYYY or similar from backend
          final dateParts = s.expectedDate.split('/');
          final d = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
          return d.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();
    }

    if (_statusFilter != 'All') {
      final statusIdx = _statusFilters.indexOf(_statusFilter) - 1;
      list = list.where((s) => s.status.index == statusIdx).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.trackingNumber.toLowerCase().contains(q) ||
                s.itemName.toLowerCase().contains(q),
          )
          .toList();
    }

    setState(() {
      _filtered = list;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final p = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: _bgDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (p != null) {
      setState(() => _dateRange = p);
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _filtered.length;
    final del = _filtered
        .where((s) => s.status == ShipmentStatus.delivered)
        .length;
    final trans = _filtered
        .where(
          (s) =>
              s.status == ShipmentStatus.inTransit ||
              s.status == ShipmentStatus.outForDelivery,
        )
        .length;
    final pen = _filtered
        .where(
          (s) =>
              s.status == ShipmentStatus.booked ||
              s.status == ShipmentStatus.received,
        )
        .length;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgDark, _bgDark.withBlue(40)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildStats(total, pen, trans, del),
                _buildFilters(),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(color: _accentColor),
                        )
                      : RefreshIndicator(
                          onRefresh: ShipmentService.refresh,
                          color: _accentColor,
                          child: _filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No shipments found',
                                    style: TextStyle(color: Colors.white24),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    100,
                                  ),
                                  itemCount: _filtered.length,
                                  itemBuilder: (c, i) => FadeInUp(
                                    delay: Duration(milliseconds: 30 * i),
                                    child: _buildTile(_filtered[i]),
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Intelligence',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'UNIFIED GOVERNANCE CENTER',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_currentUser?.isSuperAdmin == true) _buildOfficeSelector(),
        ],
      ),
    );
  }

  Widget _buildOfficeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _officeFilter,
          dropdownColor: _bgDark,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white60,
            size: 16,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          items: [
            'All',
            'Jeddah',
            'Riyadh',
            'Dammam',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() {
            _officeFilter = v!;
            _applyFilter();
          }),
        ),
      ),
    );
  }

  Widget _buildStats(int t, int p, int r, int d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', t.toString(), Icons.analytics, Colors.white),
          _statItem('Pending', p.toString(), Icons.timer, Colors.white38),
          _statItem(
            'Transit',
            r.toString(),
            Icons.local_shipping,
            Colors.amber,
          ),
          _statItem(
            'Done',
            d.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String l, String v, IconData i, Color c) {
    return Column(
      children: [
        Icon(i, color: c.withOpacity(0.6), size: 14),
        const SizedBox(height: 6),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(l, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilter();
              },
              decoration: const InputDecoration(
                hintText: 'Search Track ID or Item...',
                hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                border: InputBorder.none,
                fillColor:
                    Colors.transparent, // Use container's white background
                icon: Icon(Icons.search, color: Colors.black38, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final sel = _statusFilter == s;
                return GestureDetector(
                  onTap: () => setState(() {
                    _statusFilter = s;
                    _applyFilter();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? _accentColor
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? _accentColor : Colors.white10,
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Shipment s) {
    return GestureDetector(
      onTap: () => _showTrackingDetails(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.orangeDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(s.type), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.trackingNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        s.itemName,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(s),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _shipInfo(Icons.location_on_outlined, 'Origin', s.origin)),
                const SizedBox(width: 4),
                Expanded(child: _shipInfo(Icons.flag_outlined, 'Dest.', s.destination)),
                const SizedBox(width: 4),
                Expanded(child: _shipInfo(Icons.calendar_today_rounded, 'Date', s.expectedDate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Shipment s) {
    Color c;
    switch (s.status) {
      case ShipmentStatus.delivered:
        c = AppColors.success;
        break;
      case ShipmentStatus.booked:
        c = Colors.white60;
        break;
      case ShipmentStatus.cancelled:
        c = AppColors.error;
        break;
      case ShipmentStatus.received:
        c = AppColors.info;
        break;
      case ShipmentStatus.processing:
        c = AppColors.accent;
        break;
      default:
        c = Colors.amber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Text(
        s.statusLabel,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _shipInfo(IconData i, String l, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(i, size: 10, color: Colors.white24),
            const SizedBox(width: 4),
            Text(
              l,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  String _statusName(ShipmentStatus s) {
    return s.toString().split('.').last;
  }

  IconData _typeIcon(String t) {
    if (t.toLowerCase().contains('air')) return Icons.flight;
    if (t.toLowerCase().contains('sea')) return Icons.directions_boat;
    return Icons.local_shipping;
  }

  void _showTrackingDetails(Shipment s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track ${s.trackingNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          s.itemName,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateTracking(s),
                    icon: Icon(Icons.add_circle_outline, color: _accentColor),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: Colors.white10),
            Expanded(
              child: s.steps.isEmpty
                  ? const Center(
                      child: Text(
                        'No movement records found',
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: s.steps.length,
                      itemBuilder: (c, i) {
                        final step = s.steps.reversed.toList()[i];
                        return _buildStep(step, i == 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(TrackingStep step, bool isNew) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isNew ? _accentColor : Colors.white12,
                  shape: BoxShape.circle,
                  boxShadow: isNew
                      ? [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              Expanded(child: Container(width: 2, color: Colors.white10)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: isNew ? Colors.white : Colors.white60,
                      fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    step.subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Text(
                    step.time,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTracking(Shipment s) {
    final tCtrl = TextEditingController();
    final sCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Update Logistics Step',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Status Title',
                labelStyle: TextStyle(color: AppColors.textMuted),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Location/Note',
                labelStyle: TextStyle(color: AppColors.textMuted),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tCtrl.text.isEmpty) return;
              await ShipmentService.addTrackingStep(
                shipmentId: s.id,
                title: tCtrl.text,
                subtitle: sCtrl.text,
              );
              await ShipmentService.refresh();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Step'),
          ),
        ],
      ),
    );
  }
}
