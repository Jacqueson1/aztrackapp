import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _roles = [];
  List<dynamic> _allPermissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final rolesRes = await _apiService.get('/roles');
      final permsRes = await _apiService.get('/permissions');
      
      setState(() {
        _roles = rolesRes['roles'] ?? [];
        // Extract permission names if available, else fallback to hardcoded if API is empty
        if (permsRes['permissions'] != null && (permsRes['permissions'] as List).isNotEmpty) {
          _allPermissions = permsRes['permissions'];
        } else {
          // Fallback to the 28 known permissions
          final names = [
            'create users', 'edit users', 'delete users', 'view users',
            'create roles', 'edit roles', 'delete roles', 'view roles',
            'create permissions', 'edit permissions', 'delete permissions', 'view permissions',
            'create orders', 'edit orders', 'delete orders', 'view orders',
            'create customer', 'edit customer', 'delete customer', 'view customer',
            'create feedbacks', 'edit feedbacks', 'delete feedbacks', 'view feedbacks',
            'create status', 'edit status', 'delete status', 'view status'
          ];
          _allPermissions = names.map((n) => {'name': n}).toList();
        }
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to load data: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateRoleModal() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create New Role', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Role Name',
            hintText: 'e.g. Worker, Manager',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyan, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                DialogHelper.showErrorDialog(context, 'Validation Error', 'Please enter a role name.');
                return;
              }

              Navigator.pop(ctx);
              try {
                await _apiService.post('/roles/store', body: {
                  'name': name,
                  'guard_name': 'sanctum', // Setting to sanctum as default for API usage
                });
                _fetchData();
                if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Role "$name" created successfully');
              } catch (e) {
                if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to create role: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPermissionModal(Map<String, dynamic> role) {
    // Collect currently assigned permissions
    final currentPermsList = role['permissions'] as List? ?? [];
    final currentPermNames = currentPermsList.map((p) => p['name'].toString()).toSet();

    // Group all permissions by entity
    final groupedPerms = <String, List<String>>{};
    for (var p in _allPermissions) {
      final name = p['name'].toString();
      final parts = name.split(' ');
      if (parts.length >= 2) {
        final action = parts[0]; // create, edit, delete, view
        final entity = parts.sublist(1).join(' '); // users, roles, etc.
        groupedPerms.putIfAbsent(entity, () => []).add(name);
      } else {
        groupedPerms.putIfAbsent('other', () => []).add(name);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateModal) {
          return AlertDialog(
            title: Text('Edit Permissions for ${role['name']}', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Select the permissions this role should have.',
                    style: GoogleFonts.nunito(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ...groupedPerms.entries.map((entry) {
                    final entity = entry.key;
                    final perms = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            entity.toUpperCase(),
                            style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.cyan),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: perms.map((perm) {
                            final isSelected = currentPermNames.contains(perm);
                            final actionName = perm.split(' ')[0].toUpperCase(); // CREATE, EDIT, etc.
                            return FilterChip(
                              label: Text(actionName, style: TextStyle(color: isSelected ? Colors.white : AppTheme.keyBlack, fontSize: 12)),
                              selected: isSelected,
                              selectedColor: AppTheme.magenta,
                              checkmarkColor: Colors.white,
                              onSelected: (selected) {
                                setStateModal(() {
                                  if (selected) {
                                    currentPermNames.add(perm);
                                  } else {
                                    currentPermNames.remove(perm);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ],
              ),
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
                    await _apiService.post('/roles/${role['id']}/update', body: {
                      'permissions': currentPermNames.toList(),
                    });
                    _fetchData();
                    if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Permissions updated successfully');
                  } catch (e) {
                    if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to update permissions: $e');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionChips(List<dynamic> permissions) {
    if (permissions.isEmpty) {
      return Text('No permissions', style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12));
    }
    
    // Show just a summary if there are many
    if (permissions.length > 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${permissions.length} Permissions',
          style: GoogleFonts.nunito(color: AppTheme.cyan, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      children: permissions.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p['name'].toString().split(' ')[0].toUpperCase(),
          style: const TextStyle(fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold),
        ),
      )).toList(),
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
                  'Role Permissions',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.keyBlack,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan,
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
                ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan))
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      itemCount: _roles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        final perms = role['permissions'] as List? ?? [];
                        return ListTile(
                          onTap: () => _showPermissionModal(role),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cyan.withOpacity(0.1),
                            child: const Icon(Icons.security_rounded, color: AppTheme.cyan),
                          ),
                          title: Text(role['name'].toString().toUpperCase(), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: _buildPermissionChips(perms),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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

