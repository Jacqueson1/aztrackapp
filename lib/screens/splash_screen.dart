import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'choose_role_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Wait for 3 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Company Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.local_printshop_rounded,
                size: 80,
                color: AppTheme.magenta,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'AZTracking',
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppTheme.cyan,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Print. Your Way.',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 50),
            // Loading Animation
            SizedBox(
              height: 100,
              // Fallback to CircularProgressIndicator if network is down or URL is invalid
              child: Lottie.network(
                'https://assets2.lottiefiles.com/packages/lf20_tijmpky4.json', // Box delivery animation
                errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(
                  color: AppTheme.yellow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
