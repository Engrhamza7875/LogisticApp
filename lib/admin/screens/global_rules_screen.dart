import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../services/admin_service.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/role_guard.dart';

class GlobalRulesScreen extends StatefulWidget {
  const GlobalRulesScreen({super.key});

  @override
  State<GlobalRulesScreen> createState() => _GlobalRulesScreenState();
}

class _GlobalRulesScreenState extends State<GlobalRulesScreen> {
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  void initState() {
    super.initState();
    final adminService = Provider.of<AdminService>(context, listen: false);
    _rateController.text = adminService.shippingRate.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
    });
  }

  void _updateRate() {
    final newRate = double.tryParse(_rateController.text);
    if (newRate != null) {
      context.read<AdminService>().updateShippingRate(newRate);
      _snack('Global Tariff Protocol Updated');
    }
  }

  void _addRoute() {
    if (_routeController.text.isNotEmpty) {
      context.read<AdminService>().addRoute(_routeController.text);
      _routeController.clear();
      _snack('Network Expansion Complete');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _rateController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_bgDark, _bgDark.withBlue(30)])))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 20),
                  FadeInDown(child: _buildHeaderBanner()),
                  const SizedBox(height: 32),
                  _buildRateSection(),
                  const SizedBox(height: 32),
                  _buildRouteSection(adminService),
                  const SizedBox(height: 32),
                  _buildFeatureGovernance(adminService),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Policy Governance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('SYSTEM OPERATIONAL PARAMETERS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [_accentColor, _accentColor.withBlue(200)]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 20),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Economic Framework', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Adjust global shipping tariffs and international route expansion.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
        ],
      ),
    );
  }

  Widget _buildRateSection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GLOBAL TARIFF PROTOCOL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: _rateController, keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      decoration: InputDecoration(prefixText: 'SAR ', prefixStyle: TextStyle(color: _accentColor, fontWeight: FontWeight.bold), hintText: '0.00', hintStyle: const TextStyle(color: Colors.white10), border: InputBorder.none),
                    )),
                    ElevatedButton(
                      onPressed: _updateRate,
                      style: ElevatedButton.styleFrom(backgroundColor: _accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      child: const Text('Update Tariff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 32),
                const Row(children: [Icon(Icons.info_outline_rounded, color: Colors.white24, size: 14), SizedBox(width: 8), Expanded(child: Text('This rate dynamically updates calculations across all branch hubs.', style: TextStyle(color: Colors.white24, fontSize: 11)))]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(AdminService service) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LOGISTICS NETWORK MAPPING', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(
              children: [
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: service.activeRoutes.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentColor.withOpacity(0.2))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r, style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: () => service.removeRoute(r), child: Icon(Icons.close_rounded, size: 14, color: _accentColor)),
                      ],
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(child: TextField(
                        controller: _routeController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(hintText: 'Define new hub route...', hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
                      )),
                      IconButton(onPressed: _addRoute, icon: Icon(Icons.add_box_rounded, color: _accentColor, size: 28)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGovernance(AdminService service) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('USER INTERFACE GOVERNANCE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(
              children: service.featureToggles.entries.map((e) {
                return ListTile(
                  leading: Icon(_getFeatureIcon(e.key), color: e.value ? _accentColor : Colors.white24, size: 20),
                  title: Text(e.key.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: e.value ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(e.value ? 'Active & Visible' : 'Restricted / Hidden', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  trailing: Switch(
                    value: e.value,
                    onChanged: (val) => service.updateFeatureToggle(e.key, val),
                    activeColor: _accentColor,
                    activeTrackColor: _accentColor.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String key) {
    switch (key) {
      case 'file_upload': return Icons.cloud_upload_rounded;
      case 'comments_section': return Icons.comment_rounded;
      case 'metrics_view': return Icons.analytics_rounded;
      case 'profile_edit': return Icons.manage_accounts_rounded;
      case 'ai_chat': return Icons.smart_toy_rounded;
      default: return Icons.toggle_on_rounded;
    }
  }
}
