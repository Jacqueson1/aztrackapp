import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _statuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  Future<void> _fetchStatuses() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/statuses');
      setState(() {
        _statuses = response['statuses'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load statuses: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStatus(int id) async {
    try {
      await _apiService.delete('/statuses/$id/delete');
      _fetchStatuses();
      if (mounted) {
        DialogHelper.showSuccessDialog(context, 'Success', 'Status deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete status: $e');
      }
    }
  }

  void _showStatusModal({Map<String, dynamic>? status}) {
    final isEditing = status != null;
    final nameCtrl = TextEditingController(text: isEditing ? status['name'] : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Status' : 'Create Status', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please fill in the status details below.',
                  style: GoogleFonts.nunito(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Status Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  final body = {
                    'name': nameCtrl.text,
                  };
                  
                  if (isEditing) {
                    await _apiService.post('/statuses/${status['id']}/update', body: body);
                  } else {
                    await _apiService.post('/statuses/store', body: body);
                  }
                  _fetchStatuses();
                  if (mounted) DialogHelper.showSuccessDialog(context, 'Success', isEditing ? 'Status updated successfully' : 'Status created successfully');
                } catch (e) {
                  if (mounted) {
                    DialogHelper.showErrorDialog(context, 'Error', 'Failed to save status: $e');
                  }
                }
              } else {
                DialogHelper.showErrorDialog(context, 'Validation Error', 'Please fill in all required fields properly.');
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
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
                  'Status Management',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.keyBlack,
                  ),
                ),
                if (_apiService.hasPermission('create status'))
                  ElevatedButton.icon(
                    onPressed: () => _showStatusModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Status'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan))
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      itemCount: _statuses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final status = _statuses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cyan.withOpacity(0.1),
                            child: Text(
                              status['name'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(status['name'], style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_apiService.hasPermission('edit status'))
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan),
                                  onPressed: () => _showStatusModal(status: status),
                                  tooltip: 'Edit',
                                ),
                              if (_apiService.hasPermission('delete status'))
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Status'),
                                        content: Text('Are you sure you want to delete ${status['name']}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteStatus(status['id']);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Delete',
                                ),
                            ],
                          ),
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
