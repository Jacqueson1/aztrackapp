import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../service/api_service.dart';
import '../widgets/order_status_modal.dart';
import '../widgets/dialog_helper.dart';
import 'choose_role_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final TextEditingController _trackingController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _foundOrder;

  Future<void> _trackOrder() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      DialogHelper.showErrorDialog(context, 'Validation Error', 'Please enter a tracking number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/guest');
      
      List<dynamic> orders = response['orders'] ?? [];
      
      var foundOrder = orders.firstWhere(
        (order) => order['id'].toString() == trackingNumber || order['name'] == trackingNumber,
        orElse: () => null,
      );

      if (foundOrder != null) {
        if (mounted) {
          setState(() {
            _foundOrder = foundOrder;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _foundOrder = null;
          });
          DialogHelper.showErrorDialog(context, 'Not Found', 'Order not found. Please check your tracking number.');
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to fetch tracking data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Disclaimer',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.slateBlue),
        ),
        content: Text(
          'Tracking updates may take up to 24 hours to reflect on this system. '
          'For any urgent queries regarding your print order, please contact our support.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Customer Feedback',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.slateBlue),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We value your feedback. Please let us know your thoughts!',
                style: GoogleFonts.nunito(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.navy),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.nunito(color: AppTheme.slateBlue, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.slateBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.navy),
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: GoogleFonts.nunito(color: AppTheme.slateBlue, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.slateBlue, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.slateBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              final message = messageController.text.trim();
              if (name.isEmpty || message.isEmpty) return;

              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.slateBlue)),
              );

              try {
                await _apiService.post('/guest/store', body: {
                  'name': name,
                  'message': message,
                });
                if (mounted) Navigator.pop(context); // pop loading
                if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Thank you! Feedback submitted successfully.');
              } catch (e) {
                if (mounted) Navigator.pop(context); // pop loading
                if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to submit feedback: $e');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background for Trackify style
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
              (route) => false,
            );
          },
        ),
        title: Row(
          children: [
            SvgPicture.asset(
              'lib/assets/images/FreeSample-Vectorizer-io-AZprintLogo-removebg-preview.svg',
              height: 30,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AZTracking',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slateBlue,
                  ),
                ),
                Text(
                  'Delivering Trust, Every Step.',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _showDisclaimer,
            child: Text(
              'Disclaimer',
              style: GoogleFonts.nunito(
                color: AppTheme.slateBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              AppTheme.softGrey,
              AppTheme.pastelBlue.withOpacity(0.4),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order\nTracking System',
                          style: GoogleFonts.mPlusRounded1c(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Track your orders in real-time and stay updated on every step of the delivery journey.',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_shipping_rounded,
                          size: 60,
                          color: AppTheme.slateBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Search Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.slateBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.pastelBlue.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.slateBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter your Order ID /\nTracking Number',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _trackingController,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.navy),
                      decoration: InputDecoration(
                        hintText: 'e.g. TRK-123456789',
                        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.print_outlined, color: Colors.grey),
                        suffixIcon: _foundOrder != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _trackingController.clear();
                                  setState(() => _foundOrder = null);
                                },
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.slateBlue, width: 2),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _trackOrder(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.slateBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _trackOrder,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Track Order',
                                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 24),

              // Search Results (if found)
              if (_foundOrder != null)
                AnimatedOpacity(
                  opacity: _foundOrder != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: OrderStatusModal(orderData: _foundOrder!, isInline: true),
                  ),
                ),

              // Info Sections
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppTheme.slateBlue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your tracking information is secure and private.',
                        style: GoogleFonts.nunito(
                          color: AppTheme.slateBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.slateBlue.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.slateBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your tracking number and get real-time updates on your order status.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Feedback Button
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.slateBlue,
                    side: const BorderSide(color: AppTheme.slateBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _showFeedbackModal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Feedback',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
