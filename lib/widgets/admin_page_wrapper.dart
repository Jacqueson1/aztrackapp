import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminPageWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.mPlusRounded1c(
            color: AppTheme.navy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: child,
    );
  }
}
