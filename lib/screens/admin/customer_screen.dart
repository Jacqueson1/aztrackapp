import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/customers');
      setState(() {
        _customers = response['customers'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load customers: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer(int id) async {
    try {
      await _apiService.delete('/customers/$id/delete');
      _fetchCustomers();
      if (mounted) {
        DialogHelper.showSuccessDialog(context, 'Success', 'Customer deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete customer: $e');
      }
    }
  }

  void _showCustomerModal({Map<String, dynamic>? customer}) {
    final isEditing = customer != null;
    final nameCtrl = TextEditingController(text: isEditing ? customer['name'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? customer['email'] : '');
    final phoneCtrl = TextEditingController(text: isEditing ? customer['phone']?.toString() : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Customer' : 'Create Customer', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please fill in the customer details below.',
                  style: GoogleFonts.nunito(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
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
                    'email': emailCtrl.text,
                    'phone': phoneCtrl.text,
                  };
                  
                  if (isEditing) {
                    await _apiService.post('/customers/${customer['id']}/update', body: body);
                  } else {
                    await _apiService.post('/customers/store', body: body);
                  }
                  _fetchCustomers();
                  if (mounted) DialogHelper.showSuccessDialog(context, 'Success', isEditing ? 'Customer updated successfully' : 'Customer created successfully');
                } catch (e) {
                  if (mounted) {
                    DialogHelper.showErrorDialog(context, 'Error', 'Failed to save customer: $e');
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
                  'Customer Management',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.adminText,
                  ),
                ),
                if (_apiService.hasPermission('create customer'))
                  ElevatedButton.icon(
                    onPressed: () => _showCustomerModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Customer'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
                : Card(
  elevation: 20,
  shadowColor: AppTheme.adminPrimary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) => const SizedBox(),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.adminPrimary.withOpacity(0.1),
                            child: Text(
                              customer['name'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${customer['name']} (ID: ${customer['id']})', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: Text('${customer['email']} | ${customer['phone'] ?? 'No Phone'}', style: GoogleFonts.nunito(color: Colors.grey.shade600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_apiService.hasPermission('edit customer'))
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: AppTheme.adminPrimary, shadows: [Shadow(color: AppTheme.adminPrimary, blurRadius: 10, offset: const Offset(0, 6))]),
                                  onPressed: () => _showCustomerModal(customer: customer),
                                  tooltip: 'Edit',
                                ),
                              if (_apiService.hasPermission('delete customer'))
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.redAccent, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10, offset: const Offset(0, 6))]),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Customer'),
                                        content: Text('Are you sure you want to delete ${customer['name']}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteCustomer(customer['id']);
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
