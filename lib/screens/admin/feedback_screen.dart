import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/feedbacks');
      setState(() {
        _feedbacks = response['feedback'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load feedbacks: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateFeedbackModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Feedback', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter the feedback details below.',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              final message = messageController.text.trim();
              if (name.isEmpty || message.isEmpty) {
                DialogHelper.showErrorDialog(context, 'Validation Error', 'Please fill in all required fields properly.');
                return;
              }

              Navigator.pop(ctx);
              try {
                await _apiService.post('/feedbacks/store', body: {
                  'name': name,
                  'message': message,
                });
                _fetchFeedbacks();
                if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Feedback created successfully');
              } catch (e) {
                if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to create feedback: $e');
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showEditFeedbackModal(Map<String, dynamic> feedback) {
    final TextEditingController nameController = TextEditingController(text: feedback['name']);
    final TextEditingController messageController = TextEditingController(text: feedback['message']);
    final id = feedback['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Feedback', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              final message = messageController.text.trim();
              if (name.isEmpty || message.isEmpty) {
                DialogHelper.showErrorDialog(context, 'Validation Error', 'Please fill in all required fields properly.');
                return;
              }

              Navigator.pop(ctx);
              try {
                await _apiService.post('/feedbacks/$id/update', body: {
                  'name': name,
                  'message': message,
                });
                _fetchFeedbacks();
                if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Feedback updated successfully');
              } catch (e) {
                if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to update feedback: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFeedback(dynamic id) async {
    try {
      await _apiService.delete('/feedbacks/$id/delete');
      _fetchFeedbacks();
      if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Feedback deleted successfully');
    } catch (e) {
      if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                Text(
                  'Feedback List',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.adminText,
                  ),
                ),
                if (_apiService.hasPermission('create feedbacks'))
                  ElevatedButton.icon(
                    onPressed: _showCreateFeedbackModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
                : _feedbacks.isEmpty
                    ? Center(
                        child: Text(
                          'No feedbacks available',
                          style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : Card(
  elevation: 20,
  shadowColor: AppTheme.adminPrimary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListView.separated(
                          itemCount: _feedbacks.length,
                          separatorBuilder: (_, __) => const SizedBox(),
                          itemBuilder: (context, index) {
                            final feedback = _feedbacks[index];
                            final createdAt = feedback['created_at'] != null
                                ? DateTime.tryParse(feedback['created_at'])
                                : null;
                            final dateStr = createdAt != null
                                ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                                : "Unknown date";

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.adminPrimary.withOpacity(0.1),
                                child: const Icon(Icons.feedback_outlined, color: AppTheme.adminPrimary),
                              ),
                              title: Text(feedback['name'] ?? 'Unknown', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    feedback['message'] ?? '',
                                    style: GoogleFonts.nunito(color: AppTheme.adminText),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_apiService.hasPermission('edit feedbacks'))
                                    IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppTheme.adminPrimary, shadows: [Shadow(color: AppTheme.adminPrimary, blurRadius: 10, offset: const Offset(0, 6))]),
                                      onPressed: () => _showEditFeedbackModal(feedback),
                                      tooltip: 'Edit',
                                    ),
                                  if (_apiService.hasPermission('delete feedbacks'))
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded, color: Colors.redAccent, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10, offset: const Offset(0, 6))]),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Feedback?'),
                                            content: const Text('Are you sure you want to delete this feedback?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteFeedback(feedback['id']);
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Delete',
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
