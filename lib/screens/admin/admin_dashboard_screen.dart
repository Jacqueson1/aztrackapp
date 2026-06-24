import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../choose_role_screen.dart';
import '../../service/api_service.dart';

import 'user_management_screen.dart';
import 'role_screen.dart';
import 'permission_screen.dart';
import 'feedback_screen.dart';
import 'customer_screen.dart';
import 'status_screen.dart';
import 'orders_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final apiService = ApiService();
    if (apiService.hasPermission('view orders')) {
      _selectedIndex = 0;
    } else if (apiService.hasPermission('view customer')) {
      _selectedIndex = 1;
    } else if (apiService.hasPermission('view feedbacks')) {
      _selectedIndex = 2;
    } else if (apiService.hasPermission('view status')) {
      _selectedIndex = 3;
    } else if (apiService.hasPermission('view users')) {
      _selectedIndex = 4;
    } else if (apiService.hasPermission('view roles')) {
      _selectedIndex = 5;
    } else if (apiService.hasPermission('view permissions')) {
      _selectedIndex = 6;
    } else {
      _selectedIndex = -1;
    }
  }

  // The screens
  final List<Widget> _screens = [
    const OrdersScreen(), // Orders: index 0
    const CustomerScreen(), // Customer: index 1
    const FeedbackScreen(), // Feedback: index 2
    const StatusScreen(), // Status: index 3
    const UserManagementScreen(), // User Management: index 4
    const RoleScreen(), // Roles: index 5
    const PermissionScreen(), // Permissions: index 6
  ];

  void _onMenuTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    // Optionally call API logout endpoint
    final apiService = ApiService();
    try {
      await apiService.post('/logout');
    } catch (_) {
      // Ignore errors on logout
    } finally {
      apiService.clearAuthToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    Widget navBar = Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_printshop_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'AZTrack',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.keyBlack,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (ApiService().hasPermission('view orders'))
                  _buildNavItem(icon: Icons.shopping_cart_outlined, title: 'Orders', index: 0),
                if (ApiService().hasPermission('view customer'))
                  _buildNavItem(icon: Icons.people_outline, title: 'Customer', index: 1),
                if (ApiService().hasPermission('view feedbacks'))
                  _buildNavItem(icon: Icons.feedback_outlined, title: 'Feedback', index: 2),
                if (ApiService().hasPermission('view status'))
                  _buildNavItem(icon: Icons.info_outline, title: 'Status', index: 3),
                
                // User Dropdown section
                if (ApiService().hasPermission('view users') || ApiService().hasPermission('view roles') || ApiService().hasPermission('view permissions'))
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.manage_accounts_outlined, color: AppTheme.keyBlack),
                      title: Text('User', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      children: [
                        if (ApiService().hasPermission('view users'))
                          _buildNavItem(icon: Icons.person_outline, title: 'User List', index: 4, isSubItem: true),
                        if (ApiService().hasPermission('view roles'))
                          _buildNavItem(icon: Icons.badge_outlined, title: 'Roles', index: 5, isSubItem: true),
                        if (ApiService().hasPermission('view permissions'))
                          _buildNavItem(icon: Icons.security_outlined, title: 'Permissions', index: 6, isSubItem: true),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: isDesktop ? null : Drawer(child: navBar),
      body: SafeArea(
        child: Row(
          children: [
            // Left Navigation Bar
            if (isDesktop) navBar,
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Header
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (!isDesktop)
                          Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(Icons.menu, color: AppTheme.keyBlack),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.help_outline_rounded, color: AppTheme.keyBlack),
                          onPressed: () {},
                          tooltip: 'Help',
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.cyan,
                                  child: Icon(Icons.person, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    ApiService().currentUserName ?? 'Admin User',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.keyBlack,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          onPressed: _logout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  // Screen Body
                  Expanded(
                    child: _selectedIndex >= 0 && _selectedIndex < _screens.length
                        ? _screens[_selectedIndex]
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('Welcome! You have limited access. Please select an option from the menu, or contact an administrator if you need permissions.', textAlign: TextAlign.center),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String title, required int index, bool isSubItem = false}) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.cyan : AppTheme.keyBlack, size: isSubItem ? 20 : 24),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: isSelected ? AppTheme.cyan : AppTheme.keyBlack,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: isSubItem ? 14 : 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.cyan.withOpacity(0.1),
      onTap: () {
        _onMenuTapped(index);
        final isDesktop = MediaQuery.of(context).size.width > 800;
        if (!isDesktop) {
          Navigator.pop(context); // Close the drawer
        }
      },
    );
  }
}
