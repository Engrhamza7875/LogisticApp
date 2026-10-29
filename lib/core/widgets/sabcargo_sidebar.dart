import 'package:flutter/material.dart';
import '../colors.dart';
import '../../services/auth_service.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;
  final String? badge;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    this.badge,
  });
}

class SabCargoSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<SidebarItem> items;
  final String roleTitle;
  final String? userEmail;

  const SabCargoSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    required this.roleTitle,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleTitle.toUpperCase(),
                        style: const TextStyle(
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
          const SizedBox(height: 16),

          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => onItemSelected(item.index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white24 : AppColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer User Profile & Logout
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.orange.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppColors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userEmail ?? 'Authenticated User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Secure Session Active',
                        style: TextStyle(color: AppColors.success, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/pin-login', (r) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
