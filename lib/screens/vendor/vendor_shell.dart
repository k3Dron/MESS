import 'package:flutter/material.dart';
import '../../widgets/floating_bottom_nav.dart';
import 'vendor_dashboard.dart';
import 'vendor_menu_editor.dart';
import 'vendor_billing.dart';
import 'vendor_notifications.dart';
import 'vendor_settings.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _currentIndex = 0;

  final _pages = const [
    VendorDashboard(),
    VendorMenuEditor(),
    VendorBilling(),
    VendorNotifications(),
    VendorSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          FloatingNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          FloatingNavItem(
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu_rounded,
            label: 'Menu',
          ),
          FloatingNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Bills',
          ),
          FloatingNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'Alerts',
          ),
          FloatingNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
