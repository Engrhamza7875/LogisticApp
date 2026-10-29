import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../services/admin_service.dart';
import '../../services/api_service.dart';
import '../models/admin_user.dart';

import '../widgets/role_guard.dart';

class OfficeLocationsScreen extends StatefulWidget {
  const OfficeLocationsScreen({super.key});

  @override
  State<OfficeLocationsScreen> createState() => _OfficeLocationsScreenState();
}

class _OfficeLocationsScreenState extends State<OfficeLocationsScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    // Ensure we have the latest locations/admins from the real backend settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminService>().refreshData();
    });
    _loadUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
    });
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.fetchAllUsers();
      if (mounted) setState(() { _allUsers = users; _loadingUsers = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  void _showOfficeDetails(String officeName) {
    final adminService = context.read<AdminService>();
    final admins = adminService.admins.where((a) => a.branchName == officeName).toList();
    
    // Real association: users explicitly assigned to this office by Admin/SuperAdmin.
    final users = _allUsers
        .where((u) => (u['assignedOffice'] ?? '').toString() == officeName)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
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
                    Text(officeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Text('OFFICE GOVERNANCE DETAILS', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 32),
            
            // ADMINS SECTION
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Assigned Administrators (${admins.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (admins.isEmpty) 
              const Padding(
                padding: EdgeInsets.only(left: 28),
                child: Text('No administrators assigned to this branch.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...admins.map((admin) => ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(admin.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                title: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(admin.email, style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )),
            
            const SizedBox(height: 32),
            
            // USERS SECTION
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text('Attached Users (${users.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 28),
                child: Text('No users currently associated with this location.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.blue, size: 20)),
                      title: Text(u['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addLocation() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Office Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Branch Name',
                  hintText: 'e.g. Medina Office',
                  prefixIcon: const Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Branch Email',
                  hintText: 'e.g. admin.medina@sabcargo.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 05XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final branchName = nameController.text.trim();
                final adminService = context.read<AdminService>();
                
                // 1) Create the office location in global settings (real backend)
                await adminService.addOffice(branchName);
                
                // Generate a 6-digit PIN
                final pin = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
                
                // Create an AdminUser for this new branch
                final newAdmin = AdminUser(
                  id: 'ADM-${DateTime.now().millisecondsSinceEpoch}',
                  name: '$branchName Admin',
                  email: emailController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  role: AdminRole.officeAdmin,
                  branchName: branchName,
                  pin: pin,
                );
                
                await adminService.addAdmin(newAdmin);
                await adminService.refreshData();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _showPinConfirmation(branchName, pin, emailController.text.trim());
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Create Office & Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPinConfirmation(String branchName, String pin, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Office Created Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 20),
            Text('The branch $branchName and its admin account have been created.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
              child: Column(
                children: [
                  const Text('PERMANENT ACCESS PIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(pin, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Please share this PIN with the $branchName admin ($email). They can use it to log in and manage the branch.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final locations = adminService.officeLocations;
    final total = locations.length;
    final active = total; // Mocked

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
                _buildModernAppBar(),
                _buildStatsBanner(total, active),
                Expanded(
                  child: _loadingUsers 
                    ? Center(child: CircularProgressIndicator(color: _accentColor))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          final adminsCount = adminService.admins.where((a) => a.branchName == loc).length;
                          final usersCount = _allUsers.where((u) => (u['assignedOffice'] ?? '').toString() == loc).length;

                          return FadeInUp(
                            delay: Duration(milliseconds: 50 * index),
                            child: _buildOfficeTile(loc, adminsCount, usersCount, adminService),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLocation,
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Create New Office', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logistics Infrastructure',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'BRANCH & HUB MANAGEMENT',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.hub_rounded, color: _accentColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner(int total, int active) {
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
          _statItem('Total Hubs', total.toString(), Icons.location_city_rounded, Colors.white),
          _statItem('Active Status', '100%', Icons.check_circle_rounded, AppColors.success),
          _statItem('Operational', active.toString(), Icons.bolt_rounded, Colors.amber),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.6), size: 16),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
  Widget _buildOfficeTile(String loc, int adminsCount, int usersCount, AdminService adminService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showOfficeDetails(loc),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeDark]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                          Text('SabCargo Hub Network', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white24, size: 20),
                      onPressed: () => _handleEditOffice(loc, adminService),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                      onPressed: () => _handleRemoveOffice(loc, adminsCount, usersCount, adminService),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _officeStat(Icons.admin_panel_settings_rounded, 'Lead', adminsCount > 0 ? adminService.admins.firstWhere((a) => a.branchName == loc).name : 'Unassigned'),
                    _officeStat(Icons.groups_rounded, 'Staff', '$usersCount Active'),
                    _officeStat(Icons.verified_rounded, 'Status', 'Online', color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _officeStat(IconData icon, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.white24),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? Colors.white70)),
      ],
    );
  }

  Future<void> _handleEditOffice(String oldName, AdminService adminService) async {
    final nameController = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Branch Name'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Branch Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, nameController.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      await adminService.updateOfficeName(oldName, newName);
      await adminService.refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Branch renamed to $newName'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _handleRemoveOffice(String loc, int adminsCount, int usersCount, AdminService adminService) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove Branch?'),
        content: Text(
          adminsCount > 0 || usersCount > 0
              ? 'This branch currently has $adminsCount admin(s) and $usersCount user(s) assigned. Removing it will only hide it from lists; it does not automatically reassign users/admins.'
              : 'Are you sure you want to remove "$loc" from office locations?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;
    await adminService.removeOffice(loc);
    await adminService.refreshData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Branch removed from office locations.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
