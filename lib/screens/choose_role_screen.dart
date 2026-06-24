import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'customer_main_screen.dart';
import 'login_screen.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 2.5,
                  child: SvgPicture.asset(
                    'lib/assets/images/untitled_design_1.svg',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'lib/assets/images/FreeSample-Vectorizer-io-AZprintLogo-removebg-preview.svg',
                  height: 60,
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome to AZTracking',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slateBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Please select your role to continue',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 50),
                _buildRoleButton(
                  context: context,
                  title: 'Customer',
                  subtitle: 'Track your print orders',
                  icon: Icons.person_rounded,
                  color: AppTheme.slateBlue,
                  isGradient: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildRoleButton(
                  context: context,
                  title: 'Admin / Worker',
                  subtitle: 'Manage orders and system',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppTheme.adminPrimary,
                  isGradient: true,
                  isAdmin: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isGradient = false,
    bool isAdmin = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAdmin ? AppTheme.adminPrimary : AppTheme.slateBlue,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isAdmin ? AppTheme.adminPrimary.withOpacity(0.4) : AppTheme.slateBlue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isAdmin ? AppTheme.adminPrimary : AppTheme.slateBlue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isAdmin ? AppTheme.adminPrimary : AppTheme.slateBlue,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? AppTheme.adminPrimary : AppTheme.slateBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isAdmin ? AppTheme.adminPrimary : AppTheme.slateBlue,
            ),
          ],
          ),
      ),
    );
  }
}
