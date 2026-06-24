import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../service/api_service.dart';
import '../widgets/order_status_modal.dart';
import '../widgets/dialog_helper.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final TextEditingController _trackingController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

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
      // The backend /api/guest endpoint returns all orders.
      // We fetch them and search for the tracking number (name or id).
      final response = await _apiService.get('/guest');
      
      List<dynamic> orders = response['orders'] ?? [];
      
      // Find the order that matches the ID or Name
      var foundOrder = orders.firstWhere(
        (order) => order['id'].toString() == trackingNumber || order['name'] == trackingNumber,
        orElse: () => null,
      );

      if (foundOrder != null) {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => OrderStatusModal(orderData: foundOrder),
          );
        }
      } else {
        if (mounted) {
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
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.cyan),
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
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.magenta),
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
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.magenta, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              final message = messageController.text.trim();
              if (name.isEmpty || message.isEmpty) return;

              Navigator.pop(ctx);
              
              // We'll show a loading dialog instead
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.magenta)),
              );

              try {
                // Post to the public guest endpoint
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AZTracking'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.search_rounded,
                size: 100,
                color: AppTheme.cyan.withOpacity(0.5),
              ),
              const SizedBox(height: 30),
              Text(
                'Track Your Order',
                textAlign: TextAlign.center,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.keyBlack,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your order ID or tracking name below',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10045 or PosterPrint',
                  prefixIcon: Icon(Icons.local_printshop_rounded, color: AppTheme.magenta),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _trackOrder(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _trackOrder,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Track Order'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showDisclaimer,
                child: Text(
                  'Disclaimer & Info',
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFeedbackModal,
        backgroundColor: AppTheme.magenta,
        tooltip: 'Send Feedback',
        child: const Icon(Icons.feedback_rounded, color: Colors.white),
      ),
    );
  }
}

