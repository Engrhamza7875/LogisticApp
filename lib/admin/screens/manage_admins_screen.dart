import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/colors.dart';
import '../models/admin_user.dart';
import 'package:animate_do/animate_do.dart';
import '../services/admin_service.dart';
import '../widgets/role_guard.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
    });
  }

  void _removeAdmin(String id) async {
    final role = await AuthService.getUserRole();
    if (role != 'SuperAdmin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied: Only SuperAdmin can revoke admin access.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    context.read<AdminService>().removeAdmin(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin removed successfully'), backgroundColor: AppColors.error),
    );
  }

  Future<void> _toggleAdminActive(AdminUser admin) async {
    try {
      final newState = await ApiService.toggleAdminActive(admin.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newState ? '${admin.name} enabled' : '${admin.name} disabled'),
          backgroundColor: newState ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        context.read<AdminService>().refreshData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _resetAdminPin(AdminUser admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Admin PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('A new PIN will be sent to ${admin.email}. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    try {
      await ApiService.resetAdminPin(admin.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PIN reset email sent to ${admin.email}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  void _addAdmin() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String phoneNumber = '';
    String? selectedBranch;
    final adminService = context.read<AdminService>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Add Office Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADMIN DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  initialCountryCode: 'SA',
                  onChanged: (phone) => phoneNumber = phone.completeNumber,
                ),
                const SizedBox(height: 16),
                const Text('ASSIGN LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  hint: const Text('Select Office Location'),
                  value: selectedBranch,
                  items: adminService.officeLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                  onChanged: (val) => setModalState(() => selectedBranch = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && selectedBranch != null) {
                  // Generate a 6-digit PIN
                  final pin = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
                  
                  final newAdmin = AdminUser(
                    id: 'ADM-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    email: emailController.text,
                    phoneNumber: phoneNumber,
                    role: AdminRole.officeAdmin,
                    branchName: selectedBranch!,
                    pin: pin,
                  );
                  
                  // Add admin via service
                  await adminService.addAdmin(newAdmin);
                  
                  // Show the generated PIN to the SuperAdmin
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showPinConfirmation(newAdmin.name, pin);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Create Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinConfirmation(String adminName, String pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Admin Created Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 20),
            Text('A new account has been created for $adminName.', textAlign: TextAlign.center),
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
            const Text('Please share this PIN with the admin. They can use it to log in and can change it later via recovery.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  void _editAdmin(AdminUser admin) {
    final nameController = TextEditingController(text: admin.name);
    final emailController = TextEditingController(text: admin.email);
    final pinController = TextEditingController(text: admin.pin ?? '');
    String phoneNumber = admin.phoneNumber;
    String? selectedBranch = admin.branchName;
    final adminService = context.read<AdminService>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Update Admin Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameController, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _field(emailController, 'Email Address', Icons.email_outlined, readOnly: true),
                const SizedBox(height: 12),
                IntlPhoneField(
                  initialValue: phoneNumber.isNotEmpty ? phoneNumber.replaceAll(RegExp(r'\D'), '') : '',
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  initialCountryCode: 'SA',
                  onChanged: (phone) => phoneNumber = phone.completeNumber,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration: InputDecoration(
                    labelText: 'Assigned Branch',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: [
                    if (selectedBranch != null && !adminService.officeLocations.contains(selectedBranch))
                      DropdownMenuItem(value: selectedBranch, child: Text('$selectedBranch (Inactive)', style: const TextStyle(fontSize: 13, color: Colors.red))),
                    ...adminService.officeLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13))))
                  ],
                  onChanged: (v) => setD(() => selectedBranch = v),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SECURITY CREDENTIALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(pinController, 'Account PIN', Icons.lock_outline_rounded, hint: 'Leave empty to keep current'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Generate New PIN',
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary.withOpacity(0.1)),
                      icon: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                      onPressed: () {
                        setD(() {
                          pinController.text = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && selectedBranch != null) {
                  final updatedAdmin = AdminUser(
                    id: admin.id,
                    name: nameController.text,
                    email: admin.email,
                    phoneNumber: phoneNumber,
                    role: admin.role,
                    branchName: selectedBranch!,
                    pin: pinController.text.isNotEmpty ? pinController.text : admin.pin,
                    isActive: admin.isActive,
                    permissions: admin.permissions,
                  );
                  
                  await adminService.addAdmin(updatedAdmin);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool readOnly = false, String? hint}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.transparent,
      ),
    );
  }

  void _showPermissionsModal(AdminUser admin) {
    final allPermissions = [
      {'id': 'view_shipments', 'label': 'View Shipments'},
      {'id': 'create_shipments', 'label': 'Create Shipments'},
      {'id': 'update_status', 'label': 'Update Status'},
      {'id': 'manage_users', 'label': 'Manage Users'},
      {'id': 'broadcast_notify', 'label': 'Broadcast Notifications'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Permissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Admin: ${admin.name}', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ...allPermissions.map((p) {
              final isEnabled = admin.permissions.contains(p['id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isEnabled ? null : () => context.read<AdminService>().togglePermission(admin.id, p['id']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            disabledBackgroundColor: Colors.grey[200],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Allow', style: TextStyle(color: isEnabled ? Colors.white : Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: !isEnabled ? null : () => context.read<AdminService>().togglePermission(admin.id, p['id']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            disabledBackgroundColor: Colors.grey[200],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Deny', style: TextStyle(color: !isEnabled ? Colors.white : Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final admins = adminService.admins;
    final total = admins.length;
    final active = admins.where((a) => a.isActive).length;
    final superAdmins = admins.where((a) => a.role == AdminRole.superAdmin).length;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Background Gradient
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
                _buildStatsBanner(total, active, superAdmins),
                _buildSearchAndAdd(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: adminService.refreshData,
                    color: _accentColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: admins.length,
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          child: _buildAdminTile(admin),
                        );
                      },
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrative Governance',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'SYSTEM PERSONNEL & PRIVILEGES',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.verified_user_rounded, color: _accentColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner(int total, int active, int superAdmins) {
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
          _statItem('Total', total.toString(), Icons.people_rounded, Colors.white),
          _statItem('Active', active.toString(), Icons.check_circle_rounded, AppColors.success),
          _statItem('Super', superAdmins.toString(), Icons.stars_rounded, Colors.amber),
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

  Widget _buildSearchAndAdd() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const TextField(
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search administrator...',
                  hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  icon: Icon(Icons.search_rounded, color: Colors.black38, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final role = await AuthService.getUserRole();
              if (role != 'SuperAdmin') {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission denied: SuperAdmin only.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              _addAdmin();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeDark]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(AdminUser admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: admin.isActive ? Colors.white.withOpacity(0.1) : AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: admin.role == AdminRole.superAdmin
                        ? [const Color(0xFFFBBF24), const Color(0xFFD97706)]
                        : admin.isActive
                            ? [AppColors.orange, AppColors.orangeDark]
                            : [Colors.grey[700]!, Colors.grey[800]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (admin.role == AdminRole.superAdmin ? Colors.amber : AppColors.orange).withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Text(admin.name[0].toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(admin.name, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis, maxLines: 1),
                        ),
                        const SizedBox(width: 8),
                        if (admin.role == AdminRole.superAdmin)
                          const Icon(Icons.verified_rounded, color: Colors.amber, size: 14),
                      ],
                    ),
                    Text(admin.email, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPermissionsModal(admin),
                icon: Icon(Icons.shield_outlined, color: _accentColor, size: 20),
                tooltip: 'Permissions',
              ),
              _buildActionMenu(admin),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _adminDetail(Icons.phone_outlined, 'Phone', admin.phoneNumber.isNotEmpty ? admin.phoneNumber : 'N/A')),
              const SizedBox(width: 4),
              Expanded(child: _adminDetail(Icons.business_rounded, 'Office', admin.branchName)),
              const SizedBox(width: 4),
              Expanded(child: _adminDetail(Icons.radio_button_checked_rounded, 'Status', admin.isActive ? 'Online' : 'Locked', 
                  color: admin.isActive ? AppColors.success : AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminDetail(IconData icon, String label, String value, {Color? color}) {
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
        Text(value, 
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: color ?? Colors.white70
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ],
    );
  }

  Widget _buildActionMenu(AdminUser admin) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'edit') _editAdmin(admin);
        if (val == 'remove') _removeAdmin(admin.id);
        if (val == 'toggle') _toggleAdminActive(admin);
        if (val == 'reset_pin') _resetAdminPin(admin);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Details'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(admin.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  size: 18, color: admin.isActive ? AppColors.warning : AppColors.success),
              const SizedBox(width: 8),
              Text(admin.isActive ? 'Deactivate' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reset_pin',
          child: Row(
            children: [
              Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Reset Password'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Revoke Access', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
    );
  }

}
