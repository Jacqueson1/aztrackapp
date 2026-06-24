import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/users');
      setState(() {
        _users = response['users'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load users: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      await _apiService.delete('/users/$id/delete');
      _fetchUsers();
      if (mounted) {
        DialogHelper.showSuccessDialog(context, 'Success', 'User deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete user: $e');
      }
    }
  }

  void _showUserModal({Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final nameCtrl = TextEditingController(text: isEditing ? user['name'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] : '');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Create User', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please fill in the user details below.',
                  style: GoogleFonts.nunito(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
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
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isEditing ? 'Password (leave blank to keep current)' : 'Password',
                  ),
                  obscureText: true,
                  validator: (v) => !isEditing && v!.isEmpty ? 'Required' : null,
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
                  };
                  if (passwordCtrl.text.isNotEmpty) {
                    body['password'] = passwordCtrl.text;
                  }
                  
                  if (isEditing) {
                    await _apiService.post('/users/${user['id']}/update', body: body);
                  } else {
                    await _apiService.post('/users/store', body: body);
                  }
                  _fetchUsers();
                  if (mounted) DialogHelper.showSuccessDialog(context, 'Success', isEditing ? 'User updated successfully' : 'User created successfully');
                } catch (e) {
                  if (mounted) {
                    DialogHelper.showErrorDialog(context, 'Error', 'Failed to save user: $e');
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
                  'User Management',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.keyBlack,
                  ),
                ),
                if (_apiService.hasPermission('create users'))
                  ElevatedButton.icon(
                    onPressed: () => _showUserModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
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
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cyan.withOpacity(0.1),
                            child: Text(
                              user['name'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user['name'], style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email'], style: GoogleFonts.nunito(color: Colors.grey.shade600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan),
                                onPressed: () => _showUserModal(user: user),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete User'),
                                      content: Text('Are you sure you want to delete ${user['name']}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteUser(user['id']);
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

