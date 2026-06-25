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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, foregroundColor: Colors.white),
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
                  'guard_name': 'api', // Setting to api based on backend setup
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

  void _showPermissionModal(Map<String, dynamic> role, {bool isReadOnly = false}) {
    // Collect currently assigned permissions
    final currentPermsList = role['permissions'] as List? ?? [];
    final currentPermNames = currentPermsList.map((p) => p['name'].toString()).toSet();
    final TextEditingController nameController = TextEditingController(text: role['name']);

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
            title: Text(isReadOnly ? 'View Permissions for ${role['name']}' : 'Edit Role & Permissions', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 8),
                children: [
                  if (!isReadOnly) ...[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Role Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.adminPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: Selecting "orders" permissions will auto-include customer and status permissions.',
                              style: GoogleFonts.nunito(color: AppTheme.adminPrimary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    isReadOnly ? 'Permissions assigned to this role:' : 'Select the permissions this role should have.',
                    style: GoogleFonts.nunito(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        return _buildPermissionTable(groupedPerms, currentPermNames, isReadOnly, setStateModal);
                      } else {
                        return _buildPermissionCards(groupedPerms, currentPermNames, isReadOnly, setStateModal);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (!isReadOnly)
                TextButton(
                  onPressed: () => setStateModal(() => currentPermNames.clear()),
                  child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isReadOnly ? 'Close' : 'Cancel'),
              ),
              if (!isReadOnly)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final permissionsPayload = currentPermNames.map((name) {
                        var perm;
                        for (var p in _allPermissions) {
                          if (p['name'] == name) {
                            perm = p;
                            break;
                          }
                        }
                        if (perm != null && perm['id'] != null) return perm['id'].toString();
                        return name;
                      }).toList();

                      await _apiService.post('/roles/${role['id']}/update', body: {
                        'name': nameController.text.trim(),
                        'permissions': currentPermNames.toList(),
                      });
                      _fetchData();
                      if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Role updated successfully');
                    } catch (e) {
                      if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to update role: $e');
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

  void _showDeleteConfirmation(Map<String, dynamic> role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Role', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the role "${role['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.delete('/roles/${role['id']}');
                _fetchData();
                if (mounted) DialogHelper.showSuccessDialog(context, 'Success', 'Role deleted successfully');
              } catch (e) {
                if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete role: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTable(Map<String, List<String>> groupedPerms, Set<String> currentPermNames, bool isReadOnly, StateSetter setStateModal) {
    final columns = ['Module', 'Create', 'View', 'Edit', 'Delete'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.adminPrimary.withOpacity(0.1)),
        columns: columns.map((c) => DataColumn(label: Text(c, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)))).toList(),
        rows: groupedPerms.entries.map((entry) {
          final entity = entry.key;
          final perms = entry.value;
          
          DataCell buildCell(String action) {
            final permName = '$action $entity';
            if (!perms.contains(permName)) {
              return const DataCell(Text('-'));
            }
            final isSelected = currentPermNames.contains(permName);
            return DataCell(
              Checkbox(
                value: isSelected,
                onChanged: isReadOnly ? null : (val) {
                  setStateModal(() {
                    if (val == true) {
                      currentPermNames.addAll(perms);
                      if (entity == 'orders') {
                        for (var p in _allPermissions) {
                          final pName = p['name'].toString();
                          if (pName == 'view customer' || pName == 'create customer' || pName == 'view status' ||
                              pName == 'view customers' || pName == 'create customers' || pName == 'view statuses') {
                            currentPermNames.add(pName);
                          }
                        }
                      }
                    } else {
                      currentPermNames.removeAll(perms);
                    }
                  });
                },
                activeColor: AppTheme.adminPrimary,
              ),
            );
          }

          return DataRow(
            cells: [
              DataCell(Text(entity.toUpperCase(), style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold))),
              buildCell('create'),
              buildCell('view'),
              buildCell('edit'),
              buildCell('delete'),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionCards(Map<String, List<String>> groupedPerms, Set<String> currentPermNames, bool isReadOnly, StateSetter setStateModal) {
    return Column(
      children: groupedPerms.entries.map((entry) {
        final entity = entry.key;
        final perms = entry.value;

        return Card(
  elevation: 20,
  shadowColor: AppTheme.adminPrimary.withOpacity(0.3),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.toUpperCase(),
                  style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold, color: AppTheme.adminPrimary, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['create', 'view', 'edit', 'delete'].map((action) {
                    final permName = '$action $entity';
                    if (!perms.contains(permName)) return const SizedBox.shrink();
                    
                    final isSelected = currentPermNames.contains(permName);
                    return InkWell(
                      onTap: isReadOnly ? null : () {
                        setStateModal(() {
                          if (!isSelected) {
                            currentPermNames.addAll(perms);
                            if (entity == 'orders') {
                              for (var p in _allPermissions) {
                                final pName = p['name'].toString();
                                if (pName == 'view customer' || pName == 'create customer' || pName == 'view status' ||
                                    pName == 'view customers' || pName == 'create customers' || pName == 'view statuses') {
                                  currentPermNames.add(pName);
                                }
                              }
                            }
                          } else {
                            currentPermNames.removeAll(perms);
                          }
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.adminPrimary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? AppTheme.adminPrimary : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              action.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppTheme.adminText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          color: AppTheme.adminPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${permissions.length} Permissions',
          style: GoogleFonts.nunito(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      children: permissions.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.adminPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p['name'].toString().split(' ')[0].toUpperCase(),
          style: const TextStyle(fontSize: 10, color: AppTheme.adminPrimary, fontWeight: FontWeight.bold),
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
                    color: AppTheme.adminText,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Role'),
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
                : Card(
  elevation: 20,
  shadowColor: AppTheme.adminPrimary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      itemCount: _roles.length,
                      separatorBuilder: (_, __) => const SizedBox(),
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        final perms = role['permissions'] as List? ?? [];
                        return ListTile(
                          onTap: () => _showPermissionModal(role, isReadOnly: true),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.adminPrimary.withOpacity(0.1),
                            child: const Icon(Icons.security_rounded, color: AppTheme.adminPrimary),
                          ),
                          title: Text(role['name'].toString().toUpperCase(), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: _buildPermissionChips(perms),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.adminPrimary),
                                onPressed: () => _showPermissionModal(role, isReadOnly: true),
                                tooltip: 'View',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: AppTheme.adminPrimary, shadows: [Shadow(color: AppTheme.adminPrimary, blurRadius: 10, offset: const Offset(0, 6))]),
                                onPressed: () => _showPermissionModal(role, isReadOnly: false),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.redAccent, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10, offset: const Offset(0, 6))]),
                                onPressed: () => _showDeleteConfirmation(role),
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

