import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'shipments_management_screen.dart';
import 'cargo_services_screen.dart';
import 'users_management_screen.dart';
import '../widgets/role_guard.dart';

class OfficeAdminDashboard extends StatefulWidget {
  const OfficeAdminDashboard({super.key});

  @override
  State<OfficeAdminDashboard> createState() => _OfficeAdminDashboardState();
}

class _OfficeAdminDashboardState extends State<OfficeAdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _logs = [];
  String _branchName = 'Main Office Hub';
  int _selectedIndex = 0;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _initDashboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['Admin', 'SuperAdmin']);
    });
  }

  Future<void> _initDashboard() async {
    AuthService.getUserDetails().then((details) {
      if (mounted) {
        setState(() => _branchName = details['branch'] ?? 'Riyadh Hub');
      }
    });

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
                            child: _buildBranchBanner(),
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: FadeInDown(child: _buildKPIs(isDesktop))),
                        SliverToBoxAdapter(
                            child: FadeInUp(child: _buildCharts(isDesktop))),
                        SliverToBoxAdapter(
                            child: FadeInUp(child: _buildActivityFeed(isDesktop))),
                        const SliverToBoxAdapter(child: SizedBox(height: 50)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _branchName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ONLINE & OPERATIONAL',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Branch-specific fleet dispatch, receiving operations, and driver assignments.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
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
                    child: Icon(Icons.hub_rounded,
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
                        'OFFICE ADMIN',
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
                  _sidebarItem(0, Icons.grid_view_rounded, 'Branch Overview'),
                  const Padding(
                    padding: EdgeInsets.only(left: 14, top: 18, bottom: 6),
                    child: Text(
                      'OPERATIONS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _sidebarItem(1, Icons.groups_rounded, 'Branch Staff'),
                  _sidebarItem(2, Icons.inventory_2_rounded, 'Fleet Shipments'),
                  _sidebarItem(3, Icons.local_shipping_rounded, 'Cargo Types'),
                  _sidebarItem(4, Icons.arrow_back_rounded, 'Switch to Customer View'),
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
        target = const UsersManagementScreen();
        break;
      case 2:
        target = const ShipmentsManagementScreen();
        break;
      case 3:
        target = const CargoServicesScreen();
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/home');
        return;
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
          Text(
            _branchName,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Regional Dispatch & Receiving Hub',
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
        const SizedBox(width: 14),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _initDashboard();
    }
  }

  Widget _buildKPIs(bool isDesktop) {
    if (_stats == null) return const SizedBox.shrink();
    final kpis = _stats!['kpis'] ?? {};

    final kpiCards = [
      _kpiCard('Hub Shipments', kpis['totalShipments']?.toString() ?? '0',
          Icons.inventory_rounded, AppColors.navy),
      _kpiCard('In Transit', (kpis['today'] ?? 0).toString(),
          Icons.local_shipping_rounded, AppColors.orange),
      _kpiCard('Delivered', kpis['delivered']?.toString() ?? '0',
          Icons.verified_rounded, AppColors.success),
      _kpiCard('Branch Staff', _stats!['users']?['total']?.toString() ?? '0',
          Icons.people_alt_rounded, AppColors.info),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 8,
      ),
      child: isDesktop
          ? Row(
              children: kpiCards
                  .map((c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: c,
                        ),
                      ))
                  .toList(),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kpiCards
                  .map((c) => SizedBox(
                        width: (MediaQuery.of(context).size.width - 44) / 2,
                        child: c,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                      'Operational Dispatch Efficiency', _buildLineChart()),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _chartContainer(
                      'Hub Status Breakdown', _buildPieChart()),
                ),
              ],
            )
          : Column(
              children: [
                _chartContainer(
                    'Operational Dispatch Efficiency', _buildLineChart()),
                const SizedBox(height: 16),
                _chartContainer(
                    'Hub Status Breakdown', _buildPieChart()),
              ],
            ),
    );
  }

  Widget _chartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(22),
      height: 320,
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
          barWidth: 3,
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
            radius: 40,
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
                'BRANCH OPERATIONAL LOGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE FEED',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No operational logs recorded.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            ..._logs.take(5).map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: AppColors.navy, size: 14),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['action'] ?? 'Operation',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              log['userEmail'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        log['createdAt']?.toString().split('T')[0] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
