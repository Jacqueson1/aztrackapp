import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../choose_role_screen.dart';
import '../../service/api_service.dart';
import '../../widgets/admin_page_wrapper.dart';

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
  final ApiService _apiService = ApiService();
  int _customerCount = 0;
  int _orderCount = 0;
  int _userCount = 0;
  bool _isLoadingCounts = true;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchKPIs();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime time) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = time.hour > 12 ? (time.hour - 12).toString().padLeft(2, '0') : (time.hour == 0 ? '12' : time.hour.toString().padLeft(2, '0'));
    String minute = time.minute.toString().padLeft(2, '0');
    String second = time.second.toString().padLeft(2, '0');
    String ampm = time.hour >= 12 ? 'PM' : 'AM';
    String date = '${time.day} ${months[time.month - 1]} ${time.year}';
    return '$date  |  $hour:$minute:$second $ampm';
  }

  Future<void> _fetchKPIs() async {
    setState(() => _isLoadingCounts = true);
    try {
      if (_apiService.hasPermission('view customer')) {
        final custRes = await _apiService.get('/customers');
        _customerCount = (custRes['customers'] as List?)?.length ?? 0;
      }
      if (_apiService.hasPermission('view orders')) {
        final orderRes = await _apiService.get('/orders');
        _orderCount = (orderRes['orders'] as List?)?.length ?? 0;
      }
      if (_apiService.hasPermission('view users')) {
        final userRes = await _apiService.get('/users');
        _userCount = (userRes['users'] as List?)?.length ?? 0;
      }
    } catch (e) {
      // Ignore errors for KPI fetches
    } finally {
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  void _logout() async {
    try {
      await _apiService.post('/logout');
    } catch (_) {}
    _apiService.clearAuthToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
        (route) => false,
      );
    }
  }

  void _navigateTo(Widget screen, String title) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPageWrapper(title: title, child: screen),
      ),
    );
    _fetchKPIs();
  }

  void _showUsersSubModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.softGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text('User Management', style: GoogleFonts.mPlusRounded1c(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.adminText)),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  if (_apiService.hasPermission('view users'))
                    _buildGridCard('Users List', Icons.people_alt_rounded, Colors.orangeAccent, () {
                      Navigator.pop(context);
                      _navigateTo(const UserManagementScreen(), 'Users List');
                    }),
                  if (_apiService.hasPermission('view roles'))
                    _buildGridCard('Roles', Icons.badge_rounded, Colors.purpleAccent, () {
                      Navigator.pop(context);
                      _navigateTo(const RoleScreen(), 'Roles');
                    }),
                  if (_apiService.hasPermission('view permissions'))
                    _buildGridCard('Permissions', Icons.security_rounded, Colors.redAccent, () {
                      Navigator.pop(context);
                      _navigateTo(const PermissionScreen(), 'Permissions');
                    }),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppTheme.adminPrimary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.adminText),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickListModal(String title, Widget screen) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.only(top: 24),
          decoration: const BoxDecoration(
            color: AppTheme.softGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: GoogleFonts.mPlusRounded1c(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.adminText)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: screen),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back/sidebar icon
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: SvgPicture.asset(
            'lib/assets/images/FreeSample-Vectorizer-io-AZprintLogo-removebg-preview.svg',
            alignment: Alignment.centerLeft,
          ),
        ),
        title: Text(
          'AZTRACKING',
          style: GoogleFonts.mPlusRounded1c(
            color: AppTheme.adminText,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.adminPrimary),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info & Digital Clock
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelBlue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin, color: AppTheme.adminPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome back, ${_apiService.currentUserName ?? 'Admin'}',
                          style: GoogleFonts.nunito(
                            color: AppTheme.adminText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppTheme.adminText, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateTime(_currentTime),
                          style: GoogleFonts.mPlusRounded1c(
                            color: AppTheme.adminText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.space_dashboard_rounded, color: AppTheme.adminPrimary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Your Dashboard',
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.adminText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Overview of your key metrics and quick access to management tools.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              
              // The KPI Black Box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Deep black/grey
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4), 
                      blurRadius: 25, 
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Customer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Customer', style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _isLoadingCounts
                              ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                              : Text('$_customerCount', style: GoogleFonts.mPlusRounded1c(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _showQuickListModal('Customers', const CustomerScreen()),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Text('View', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Column 2: Order
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Order', style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _isLoadingCounts
                              ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                              : Text('$_orderCount', style: GoogleFonts.mPlusRounded1c(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _showQuickListModal('Orders', const OrdersScreen()),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Text('View', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Column 3: Users
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Users', style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _isLoadingCounts
                              ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                              : Text('$_userCount', style: GoogleFonts.mPlusRounded1c(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _showQuickListModal('Users', const UserManagementScreen()),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Text('View', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Grid Navigation Title
              Text(
                'Quick Access',
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.adminText,
                ),
              ),
              const SizedBox(height: 16),

              // Grid Navigation
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  if (_apiService.hasPermission('view orders'))
                    _buildGridCard('Order', Icons.shopping_cart_rounded, Colors.amber.shade600, () => _navigateTo(const OrdersScreen(), 'Order Management')),
                  if (_apiService.hasPermission('view customer'))
                    _buildGridCard('Customer', Icons.people_alt_rounded, AppTheme.adminPrimary, () => _navigateTo(const CustomerScreen(), 'Customer Management')),
                  if (_apiService.hasPermission('view feedbacks'))
                    _buildGridCard('Feedback', Icons.feedback_rounded, AppTheme.accentGreen, () => _navigateTo(const FeedbackScreen(), 'Feedbacks')),
                  if (_apiService.hasPermission('view status'))
                    _buildGridCard('Status', Icons.info_rounded, Colors.blueAccent, () => _navigateTo(const StatusScreen(), 'Status Management')),
                  if (_apiService.hasPermission('view users') || _apiService.hasPermission('view roles') || _apiService.hasPermission('view permissions'))
                    _buildGridCard('Users', Icons.manage_accounts_rounded, Colors.orangeAccent, _showUsersSubModal),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
