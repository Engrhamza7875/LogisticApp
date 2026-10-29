import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive.dart';
import 'home_screen.dart';
import 'book_shipment_screen.dart';
import 'shipments_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    BookShipmentScreen(),
    ShipmentsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Enterprise Navy Sidebar for Web/Desktop
            Container(
              width: 250,
              color: AppColors.navy,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SABCARGO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Customer Portal',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  _buildSidebarItem(0, Icons.home_rounded, 'Home Dashboard'),
                  _buildSidebarItem(1, Icons.add_box_rounded, 'Book Shipment'),
                  _buildSidebarItem(2, Icons.track_changes_rounded, 'Track Cargo'),
                  _buildSidebarItem(3, Icons.person_rounded, 'My Profile'),
                  const Spacer(),
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Encrypted Session',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: AppColors.navShadow,
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomInset > 0 ? bottomInset : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, 'Home'),
          _navItem(1, Icons.add_box_rounded, 'Book'),
          _navItem(2, Icons.track_changes_rounded, 'Track'),
          _navItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.orange : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.orange : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
