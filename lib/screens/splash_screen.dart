import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: AppTheme.softGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stacked Logos
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
              height: 80,
            ),
            const SizedBox(height: 30),
            Text(
              'AZTRACKING : Order Tracking System',
              textAlign: TextAlign.center,
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.slateBlue,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Delivering Trust, Every Step',
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
                  color: AppTheme.pastelBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
