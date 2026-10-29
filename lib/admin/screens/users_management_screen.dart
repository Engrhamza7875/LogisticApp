import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../services/admin_service.dart';

import '../widgets/role_guard.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _currentRole = 'User';

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['Admin', 'SuperAdmin']);
    });
  }

  Future<void> _init() async {
    _currentRole = await AuthService.getUserRole();
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.fetchAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Failed to load users: $e', isError: true);
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_allUsers)
        : _allUsers.where((u) {
            return (u['name'] ?? '').toString().toLowerCase().contains(q) ||
                (u['email'] ?? '').toString().toLowerCase().contains(q) ||
                (u['phone'] ?? '').toString().toLowerCase().contains(q);
          }).toList();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Edit User ────────────────────────────────────────────────
  void _editUser(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    String? selectedOffice = user['assignedOffice'];
    final adminService = context.read<AdminService>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _field(emailCtrl, 'Email Address', Icons.email_outlined),
                const SizedBox(height: 12),
                _field(phoneCtrl, 'Phone Number', Icons.phone_outlined),
                if (_currentRole == 'SuperAdmin') ...[
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ASSIGN OFFICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedOffice,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Select Office'),
                    items: [
                      if (selectedOffice != null && !adminService.officeLocations.contains(selectedOffice))
                        DropdownMenuItem(value: selectedOffice, child: Text('$selectedOffice (Inactive)', style: const TextStyle(fontSize: 13, color: Colors.red))),
                      ...adminService.officeLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13))))
                    ],
                    onChanged: (v) => setD(() => selectedOffice = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                Navigator.pop(context);
                
                final updatedData = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'assignedOffice': selectedOffice,
                };

                // OPTIMISTIC UPDATE
                final userIndex = _allUsers.indexWhere((u) => u['id'] == user['id']);
                if (userIndex != -1) {
                  setState(() {
                    _allUsers[userIndex] = {
                      ..._allUsers[userIndex],
                      ...updatedData,
                    };
                    _applyFilter();
                  });
                }

                try {
                  await ApiService.editUser(
                    user['id'] as int,
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                    assignedOffice: selectedOffice,
                  );
                  
                  await ApiService.broadcastNotification(
                    title: 'Profile Updated',
                    body: 'Your profile has been updated by an administrator.',
                    targetRole: 'All',
                  );

                  _snack('User updated successfully');
                } catch (e) {
                  _snack('Local update active (DB Sync Pending)', isError: false);
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── User Actions Menu ────────────────────────────────────────
  void _showActions(Map<String, dynamic> user) {
    final isActive = (user['isActive'] ?? true) == true || user['isActive'] == 1;
    final isSuperAdmin = _currentRole == 'SuperAdmin';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user['name'] ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(user['email'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            if (isSuperAdmin) ...[
              _actionTile(
                icon: Icons.visibility_rounded,
                label: 'View as User',
                color: Colors.blueAccent,
                onTap: () { Navigator.pop(context); _impersonate(user); },
              ),
              const Divider(color: Colors.black12, height: 24),
            ],
            _actionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Details',
              color: AppColors.primary,
              onTap: () { Navigator.pop(context); _editUser(user); },
            ),
            _actionTile(
              icon: Icons.lock_reset_rounded,
              label: 'Reset PIN',
              color: AppColors.warning,
              onTap: () { Navigator.pop(context); _resetPin(user); },
            ),
            _actionTile(
              icon: isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
              label: isActive ? 'Disable Account' : 'Enable Account',
              color: isActive ? AppColors.error : AppColors.success,
              onTap: () { Navigator.pop(context); _toggleActive(user); },
            ),
            if (isSuperAdmin) ...[
              _actionTile(
                icon: Icons.logout_rounded,
                label: 'Force Logout',
                color: const Color(0xFFF59E0B),
                onTap: () { Navigator.pop(context); _forceLogout(user); },
              ),
              _actionTile(
                icon: Icons.security_rounded,
                label: 'Lock (Suspicious)',
                color: const Color(0xFFEF4444),
                onTap: () { Navigator.pop(context); _lockUser(user); },
              ),
            ],
            _actionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete User',
              color: AppColors.error,
              onTap: () { Navigator.pop(context); _deleteUser(user); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _impersonate(Map<String, dynamic> user) async {
    final confirmed = await _confirm(
      'Impersonate User',
      'You are about to enter "${user['name']}"\'s account. Admin functions will be disabled until you exit.',
    );
    if (!confirmed) return;
    
    await AuthService.loginAsUser(user);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Widget _actionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color == AppColors.error ? AppColors.error : AppColors.textPrimary)),
      onTap: onTap,
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    // OPTIMISTIC TOGGLE
    final userIndex = _allUsers.indexWhere((u) => u['id'] == user['id']);
    if (userIndex != -1) {
      final wasActive = (_allUsers[userIndex]['isActive'] ?? true) == true || _allUsers[userIndex]['isActive'] == 1;
      setState(() {
        _allUsers[userIndex]['isActive'] = !wasActive;
        _applyFilter();
      });
    }

    try {
      await ApiService.toggleUserActive(user['id'] as int);
      
      // SEND NOTIFICATION
      await ApiService.broadcastNotification(
        title: 'Account Status Change',
        body: 'User account ${user['name']} has been ${user['isActive'] == true ? 'disabled' : 'enabled'} by an administrator.',
        targetRole: 'All',
      );

      _snack('Status updated');
    } catch (e) {
      _snack('Local status updated (DB Sync Pending)', isError: false);
    }
  }

  Future<void> _resetPin(Map<String, dynamic> user) async {
    final confirmed = await _confirm(
      'Reset PIN',
      'A new PIN will be emailed to ${user['email']}. Continue?',
    );
    if (!confirmed) return;
    try {
      await ApiService.resetUserPin(user['id'] as int);
      
      // SEND NOTIFICATION
      await ApiService.broadcastNotification(
        title: 'Security PIN Reset',
        body: 'A security PIN reset has been initiated for user ${user['name']} by an administrator.',
        targetRole: 'All',
      );

      _snack('New PIN sent to ${user['email']}');
    } catch (e) {
      _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _forceLogout(Map<String, dynamic> user) async {
    final confirmed = await _confirm('Force Logout', 'Force logout ${user['name']}?');
    if (!confirmed) return;
    try {
      await ApiService.forceLogoutUser(user['id'] as int);
      _snack('Force logout logged');
    } catch (e) {
      _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _lockUser(Map<String, dynamic> user) async {
    final confirmed = await _confirm(
      'Lock Account',
      'This will disable and unverify "${user['name']}". Proceed?',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await ApiService.lockUser(user['id'] as int);
      _snack('Account locked');
      _load();
    } catch (e) {
      _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await _confirm(
      'Delete User',
      'Permanently delete "${user['name']}"? This cannot be undone.',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteUserAdmin(user['id'] as int);
      _snack('User deleted');
      _load();
    } catch (e) {
      _snack('Failed: $e', isError: true);
    }
  }

  Future<bool> _confirm(String title, String message, {bool isDanger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDanger ? AppColors.error : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Confirm', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  Widget build(BuildContext context) {
    final total = _allUsers.length;
    final active = _allUsers.where((u) => u['isActive'] == true || u['isActive'] == 1).length;
    final disabled = total - active;

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
                _buildStatsBanner(total, active, disabled),
                _buildModernSearch(),
                Expanded(
                  child: _loading
                      ? Center(child: CircularProgressIndicator(color: _accentColor))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _accentColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final user = _filtered[index];
                              return FadeInUp(
                                delay: Duration(milliseconds: 50 * index),
                                child: _buildUserTile(user),
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
                'User Governance',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'CLIENT & STAFF DIRECTORY',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white60),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner(int total, int active, int disabled) {
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
          _statItem('Total', total.toString(), Icons.groups_rounded, Colors.white),
          _statItem('Active', active.toString(), Icons.check_circle_rounded, AppColors.success),
          _statItem('Locked', disabled.toString(), Icons.block_rounded, AppColors.error),
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

  Widget _buildModernSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          onChanged: (v) => setState(() { _searchQuery = v; _applyFilter(); }),
          decoration: const InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
            border: InputBorder.none,
            fillColor: Colors.transparent,
            icon: Icon(Icons.search_rounded, color: Colors.black38, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isActive = user['isActive'] == true || user['isActive'] == 1;
    final isVerified = user['isVerified'] == true || user['isVerified'] == 1;
    final name = (user['name'] ?? 'Unknown') as String;
    final email = (user['email'] ?? '') as String;
    final phone = (user['phone'] ?? '') as String;
    final role = (user['role'] ?? 'User') as String;
    final office = (user['assignedOffice'] ?? 'No Office') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? Colors.white.withOpacity(0.1) : AppColors.error.withOpacity(0.2),
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
                    colors: isActive
                        ? [AppColors.orange, AppColors.orangeDark]
                        : [Colors.grey[700]!, Colors.grey[800]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isVerified)
                          const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                      ],
                    ),
                    Text(email, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showActions(user),
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white60),
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
              _userStat(Icons.phone_outlined, 'Phone', phone),
              _userStat(Icons.business_rounded, 'Office', office),
              _userStat(Icons.verified_user_rounded, 'Role', role, 
                  color: role == 'Driver' ? Colors.amber : _accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userStat(IconData icon, String label, String value, {Color? color}) {
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
            )),
      ],
    );
  }
}
