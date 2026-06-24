import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  List<dynamic> _availableRoles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final userRes = await _apiService.get('/users');
      final roleRes = await _apiService.get('/roles');
      setState(() {
        _users = userRes['users'] ?? [];
        _availableRoles = roleRes['roles'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRoleModal(Map<String, dynamic> user) {
    if (_availableRoles.isEmpty) {
      DialogHelper.showErrorDialog(context, 'No Roles', 'No roles available to assign. Create them in Permissions screen.');
      return;
    }

    String currentRole = _availableRoles[0]['name']; // Default to first available
    if (user['roles'] != null && (user['roles'] as List).isNotEmpty) {
      currentRole = user['roles'][0]['name'];
    }

    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateModal) {
          return AlertDialog(
            title: Text('Assign Role to ${user['name']}', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select the role for this user.',
                  style: GoogleFonts.nunito(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ..._availableRoles.map((role) {
                  return RadioListTile<String>(
                    title: Text(role['name'].toString().toUpperCase()),
                    value: role['name'],
                    groupValue: selectedRole,
                    onChanged: (val) => setStateModal(() => selectedRole = val!),
                    activeColor: role['name'] == 'admin' ? AppTheme.adminPrimary : AppTheme.adminPrimary,
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _apiService.post('/users/${user['id']}/update', body: {
                      'roles': [selectedRole],
                    });
                    _fetchData();
                    if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Role assigned successfully');
                  } catch (e) {
                    if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to assign role: $e');
                  }
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String roleName) {
    Color badgeColor = roleName.toLowerCase() == 'admin' ? Colors.redAccent : AppTheme.adminPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        roleName.toUpperCase(),
        style: GoogleFonts.nunito(
          color: badgeColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
          Text(
            'Role Assignment',
            style: GoogleFonts.mPlusRounded1c(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.adminText,
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
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        String primaryRole = 'No Role';
                        if (user['roles'] != null && (user['roles'] as List).isNotEmpty) {
                          primaryRole = user['roles'][0]['name'];
                        }

                        return ListTile(
                          onTap: () => _showRoleModal(user),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.adminPrimary.withOpacity(0.1),
                            child: const Icon(Icons.badge_outlined, color: AppTheme.adminPrimary),
                          ),
                          title: Text(user['name'], style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email'], style: GoogleFonts.nunito(color: Colors.grey.shade600)),
                          trailing: _buildRoleBadge(primaryRole),
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


