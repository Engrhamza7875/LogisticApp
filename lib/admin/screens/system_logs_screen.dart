import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/colors.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/role_guard.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterAction = 'All';

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  static const List<String> _actionFilters = [
    'All', 'LOGIN', 'VERIFY_ACCOUNT', 'UPSERT_SHIPMENT', 'UPDATE_TRACKING',
    'ADD_SERVICE', 'DELETE_SERVICE', 'EDIT_USER', 'DELETE_USER',
    'DISABLE_USER', 'ENABLE_USER', 'LOCK_USER', 'FORCE_LOGOUT',
    'RESET_USER_PIN', 'BROADCAST_NOTIFICATION', 'CANCEL_SHIPMENT',
    'ENABLE_ADMIN', 'DISABLE_ADMIN', 'RESET_ADMIN_PIN',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await ApiService.fetchLogs(limit: 200);
      setState(() {
        _allLogs = logs;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = List<Map<String, dynamic>>.from(_allLogs);
    if (_filterAction != 'All') list = list.where((l) => l['action'] == _filterAction).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) => (l['userEmail'] ?? '').toString().toLowerCase().contains(q) || (l['action'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  Color _actionColor(String a) {
    if (a.contains('DELETE') || a.contains('LOCK') || a.contains('CANCEL')) return AppColors.error;
    if (a.contains('DISABLE') || a.contains('FORCE')) return Colors.orange;
    if (a.contains('ENABLE') || a.contains('VERIFY') || a.contains('LOGIN')) return AppColors.success;
    return _accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_bgDark, _bgDark.withBlue(30)])))),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildFilterBar(),
                Expanded(
                  child: _loading 
                    ? Center(child: CircularProgressIndicator(color: _accentColor))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (c, i) => FadeInUp(delay: Duration(milliseconds: 30*i.clamp(0, 10)), child: _buildLogTile(_filtered[i])),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Security Audit', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('SYSTEM EVENT TELEMETRY', style: TextStyle(color: _accentColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        const Spacer(),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white24)),
      ]),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: TextField(
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onChanged: (v) { _searchQuery = v; _applyFilter(); },
            decoration: const InputDecoration(
              hintText: 'Search audit trail...', 
              hintStyle: TextStyle(color: Colors.black26, fontSize: 14), 
              border: InputBorder.none, 
              fillColor: Colors.transparent,
              icon: Icon(Icons.search, color: Colors.black38, size: 20)
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _actionFilters.map((f) {
            final sel = _filterAction == f;
            return GestureDetector(
              onTap: () => setState(() { _filterAction = f; _applyFilter(); }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: sel ? _accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.05))),
                child: Text(f, style: TextStyle(color: sel ? _accentColor : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final action = (log['action'] ?? 'UNKNOWN') as String;
    final color = _actionColor(action);
    final email = (log['userEmail'] ?? 'System') as String;
    final date = DateFormat('dd MMM, HH:mm').format(DateTime.parse(log['createdAt'].toString()).toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_actionIcon(action), color: color, size: 18)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(action, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            if (log['details'] != null && log['details'].toString() != 'null') Text(log['details'].toString(), style: const TextStyle(color: Colors.white24, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Text(date, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  IconData _actionIcon(String a) {
    if (a == 'LOGIN') return Icons.login_rounded;
    if (a.contains('SHIPMENT')) return Icons.local_shipping_rounded;
    if (a.contains('USER')) return Icons.person_rounded;
    if (a.contains('ADMIN')) return Icons.admin_panel_settings_rounded;
    return Icons.history_rounded;
  }
}
