import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import 'reset_pin_screen.dart';
import 'help_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _user = {'name': 'User', 'email': 'user@sabcargo.com'};
  Map<String, int> _stats = {'total': 0, 'active': 0, 'delivered': 0};
  String? _photoBase64;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getUserDetails();
      final stats = await ShipmentService.getStats();
      final photo = await AuthService.getUserPhoto();
      final isAdmin = await AuthService.isAdmin();
      if (mounted) {
        setState(() {
          _user = Map<String, dynamic>.from(user);
          _stats = stats;
          _photoBase64 = photo;
          _isAdmin = isAdmin;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.orange,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildStatsRow(),
              _buildActionsList(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          FadeInDown(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Builder(builder: (context) {
                      try {
                        if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
                          return Image.memory(base64Decode(_photoBase64!),
                              fit: BoxFit.cover);
                        }
                      } catch (_) {}
                      return Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.navy, size: 50),
                      );
                    }),
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            child: Column(
              children: [
                Text(
                  (_user['name'] ?? 'User').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    _user['email'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _statItem('TOTAL', _stats['total'] ?? 0, AppColors.navy),
          const SizedBox(width: 12),
          _statItem('ACTIVE', _stats['active'] ?? 0, AppColors.orange),
          const SizedBox(width: 12),
          _statItem('DELIVERED', _stats['delivered'] ?? 0, AppColors.success),
        ],
      ),
    );
  }

  Widget _statItem(String label, int val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              val.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ACCOUNT SETTINGS'),
          _actionTile(
            Icons.person_outline_rounded,
            'Personal Details',
            'Update your name and phone number',
            AppColors.navy,
            () => _showEditProfile(context),
          ),
          _actionTile(
            Icons.lock_outline_rounded,
            'Security & PIN',
            'Change your 6-digit access PIN',
            AppColors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResetPinScreen()),
            ),
          ),

          if (_isAdmin) ...[
            const SizedBox(height: 20),
            _sectionTitle('OPERATIONS HUB'),
            _actionTile(
              Icons.admin_panel_settings_rounded,
              'Admin Console',
              'Return to management workspace',
              AppColors.navy,
              () async {
                final role = await AuthService.getUserRole();
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    role == 'SuperAdmin' ? '/superadmin' : '/admin',
                  );
                }
              },
            ),
          ],

          const SizedBox(height: 20),
          _sectionTitle('SUPPORT & SECURITY'),
          _actionTile(
            Icons.help_outline_rounded,
            'Help Center',
            'FAQs, customer service & rates',
            AppColors.navy,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
          _actionTile(
            Icons.logout_rounded,
            'Logout Session',
            'Securely sign out of this device',
            AppColors.error,
            () => _showLogoutDialog(),
          ),
          _actionTile(
            Icons.delete_forever_rounded,
            'Delete Account',
            'Permanently remove user credentials',
            AppColors.error,
            () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FadeInUp(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              sub,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      await AuthService.updateUserPhoto(base64String);
      setState(() => _photoBase64 = base64String);
    }
  }

  void _showEditProfile(BuildContext context) {
    final nameCtrl = TextEditingController(text: _user['name']);
    final phoneCtrl = TextEditingController(text: _user['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppColors.navy),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.navy),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                await AuthService.updateUserProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  photo: _photoBase64,
                );
                if (mounted) {
                  setState(() {
                    _user['name'] = nameCtrl.text.trim();
                    _user['phone'] = phoneCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Update failed: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout Session?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit your active session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/pin-login', (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: const Text(
          'This action is permanent and cannot be undone. All your shipment history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AuthService.deleteAccount();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/pin-login', (r) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deletion failed: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
