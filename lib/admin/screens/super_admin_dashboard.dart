import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'manage_admins_screen.dart';
import 'global_rules_screen.dart';
import 'system_logs_screen.dart';
import 'office_locations_screen.dart';
import 'users_management_screen.dart';
import 'shipments_management_screen.dart';
import 'cargo_services_screen.dart';
import 'broadcasting_screen.dart';
import '../widgets/role_guard.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _logs = [];
  int _selectedIndex = 0;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // System Health Metrics Simulation
  Timer? _metricsTimer;
  double _cpuUsage = 38.0;
  double _ramUsage = 58.0;
  double _diskUsage = 24.0;
  double _networkRx = 1.4;
  double _networkTx = 0.9;
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _initDashboard();
    _startMetricsSimulation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
    });
  }

  void _startMetricsSimulation() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _cpuUsage = (35 + (DateTime.now().second % 18)).toDouble();
          _ramUsage = (55 + (DateTime.now().second % 8)).toDouble();
          _networkRx = (1.2 + (DateTime.now().second / 50));
          _networkTx = (0.6 + (DateTime.now().second / 80));
        });
      }
    });
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    final analytics = await ApiService.fetchAnalytics(
      startDate: _dateRange.start,
      endDate: _dateRange.end,
    );

    if (mounted) {
      setState(() {
        _stats = analytics;
        _logs = (analytics['activity'] as List? ?? []).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  )
                : RefreshIndicator(
                    onRefresh: _initDashboard,
                    color: AppColors.orange,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(isDesktop),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 28 : 16,
                              vertical: 12,
                            ),
                            child: _buildAtlasBanner(),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildKPIs(isDesktop)),
                        SliverToBoxAdapter(child: _buildSystemHealth(isDesktop)),
                        SliverToBoxAdapter(child: _buildCharts(isDesktop)),
                        SliverToBoxAdapter(child: _buildActivityFeed(isDesktop)),
                        const SliverToBoxAdapter(child: SizedBox(height: 50)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtlasBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_done_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MONGODB ATLAS CLOUD',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.navy,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '• LIVE & SYNCHRONIZED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Cluster: cluster0.jwiq9ec.mongodb.net | DB: cargoApp | Authoritative Production Store',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.orangeBorder),
            ),
            child: const Text(
              'TLS 1.3 Encrypted',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.security_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SABCARGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sidebarItem(0, Icons.dashboard_rounded, 'Dashboard'),

                  const Padding(
                    padding: EdgeInsets.only(left: 14, top: 18, bottom: 6),
                    child: Text(
                      'LOGISTICS FLEET',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _sidebarItem(1, Icons.business_rounded, 'Office Locations'),
                  _sidebarItem(2, Icons.manage_accounts_rounded, 'Office Admins'),
                  _sidebarItem(3, Icons.people_rounded, 'User Accounts'),
                  _sidebarItem(4, Icons.inventory_2_rounded, 'All Shipments'),
                  _sidebarItem(5, Icons.local_shipping_rounded, 'Cargo Services'),

                  const Padding(
                    padding: EdgeInsets.only(left: 14, top: 18, bottom: 6),
                    child: Text(
                      'SYSTEM GOVERNANCE',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _sidebarItem(6, Icons.receipt_long_rounded, 'System Logs'),
                  _sidebarItem(7, Icons.tune_rounded, 'Global Pricing & Rules'),
                  _sidebarItem(8, Icons.campaign_rounded, 'Push Broadcasting'),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/pin-login', (route) => false);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: const Row(
                  children: [
                    Icon(Icons.power_settings_new_rounded,
                        color: AppColors.error, size: 20),
                    SizedBox(width: 14),
                    Text(
                      'Logout Session',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index != 0) _handleNavigation(index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    Widget? target;
    switch (index) {
      case 1:
        target = const OfficeLocationsScreen();
        break;
      case 2:
        target = const ManageAdminsScreen();
        break;
      case 3:
        target = const UsersManagementScreen();
        break;
      case 4:
        target = const ShipmentsManagementScreen();
        break;
      case 5:
        target = const CargoServicesScreen();
        break;
      case 6:
        target = const SystemLogsScreen();
        break;
      case 7:
        target = const GlobalRulesScreen();
        break;
      case 8:
        target = const BroadcastingScreen();
        break;
    }
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
    }
  }

  Widget _buildAppBar(bool isDesktop) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: isDesktop
          ? null
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.navy),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Command Center',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Root Operations • Enterprise Governance',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.orange, size: 14),
                const SizedBox(width: 8),
                Text(
                  '${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.navy),
              onPressed: () => setState(() => _notificationCount = 0),
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
        const SizedBox(width: 14),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _initDashboard();
    }
  }

  Widget _buildKPIs(bool isDesktop) {
    final kpis = _stats?['kpis'] ?? {};
    final users = _stats?['users'] ?? {};
    final offices = _stats?['offices'] ?? {};

    final totalOffices = offices['totalOffices']?.toString() ?? '4';
    final totalShipments = kpis['totalShipments']?.toString() ?? '0';
    final shipmentsToday = (kpis['today'] ?? 0).toString();
    final activeUsers = (users['total'] ?? 0).toString();

    final kpiCards = [
      _kpiCard('Branch Hubs', totalOffices, Icons.business_rounded, AppColors.navy),
      _kpiCard('Total Shipments', totalShipments, Icons.inventory_2_rounded, AppColors.orange),
      _kpiCard("Today's Volume", shipmentsToday, Icons.today_rounded, AppColors.info),
      _kpiCard('Active Users', activeUsers, Icons.people_rounded, AppColors.success),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 10,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: kpiCards
            .map((c) => SizedBox(
                  width: isDesktop
                      ? (MediaQuery.of(context).size.width - 320 - (16 * 3)) / 4
                      : (MediaQuery.of(context).size.width - 48) / 2,
                  child: c,
                ))
            .toList(),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVER RESOURCE TELEMETRY',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _healthMetric(
                  'CPU CORE',
                  '${_cpuUsage.toStringAsFixed(1)}%',
                  _cpuUsage > 80 ? AppColors.error : AppColors.success,
                  _cpuUsage / 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _healthMetric(
                  'MEMORY',
                  '${_ramUsage.toStringAsFixed(1)}%',
                  _ramUsage > 85 ? AppColors.error : AppColors.info,
                  _ramUsage / 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _healthMetric(
                  'STORAGE',
                  '${_diskUsage.toStringAsFixed(1)}%',
                  AppColors.orange,
                  _diskUsage / 100,
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _healthMetric(
                    'NET RX',
                    '${_networkRx.toStringAsFixed(2)} Mb/s',
                    AppColors.info,
                    0.6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _healthMetric(
                    'NET TX',
                    '${_networkTx.toStringAsFixed(2)} Mb/s',
                    AppColors.navy,
                    0.4,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthMetric(
      String label, String value, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.bolt_rounded, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 12,
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _chartContainer(
                      'Dispatch Velocity (30 Days)', _buildLineChart()),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _chartContainer(
                      'Operational Status Ratio', _buildPieChart()),
                ),
              ],
            )
          : Column(
              children: [
                _chartContainer(
                    'Dispatch Velocity (30 Days)', _buildLineChart()),
                const SizedBox(height: 16),
                _chartContainer(
                    'Operational Status Ratio', _buildPieChart()),
              ],
            ),
    );
  }

  Widget _chartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(22),
      height: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final trends = (_stats?['charts']?['dailyTrends'] as List? ?? []);
    if (trends.isEmpty) {
      return const Center(
        child: Text(
          'Collecting trend data...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: trends
              .asMap()
              .entries
              .map((e) => FlSpot(
                    e.key.toDouble(),
                    (e.value['count'] ?? 0).toDouble(),
                  ))
              .toList(),
          isCurved: true,
          color: AppColors.orange,
          barWidth: 3.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.orange.withOpacity(0.08),
          ),
        ),
      ],
    ));
  }

  Widget _buildPieChart() {
    final breakdown = (_stats?['charts']?['statusBreakdown'] as List? ?? []);
    if (breakdown.isEmpty) {
      return const Center(
        child: Text(
          'Calculating breakdown...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }
    return PieChart(
      PieChartData(
        sections: breakdown.map((item) {
          final status = item['Status'];
          final color = status == 3
              ? AppColors.success
              : (status == 0 ? AppColors.warning : AppColors.info);
          return PieChartSectionData(
            value: (item['count'] ?? 1).toDouble(),
            title: '',
            color: color,
            radius: 44,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityFeed(bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 12,
      ),
      padding: const EdgeInsets.all(22),
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
            children: [
              const Text(
                'GLOBAL AUDIT TRAIL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showAllLogs,
                child: const Text(
                  'VIEW ALL HISTORY',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No security logs recorded.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            ..._logs.take(8).map((log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: AppColors.navy, size: 18),
                  ),
                  title: Text(
                    log['action'] ?? 'System Event',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    log['userEmail'] ?? 'root@sabcargo.com',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Text(
                    log['createdAt']?.toString().split('T')[0] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _showAllLogs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'GLOBAL AUDIT TRAIL',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, i) {
                  final log = _logs[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppColors.navy, size: 16),
                    ),
                    title: Text(
                      log['action'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${log['userEmail']} | ${log['branch'] ?? 'Global'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      log['createdAt']?.toString().split('T')[0] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
