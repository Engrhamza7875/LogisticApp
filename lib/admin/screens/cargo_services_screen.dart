import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../core/icon_mapper.dart';
import 'package:animate_do/animate_do.dart';
import '../services/admin_service.dart';
import '../widgets/role_guard.dart';

class CargoServicesScreen extends StatefulWidget {
  const CargoServicesScreen({super.key});

  @override
  State<CargoServicesScreen> createState() => _CargoServicesScreenState();
}

class _CargoServicesScreenState extends State<CargoServicesScreen> {
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['Admin', 'SuperAdmin']);
    });
  }

  void _addService() => _showServiceDialog();

  void _editService(int index, Map<String, dynamic> service) =>
      _showServiceDialog(index: index, existingService: service);

  void _deleteService(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Logic Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Deactivating this service will remove it from the global catalog. Continue?',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abort', style: TextStyle(color: Colors.white24)),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminService>().deleteCargoService(index);
              Navigator.pop(context);
              _snack('Service decommissioned');
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showServiceDialog({int? index, Map<String, dynamic>? existingService}) {
    final tCtrl = TextEditingController(text: existingService?['title']);
    final dCtrl = TextEditingController(text: existingService?['description']);
    final isEdit = index != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isEdit ? 'Refine Service' : 'Initialize Service',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(
              tCtrl,
              'Service Designation',
              Icons.label_important_rounded,
            ),
            const SizedBox(height: 16),
            _dialogField(
              dCtrl,
              'Operational Scope',
              Icons.analytics_rounded,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (tCtrl.text.isNotEmpty && dCtrl.text.isNotEmpty) {
                final data = {
                  'title': tCtrl.text,
                  'image':
                      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=400&fit=crop',
                  'subtitle': 'Global Logistics',
                  'iconCode': Icons.local_shipping_rounded.codePoint,
                  'colorValue': _accentColor.value,
                  'description': dCtrl.text,
                  'features': ['Network Optimization', 'Live Telemetry'],
                };
                if (isEdit)
                  context.read<AdminService>().updateCargoService(index, data);
                else
                  context.read<AdminService>().addCargoService(data);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isEdit ? 'Commit Changes' : 'Initialize',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: _accentColor, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Using shared icon mapper from core/icon_mapper.dart

  @override
  Widget build(BuildContext context) {
    final services = context.watch<AdminService>().cargoServices;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                _buildHeader(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: services.length,
                    itemBuilder: (context, i) => FadeInUp(
                      delay: Duration(milliseconds: 50 * i),
                      child: _buildGlassCard(i, services[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addService,
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'ADD SERVICE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                'Logistics Engine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PORTFOLIO GOVERNANCE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CORE OFFERINGS',
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Asset Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(int i, Map<String, dynamic> s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white24,
                size: 20,
              ),
              color: const Color(0xFF1E293B),
              onSelected: (v) =>
                  v == 'e' ? _editService(i, s) : _deleteService(i),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'e',
                  child: Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'd',
                  child: Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconFromCode(s['iconCode'] as int?),
                    color: _accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s['title']?.toString().toUpperCase() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  s['description']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
